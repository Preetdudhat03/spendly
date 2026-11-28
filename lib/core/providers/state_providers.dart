import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spendly/core/utils/error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spendly/core/constants/auth_constants.dart';
import 'package:spendly/core/constants/config.dart';
import 'package:spendly/core/providers/auth_providers.dart';
import 'package:spendly/core/repositories/expense_repository.dart';
import 'package:spendly/core/repositories/budget_repository.dart';
import 'package:spendly/core/repositories/family_repository.dart';
import 'package:spendly/core/repositories/profile_repository.dart';
import 'package:spendly/core/services/auth_deep_link_service.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/core/services/db_provider.dart';
import 'package:spendly/core/services/db_service.dart';
import 'package:spendly/core/utils/schema_validator.dart';
import 'package:spendly/main.dart';
import 'package:spendly/models/family.dart';
import 'package:spendly/models/family_member.dart';
import 'package:spendly/models/expense.dart';
import 'package:spendly/models/budget.dart';
import 'package:spendly/models/hive/family_model.dart';
import 'package:spendly/models/hive/family_member_model.dart';
import 'package:spendly/features/notifications/services/notification_service.dart';
import 'package:spendly/features/notifications/providers/notification_providers.dart';

// ==========================================
// 1. Authentication State & Provider
// ==========================================

enum AuthStatus {
  initializing,
  loading,
  verificationPending,
  authenticated,
  unauthenticated,
  error,
}

enum VerificationPurpose {
  signup,
  emailChange,
  otpLogin,
}

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final bool isInitializing;
  final String? userId;
  final String? email;
  final String? pendingEmail;
  final VerificationPurpose? verificationPurpose;
  final DateTime? lastOtpSentAt;
  final String? displayName;
  final String? avatarColor;
  final String? statusMessage;
  final String? error;

  AuthState({
    AuthStatus? status,
    required this.isLoading,
    this.isInitializing = false,
    this.userId,
    this.email,
    this.pendingEmail,
    this.verificationPurpose,
    this.lastOtpSentAt,
    this.displayName,
    this.avatarColor,
    this.statusMessage,
    this.error,
  }) : status = status ??
            (isInitializing
                ? AuthStatus.initializing
                : isLoading
                    ? AuthStatus.loading
                    : userId != null
                        ? AuthStatus.authenticated
                        : error != null
                            ? AuthStatus.error
                            : AuthStatus.unauthenticated);

  factory AuthState.initial() => AuthState(
        status: AuthStatus.initializing,
        isLoading: false,
        isInitializing: true,
      );

  bool get isVerificationPending => status == AuthStatus.verificationPending;

  int get resendCooldownRemaining {
    if (lastOtpSentAt == null) return 0;
    final elapsed = DateTime.now().difference(lastOtpSentAt!).inSeconds;
    final remaining = AuthConstants.resendCooldownSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    bool? isInitializing,
    String? userId,
    String? email,
    String? pendingEmail,
    bool clearPendingEmail = false,
    VerificationPurpose? verificationPurpose,
    bool clearVerificationPurpose = false,
    DateTime? lastOtpSentAt,
    String? displayName,
    String? avatarColor,
    String? statusMessage,
    bool clearStatusMessage = false,
    String? error,
  }) {
    final nextUserId = userId ?? this.userId;
    final nextIsInitializing = isInitializing ?? this.isInitializing;
    final nextIsLoading = isLoading ?? this.isLoading;
    final nextStatus = status ??
        (nextIsInitializing
            ? AuthStatus.initializing
            : nextIsLoading
                ? AuthStatus.loading
                : nextUserId != null
                    ? AuthStatus.authenticated
                    : error != null
                        ? AuthStatus.error
                        : AuthStatus.unauthenticated);

    return AuthState(
      status: nextStatus,
      isLoading: nextIsLoading,
      isInitializing: nextIsInitializing,
      userId: nextUserId,
      email: email ?? this.email,
      pendingEmail: clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      verificationPurpose: clearVerificationPurpose
          ? null
          : (verificationPurpose ?? this.verificationPurpose),
      lastOtpSentAt: lastOtpSentAt ?? this.lastOtpSentAt,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.isLoading == isLoading &&
        other.isInitializing == isInitializing &&
        other.userId == userId &&
        other.email == email &&
        other.pendingEmail == pendingEmail &&
        other.verificationPurpose == verificationPurpose &&
        other.lastOtpSentAt == lastOtpSentAt &&
        other.displayName == displayName &&
        other.statusMessage == statusMessage &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        status,
        isLoading,
        isInitializing,
        userId,
        email,
        pendingEmail,
        verificationPurpose,
        lastOtpSentAt,
        displayName,
        statusMessage,
        error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final DbService _dbService;
  final Ref _ref;
  AuthDeepLinkService? _deepLinkService;

  AuthNotifier(this._dbService, this._ref) : super(AuthState.initial()) {
    // Listen to native Supabase Auth user changes
    _ref.listen(currentUserProvider, (previous, nextUser) {
      _updateStateFromProviders();
    });

    // Listen to native Profile changes
    _ref.listen(profileProvider, (previous, nextProfile) {
      _updateStateFromProviders();
    });

    // Listen to deep-link auth callbacks (when Supabase is initialized)
    if (AppConfig.isSupabaseInitialized && !kIsWeb) {
      _deepLinkService = AuthDeepLinkService()
        ..startListening(onCallback: handleAuthCallback);
    }

    // Run initial checks
    _checkCurrentSession();
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }

  Future<void> _checkCurrentSession() async {
    // Postpone to next microtask to avoid Riverpod modify-while-building errors
    await Future.microtask(() {});
    if (state.status != AuthStatus.initializing) return;

    state = state.copyWith(
      status: AuthStatus.initializing,
      isLoading: true,
      isInitializing: true,
    );

    try {
      // Check native user (Account Integrity Guard) with a safety timeout so
      // startup never hangs on a grey/splash screen.
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        if (HiveService.currentUserId != user.id) {
          await HiveService.openUserBoxes(user.id).timeout(AuthConstants.networkTimeout);
        }
        await HiveService.settings.put('active_user_id', user.id);
        await _updateStateFromProviders().timeout(AuthConstants.networkTimeout);
        _ref.read(familyProvider.notifier).loadFamily();
        return;
      }

      if (HiveService.currentUserId != HiveService.guestNamespace) {
        await HiveService.openUserBoxes(HiveService.guestNamespace);
      }
      if (state.status == AuthStatus.initializing) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          isInitializing: false,
        );
      }
    } catch (e) {
      debugPrint('AuthNotifier._checkCurrentSession fallback error: $e');
      if (state.status == AuthStatus.initializing) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          isInitializing: false,
          error: ErrorHelper.getReadableErrorMessage(e),
        );
      }
    }
  }

  Future<void> _updateStateFromProviders() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      if (HiveService.currentUserId != HiveService.guestNamespace) {
        await HiveService.openUserBoxes(HiveService.guestNamespace);
      }
      // Preserve verificationPending state if user is currently on OTP / Verify Email screen
      if (state.status == AuthStatus.verificationPending) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          isLoading: false,
          isInitializing: false,
        );
        return;
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        isInitializing: false,
      );
      return;
    }

    // Native user is logged in - Account Integrity Guard
    if (HiveService.currentUserId != user.id) {
      await HiveService.openUserBoxes(user.id);
    }
    await HiveService.settings.put('active_user_id', user.id);
    await HiveService.updateUserRegistry(
      userId: user.id,
      displayName: user.userMetadata?['display_name'] as String? ?? 'User',
      email: user.email,
      appVersion: '5.5.0',
      boxVersion: 1,
    );

    final savedAvatar = state.avatarColor ??
        (user.userMetadata?['avatar_color'] as String?) ??
        HiveService.settings.get('avatar_color') as String?;

    // Check if an authoritative email change just completed
    final confirmedEmail = user.email;
    final shouldClearPending = state.pendingEmail != null &&
        confirmedEmail != null &&
        confirmedEmail.toLowerCase() == state.pendingEmail!.toLowerCase();

    final profileAsync = _ref.read(profileProvider);
    profileAsync.when(
      data: (profile) {
        final effectiveEmail = confirmedEmail ?? profile?.email;
        final effectiveName = (profile != null && profile.displayName.isNotEmpty)
            ? profile.displayName
            : (user.userMetadata?['display_name'] as String? ?? 'User');
        state = AuthState(
          status: AuthStatus.authenticated,
          isLoading: false,
          isInitializing: false,
          userId: profile?.id ?? user.id,
          email: effectiveEmail,
          pendingEmail: shouldClearPending ? null : state.pendingEmail,
          verificationPurpose: shouldClearPending ? null : state.verificationPurpose,
          lastOtpSentAt: state.lastOtpSentAt,
          displayName: effectiveName,
          avatarColor: savedAvatar,
          statusMessage: shouldClearPending ? 'Email address verified and updated.' : state.statusMessage,
        );
        HiveService.settings.put('active_user_id', profile?.id ?? user.id);
        _ref.read(familyProvider.notifier).loadFamily();
      },
      loading: () {
        if (state.isInitializing) {
          state = state.copyWith(
            status: AuthStatus.loading,
            isLoading: true,
          );
        }
      },
      error: (e, s) {
        // Fallback to native Supabase user even if profile fetch fails,
        // preventing an indefinite splash/grey screen.
        state = AuthState(
          status: AuthStatus.authenticated,
          isLoading: false,
          isInitializing: false,
          userId: user.id,
          email: confirmedEmail,
          displayName: user.userMetadata?['display_name'] as String? ?? 'User',
          avatarColor: savedAvatar,
          error: ErrorHelper.getReadableErrorMessage(e),
        );
        HiveService.settings.put('active_user_id', user.id);
        _ref.read(familyProvider.notifier).loadFamily();
      },
    );
  }

  Future<bool> signIn(String email, String password) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanEmail = email.toLowerCase().trim();

      // Check internet connectivity first if Supabase is configured & initialized
      if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
        if (!await _hasInternetConnection()) {
          state = state.copyWith(
            status: AuthStatus.error,
            isLoading: false,
            error: "You're offline. Connect to the internet to sign in.",
          );
          return false;
        }
      }

      // Fallback to local DB Service if Supabase is not configured or initialized
      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        try {
          final userId = await _dbService.signIn(email: cleanEmail, password: password);
          if (userId != null) {
            final displayName = await _dbService.getCurrentUserDisplayName();
            state = AuthState(
              isLoading: false,
              userId: userId,
              email: cleanEmail,
              displayName: displayName,
            );
            HiveService.settings.put('active_user_id', userId);
            _ref.read(familyProvider.notifier).loadFamily();
            return true;
          }
        } catch (e) {
          final errorMsg = ErrorHelper.getReadableErrorMessage(e);
          if (errorMsg.contains('USER_NOT_FOUND')) {
            state = state.copyWith(isLoading: false, error: 'USER_NOT_FOUND');
          } else {
            state = state.copyWith(isLoading: false, error: errorMsg.replaceAll('Exception: ', ''));
          }
          return false;
        }
        state = state.copyWith(isLoading: false, error: 'Authentication failed');
        return false;
      }

      // 1. Native Supabase Auth sign-in
      try {
        final client = Supabase.instance.client;
        final response = await client.auth
            .signInWithPassword(
              email: cleanEmail,
              password: password,
            )
            .timeout(AuthConstants.networkTimeout);
        if (response.user != null) {
          await _ref.read(syncServiceProvider).mergeLocalDataToCloud(response.user!.id);
          await _updateStateFromProviders();
          return true;
        }
        state = state.copyWith(
          status: AuthStatus.error,
          isLoading: false,
          error: 'Authentication failed. Please try again.',
        );
        return false;
      } on AuthException catch (supabaseError) {
        final msg = supabaseError.message.toLowerCase();
        if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            isLoading: false,
            error: 'Invalid email or password.',
          );
          return false;
        } else if (msg.contains('email not confirmed')) {
          state = AuthState(
            status: AuthStatus.verificationPending,
            isLoading: false,
            email: cleanEmail,
            pendingEmail: cleanEmail,
            verificationPurpose: VerificationPurpose.signup,
            error: 'Please verify your email address before logging in.',
          );
          return false;
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            isLoading: false,
            error: supabaseError.message,
          );
          return false;
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Unable to connect. Check your internet connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  bool _isNetworkError(Object e) {
    if (e is TimeoutException || e is SocketException) return true;
    final errStr = e.toString().toLowerCase();
    return errStr.contains('timeout') ||
        errStr.contains('socketexception') ||
        errStr.contains('httpexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection failed') ||
        errStr.contains('handshake') ||
        errStr.contains('unreachable');
  }

  Future<bool> _hasInternetConnection() async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      return true;
    }
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !(connectivityResult.contains(ConnectivityResult.none) ||
          connectivityResult.isEmpty);
    } catch (_) {
      return true;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );
    try {
      final cleanEmail = SchemaValidator.validateEmail(email).toLowerCase();
      final cleanName = SchemaValidator.validateDisplayName(displayName);
      SchemaValidator.validateStrictPassword(password);

      if (!await _hasInternetConnection() && AppConfig.isSupabaseInitialized) {
        state = state.copyWith(
          status: AuthStatus.error,
          isLoading: false,
          error: "You're offline. Connect to the internet to create an account.",
        );
        return false;
      }

      // Fallback to local DB Service if Supabase is not configured or initialized
      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        final userId = await _dbService
            .signUp(
              email: cleanEmail,
              password: password,
              displayName: cleanName,
            )
            .timeout(AuthConstants.networkTimeout);
        if (userId != null) {
          state = AuthState(
            status: AuthStatus.verificationPending,
            isLoading: false,
            email: cleanEmail,
            pendingEmail: cleanEmail,
            verificationPurpose: VerificationPurpose.signup,
            lastOtpSentAt: DateTime.now(),
            displayName: cleanName,
            statusMessage:
                'Registration successful! Please verify your email address.',
          );
          return true;
        }
        state = state.copyWith(
          status: AuthStatus.error,
          isLoading: false,
          error: 'Registration failed',
        );
        return false;
      }

      final client = Supabase.instance.client;
      final response = await client.auth
          .signUp(
            email: cleanEmail,
            password: password,
            data: {'display_name': cleanName},
            emailRedirectTo: kIsWeb ? null : AuthConstants.authCallbackUri,
          )
          .timeout(AuthConstants.networkTimeout);

      if (response.user != null) {
        // Supabase returns empty identities for existing confirmed accounts
        // when email enumeration protection is enabled.
        final identities = response.user!.identities;
        if (identities != null && identities.isEmpty) {
          state = state.copyWith(
            status: AuthStatus.error,
            isLoading: false,
            error:
                'An account with this email already exists. Please log in or use Email OTP.',
          );
          return false;
        }

        if (response.session != null) {
          await _ref
              .read(syncServiceProvider)
              .mergeLocalDataToCloud(response.user!.id);
          await _updateStateFromProviders();
          return true;
        }

        // Standard confirmation-required flow: user exists, session is null.
        // Never treat unconfirmed user as authenticated.
        state = AuthState(
          status: AuthStatus.verificationPending,
          isLoading: false,
          isInitializing: false,
          pendingEmail: cleanEmail,
          verificationPurpose: VerificationPurpose.signup,
          lastOtpSentAt: DateTime.now(),
          displayName: cleanName,
          statusMessage:
              'Verification email sent. Please confirm your email to continue.',
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: 'Sign up failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      String readable = e.message;
      if (msg.contains('already registered') || msg.contains('user_already_exists')) {
        readable = 'An account with this email already exists. Please log in instead.';
      } else if (msg.contains('rate limit') || msg.contains('over_email_send_rate_limit')) {
        readable = 'Too many verification emails requested. Please wait a moment before trying again.';
      }
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: readable,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Network timeout while creating account. Please check your connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Resends signup confirmation email without creating a duplicate account.
  Future<bool> resendSignupVerification(String email) async {
    final cooldown = state.resendCooldownRemaining;
    if (cooldown > 0) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        error: 'Please wait $cooldown seconds before requesting another email.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );

    try {
      final cleanEmail = SchemaValidator.validateEmail(email).toLowerCase();
      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          isLoading: false,
          pendingEmail: cleanEmail,
          verificationPurpose: VerificationPurpose.signup,
          lastOtpSentAt: DateTime.now(),
          statusMessage: 'Verification email resent to $cleanEmail.',
        );
        return true;
      }

      if (!await _hasInternetConnection()) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          isLoading: false,
          error: "You're offline. Connect to the internet and try again.",
        );
        return false;
      }

      final client = Supabase.instance.client;
      await client.auth
          .resend(
            type: OtpType.signup,
            email: cleanEmail,
            emailRedirectTo: kIsWeb ? null : AuthConstants.authCallbackUri,
          )
          .timeout(AuthConstants.networkTimeout);

      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        pendingEmail: cleanEmail,
        verificationPurpose: VerificationPurpose.signup,
        lastOtpSentAt: DateTime.now(),
        statusMessage: 'A new confirmation email has been sent.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        error: e.message.toLowerCase().contains('rate limit')
            ? 'Email rate limit reached. Please wait a minute before trying again.'
            : e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Unable to connect. Check your internet connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Passwordless Email OTP login (existing accounts only: `shouldCreateUser: false`).
  Future<bool> sendEmailOtp(String email) async {
    final cooldown = state.resendCooldownRemaining;
    if (cooldown > 0 &&
        state.pendingEmail?.toLowerCase() == email.trim().toLowerCase()) {
      state = state.copyWith(
        error: 'Please wait $cooldown seconds before requesting another OTP.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );

    try {
      final cleanEmail = SchemaValidator.validateEmail(email).toLowerCase();

      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          isLoading: false,
          pendingEmail: cleanEmail,
          verificationPurpose: VerificationPurpose.otpLogin,
          lastOtpSentAt: DateTime.now(),
          statusMessage: 'OTP sent to $cleanEmail.',
        );
        return true;
      }

      if (!await _hasInternetConnection()) {
        state = state.copyWith(
          status: AuthStatus.error,
          isLoading: false,
          error: "You're offline. Connect to the internet to request an OTP.",
        );
        return false;
      }

      final client = Supabase.instance.client;
      await client.auth
          .signInWithOtp(
            email: cleanEmail,
            shouldCreateUser: false,
            emailRedirectTo: kIsWeb ? null : AuthConstants.authCallbackUri,
          )
          .timeout(AuthConstants.networkTimeout);

      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        pendingEmail: cleanEmail,
        verificationPurpose: VerificationPurpose.otpLogin,
        lastOtpSentAt: DateTime.now(),
        statusMessage: 'Verification code sent.',
      );
      return true;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      String readable = e.message;
      if (msg.contains('signups not allowed') ||
          msg.contains('user not found') ||
          msg.contains('otp_disabled')) {
        readable = 'No account found for this email. Please sign up first.';
      } else if (msg.contains('rate limit') ||
          msg.contains('over_email_send_rate_limit')) {
        readable =
            'Too many OTP requests. Please wait a moment before trying again.';
      }
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: readable,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Unable to connect. Check your internet connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Verifies a 6-digit Email OTP for login, signup confirmation, or email change.
  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    final cleanToken = token.trim();
    if (cleanToken.length != 6 || int.tryParse(cleanToken) == null) {
      state = state.copyWith(
        error: 'Please enter the 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );

    try {
      final cleanEmail = SchemaValidator.validateEmail(email).toLowerCase();

      if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
        state = state.copyWith(
          status: AuthStatus.error,
          isLoading: false,
          error: 'OTP verification requires an active Supabase connection.',
        );
        return false;
      }

      if (!await _hasInternetConnection()) {
        state = state.copyWith(
          status: AuthStatus.verificationPending,
          isLoading: false,
          error: "You're offline. Connect to the internet to verify the code.",
        );
        return false;
      }

      final client = Supabase.instance.client;
      final previousUserId = state.userId;

      final response = await client.auth
          .verifyOTP(
            email: cleanEmail,
            token: cleanToken,
            type: type,
          )
          .timeout(AuthConstants.networkTimeout);

      final verifiedUser = response.user ?? client.auth.currentUser;
      if (verifiedUser != null) {
        // Account isolation guard for email change: ensure UUID did not switch
        if (type == OtpType.emailChange &&
            previousUserId != null &&
            verifiedUser.id != previousUserId) {
          state = state.copyWith(
            status: AuthStatus.error,
            isLoading: false,
            error: 'Account mismatch detected. Email change was aborted.',
          );
          return false;
        }

        if (response.session != null) {
          await _ref
              .read(syncServiceProvider)
              .mergeLocalDataToCloud(verifiedUser.id);
        }
        await _updateStateFromProviders();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
          clearPendingEmail: true,
          clearVerificationPurpose: true,
          statusMessage: type == OtpType.emailChange
              ? 'Your email address has been verified and updated.'
              : 'Email verified successfully.',
        );
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        error: 'Verification failed. Please check the code and try again.',
      );
      return false;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      String readable = e.message;
      if (msg.contains('expired')) {
        readable = 'This verification code has expired. Please request a new one.';
      } else if (msg.contains('invalid') || msg.contains('token')) {
        readable = 'Invalid verification code. Please check and try again.';
      }
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        error: readable,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.verificationPending,
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Network error while verifying code. Please try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  void clearPendingVerification() {
    state = state.copyWith(
      status: state.userId != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      isLoading: false,
      clearPendingEmail: true,
      clearVerificationPurpose: true,
      clearStatusMessage: true,
      error: null,
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    debugPrint('[NOTIFICATION] AuthNotifier.signOut started');

    // 1. Deactivate FCM device token and stop notification services before Supabase session is destroyed
    try {
      await _ref.read(notificationServiceProvider).onSignOut();
    } catch (e) {
      debugPrint('[NOTIFICATION] Error during notificationService.onSignOut: $e');
    }

    // 2. Reset user-specific notification and preferences providers
    _ref.read(notificationsProvider.notifier).reset();
    _ref.read(notificationPreferencesProvider.notifier).reset();

    // 3. Clear local active user pointer and sign out
    await HiveService.settings.delete('active_user_id');
    await _dbService.signOut();
    await HiveService.openUserBoxes(HiveService.guestNamespace);
    state = AuthState(isLoading: false, isInitializing: false);
    _ref.read(familyProvider.notifier).reset();
    _ref.read(expenseProvider.notifier).reset();
    _ref.read(budgetProvider.notifier).reset();
    debugPrint('[NOTIFICATION] AuthNotifier.signOut completed');
  }

  Future<void> deleteAccount() async {
    final currentId = state.userId;
    if (currentId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dbService.deleteUserAccount(currentId);
      await signOut();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      rethrow;
    }
  }

  Future<void> updateProfileName(String newName) async {
    try {
      final currentId = state.userId;
      if (currentId != null) {
        await _dbService.updateMemberDisplayName(newName);
        await _ref.read(profileRepositoryProvider).updateDisplayName(currentId, newName);
      }
      state = state.copyWith(displayName: newName);
      
      // Refresh native profile notifier
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(profileNotifierProvider(user.id).notifier).refresh();
      }

      // Reload family members to update list UI
      _ref.read(familyProvider.notifier).loadMembers();
      // Reload expenses to update createdByName cache
      _ref.read(expenseProvider.notifier).loadExpenses();
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<void> updateAvatarColor(String colorHex) async {
    try {
      await _dbService.updateMemberAvatarColor(colorHex);
      await HiveService.settings.put('avatar_color', colorHex);
      state = state.copyWith(avatarColor: colorHex);
      
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        _ref.read(familyProvider.notifier).loadMembers();
      }
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  /// Initiates an email change without overwriting the current confirmed email
  /// or altering the user's UUID. Profile email updates only after Supabase
  /// confirms the change.
  Future<bool> updateEmail(String newEmail) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );
    try {
      final cleanEmail = SchemaValidator.validateEmail(newEmail).toLowerCase();
      if (state.email != null && state.email!.toLowerCase() == cleanEmail) {
        state = state.copyWith(
          isLoading: false,
          error: 'This is already your current email address.',
        );
        return false;
      }

      await _dbService
          .updateEmail(cleanEmail)
          .timeout(AuthConstants.networkTimeout);

      state = state.copyWith(
        status: state.userId != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        isLoading: false,
        pendingEmail: cleanEmail,
        verificationPurpose: VerificationPurpose.emailChange,
        lastOtpSentAt: DateTime.now(),
        statusMessage:
            'Confirmation sent to $cleanEmail. Your email will update after confirmation.',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message.toLowerCase().contains('already')
            ? 'This email address is already associated with another account.'
            : e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Unable to connect. Check your internet connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  /// Refreshes the authenticated user from Supabase to check whether a pending
  /// email change has been confirmed, preserving the original user UUID.
  Future<bool> refreshAuthenticatedUser() async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = Supabase.instance.client;
      final previousUserId = state.userId;
      final userResp = await client.auth
          .getUser()
          .timeout(AuthConstants.networkTimeout);
      final refreshedUser = userResp.user;
      if (refreshedUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      if (previousUserId != null && refreshedUser.id != previousUserId) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session user mismatch detected.',
        );
        return false;
      }

      await _ref.read(profileNotifierProvider(refreshedUser.id).notifier).refresh();
      await _updateStateFromProviders();

      final confirmed = state.pendingEmail != null &&
          refreshedUser.email?.toLowerCase() ==
              state.pendingEmail!.toLowerCase();
      if (confirmed) {
        state = state.copyWith(
          isLoading: false,
          clearPendingEmail: true,
          clearVerificationPurpose: true,
          statusMessage: 'Email address confirmed and updated.',
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return confirmed;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Network error while checking email status.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  void cancelPendingEmailChange() {
    state = state.copyWith(
      isLoading: false,
      clearPendingEmail: true,
      clearVerificationPurpose: true,
      clearStatusMessage: true,
      error: null,
    );
  }

  Future<void> handleAuthCallback(AuthCallbackResult result) async {
    if (result.kind == AuthCallbackKind.ignored) return;

    if (result.isError) {
      state = state.copyWith(
        status: state.userId != null
            ? AuthStatus.authenticated
            : AuthStatus.error,
        isLoading: false,
        isInitializing: false,
        error: result.errorMessage ??
            'Authentication link is invalid or expired.',
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.loading,
      isLoading: true,
      error: null,
      clearStatusMessage: true,
    );

    try {
      await AuthDeepLinkService.exchangeSessionIfNeeded(result);
      await refreshAuthenticatedUser();

      final successMsg = switch (result.kind) {
        AuthCallbackKind.signup => 'Email verified! Welcome to Spendly.',
        AuthCallbackKind.emailChange =>
          'Your new email address has been confirmed.',
        AuthCallbackKind.recovery =>
          'Recovery link verified. You can now update your password.',
        AuthCallbackKind.otp => 'Email login verified.',
        _ => 'Authentication verified.',
      };

      state = state.copyWith(
        status: state.userId != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        isLoading: false,
        isInitializing: false,
        clearPendingEmail: true,
        clearVerificationPurpose: true,
        statusMessage: successMsg,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: state.userId != null
            ? AuthStatus.authenticated
            : AuthStatus.error,
        isLoading: false,
        isInitializing: false,
        error: AuthDeepLinkService.mapCallbackError(
          errorCode: e.statusCode,
          description: e.message,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        status: state.userId != null
            ? AuthStatus.authenticated
            : AuthStatus.error,
        isLoading: false,
        isInitializing: false,
        error: _isNetworkError(e)
            ? 'Network error while verifying link. Please try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
    }
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cleanEmail = SchemaValidator.validateEmail(email).toLowerCase();
      final client = Supabase.instance.client;
      await client.auth
          .resetPasswordForEmail(
            cleanEmail,
            redirectTo: kIsWeb ? null : AuthConstants.resetPasswordUri,
          )
          .timeout(AuthConstants.networkTimeout);
      state = state.copyWith(isLoading: false);
      return 'SUCCESS';
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _isNetworkError(e)
            ? 'Unable to connect. Check your internet connection and try again.'
            : ErrorHelper.getReadableErrorMessage(e),
      );
      return null;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final db = ref.watch(dbServiceProvider);
  return AuthNotifier(db, ref);
});

// ==========================================
// 2. Family State & Provider
// ==========================================

class FamilyState {
  final bool isLoading;
  final bool hasLoaded;
  final Family? family;
  final List<FamilyMember> members;
  final String? error;

  FamilyState({
    required this.isLoading,
    this.hasLoaded = false,
    this.family,
    required this.members,
    this.error,
  });

  factory FamilyState.initial() => FamilyState(
        isLoading: false,
        hasLoaded: false,
        members: [],
      );

  FamilyState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    Family? family,
    List<FamilyMember>? members,
    String? error,
  }) {
    return FamilyState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      family: family ?? this.family,
      members: members ?? this.members,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyState &&
        other.isLoading == isLoading &&
        other.hasLoaded == hasLoaded &&
        other.family == family &&
        listEquals(other.members, members) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isLoading, hasLoaded, family, Object.hashAll(members), error);
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  final FamilyRepository _familyRepo;
  final Ref _ref;
  Timer? _debounceTimer;

  FamilyNotifier(this._familyRepo, this._ref) : super(FamilyState.initial()) {
    try {
      HiveService.families.watch().listen((_) => _onHiveChanged());
      HiveService.familyMembers.watch().listen((_) => _onHiveChanged());
    } catch (_) {
      // Ignore in unit tests or before user boxes are initialized
    }
  }

  void _onHiveChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () => loadFamily());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void reset() {
    state = FamilyState.initial();
  }

  Future<void> loadFamily() async {
    if (state.isLoading) return;

    final activeUserId = HiveService.settings.get('active_user_id') ?? '';
    var family = _familyRepo.getCurrentFamily(activeUserId);

    if (family == null && activeUserId.isNotEmpty && !activeUserId.startsWith('user_')) {
      try {
        final dbService = _ref.read(dbServiceProvider);
        final remoteFamily = await dbService.getCurrentFamily();
        if (remoteFamily != null) {
          await HiveService.families.put(remoteFamily.id, FamilyModel.fromDomain(remoteFamily));
          final remoteMembers = await dbService.getFamilyMembers();
          for (var m in remoteMembers) {
            await HiveService.familyMembers.put(
              '${remoteFamily.id}_${m.userId}',
              FamilyMemberModel.fromDomain(m),
            );
          }
          family = remoteFamily;
        }
      } catch (e) {
        debugPrint('FamilyNotifier: Failed to fetch remote family fallback: $e');
      }
    }

    final members = family != null ? _familyRepo.getFamilyMembers(family.id) : <FamilyMember>[];
    
    final newState = FamilyState(
      isLoading: false,
      hasLoaded: true,
      family: family,
      members: members,
    );

    if (state != newState) {
      final wasFamilyNull = state.family == null;
      state = newState;
      if (family != null && wasFamilyNull) {
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();
      }
    }
  }

  Future<void> loadMembers() async {
    if (state.family == null) return;
    try {
      final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
      state = state.copyWith(members: members);
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<bool> createFamily(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = _ref.read(authProvider);
      final displayName = authState.displayName ?? 'User';
      final family = await _familyRepo.createFamily(name, HiveService.settings.get('active_user_id') ?? '', displayName);
      final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
      state = FamilyState(
        isLoading: false,
        hasLoaded: true,
        family: family,
        members: members,
      );
      _ref.read(expenseProvider.notifier).loadExpenses();
      _ref.read(budgetProvider.notifier).loadBudget();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> joinFamily(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = _ref.read(authProvider);
      final displayName = authState.displayName ?? 'User';
      final family = await _familyRepo.joinFamily(code, HiveService.settings.get('active_user_id') ?? '', displayName);
      if (family != null) {
        final members = await Future.value(_familyRepo.getFamilyMembers(_familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? ''));
        state = FamilyState(
          isLoading: false,
          hasLoaded: true,
          family: family,
          members: members,
        );
        _ref.read(expenseProvider.notifier).loadExpenses();
        _ref.read(budgetProvider.notifier).loadBudget();

        // Emit family member joined notification
        _ref.read(notificationServiceProvider).notifyFamilyMemberJoined(
          familyId: family.id,
          memberName: displayName,
          familyName: family.name,
          joinedUserId: HiveService.settings.get('active_user_id') ?? '',
        );

        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Could not join family',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> deleteFamily() async {
    final familyId = state.family?.id;
    if (familyId == null) {
      state = state.copyWith(error: 'No active family found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // await _familyRepo.deleteFamily(familyId); // Implement if needed
      reset();
      _ref.read(expenseProvider.notifier).reset();
      _ref.read(budgetProvider.notifier).reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHelper.getReadableErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> removeMember(String targetUserId) async {
    try {
      final familyId = state.family?.id ?? '';
      final familyName = state.family?.name ?? '';
      final targetMember = state.members.firstWhere(
        (m) => m.userId == targetUserId,
        orElse: () => FamilyMember(id: '', familyId: familyId, userId: targetUserId, role: 'member', joinedAt: DateTime.now(), displayName: 'Member'),
      );

      await _familyRepo.removeMember(targetUserId);
      await loadMembers(); // Reload members after removing

      if (familyId.isNotEmpty) {
        _ref.read(notificationServiceProvider).notifyFamilyMemberLeft(
          familyId: familyId,
          memberName: targetMember.displayName,
          familyName: familyName,
          leftUserId: targetUserId,
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return FamilyNotifier(repo, ref);
});

// ==========================================
// 3. Expenses State & Provider
// ==========================================

class ExpenseState {
  final bool isLoading;
  final List<Expense> expenses;
  final String? error;

  ExpenseState({
    required this.isLoading,
    required this.expenses,
    this.error,
  });

  factory ExpenseState.initial() => ExpenseState(isLoading: false, expenses: []);

  ExpenseState copyWith({
    bool? isLoading,
    List<Expense>? expenses,
    String? error,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseState &&
        other.isLoading == isLoading &&
        listEquals(other.expenses, expenses) &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isLoading, Object.hashAll(expenses), error);
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseRepository _expenseRepo;
  final FamilyRepository _familyRepo;
  final Ref _ref;
  Timer? _debounceTimer;

  ExpenseNotifier(this._expenseRepo, this._familyRepo, this._ref) : super(ExpenseState.initial()) {
    HiveService.expenses.watch().listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () => loadExpenses());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void reset() {
    state = ExpenseState.initial();
  }

  Future<void> loadExpenses() async {
    if (state.isLoading) return;

    try {
      final activeUserId = HiveService.settings.get('active_user_id') ?? '';
      final familyId = _familyRepo.getCurrentFamily(activeUserId)?.id ?? '';
      final expenses = _expenseRepo.getExpenses(familyId);
      final newState = ExpenseState(isLoading: false, expenses: expenses);
      if (state != newState) {
        state = newState;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<bool> addExpense({
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
      final activeUserId = authUserId ?? (HiveService.settings.get('active_user_id') as String? ?? '');
      final family = _familyRepo.getCurrentFamily(activeUserId);
      final familyId = family?.id ?? '';
      final displayName = _ref.read(authProvider).displayName ??
          Supabase.instance.client.auth.currentUser?.userMetadata?['display_name'] as String? ??
          HiveService.profiles.get(activeUserId)?.displayName ??
          'User';

      final newExpense = await _expenseRepo.addExpense(
        familyId: familyId,
        createdBy: activeUserId,
        amount: amount,
        category: category,
        description: description,
        paymentMethod: paymentMethod,
        expenseDate: expenseDate,
        createdByName: displayName,
      );
      state = state.copyWith(isLoading: false);
      // Reload expenses list
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();

      // Emit notifications
      if (familyId.isNotEmpty) {
        _ref.read(notificationServiceProvider).notifyExpenseAdded(
          familyId: familyId,
          expenseId: newExpense.id,
          memberName: displayName,
          amount: amount,
          category: category,
          createdByUserId: authUserId ?? activeUserId,
        );

        // Check budget thresholds
        final budget = _ref.read(budgetProvider).currentBudget;
        if (budget != null && budget.monthlyBudget > 0) {
          final now = DateTime.now();
          final familyMonthExpenses = state.expenses.where((e) {
            return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
          });
          final familyMonthTotal = familyMonthExpenses.fold<double>(0, (sum, item) => sum + item.amount);
          _ref.read(notificationServiceProvider).checkBudgetThresholds(
            familyId: familyId,
            totalSpent: familyMonthTotal,
            budgetLimit: budget.monthlyBudget,
            month: now.month,
            year: now.year,
          );
        }
      }

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
      final activeUserId = authUserId ?? (HiveService.settings.get('active_user_id') as String? ?? '');
      final family = _familyRepo.getCurrentFamily(activeUserId);
      final familyId = family?.id ?? '';
      final displayName = _ref.read(authProvider).displayName ??
          Supabase.instance.client.auth.currentUser?.userMetadata?['display_name'] as String? ??
          HiveService.profiles.get(activeUserId)?.displayName ??
          'User';

      final expenses = _expenseRepo.getExpenses(familyId);
      final currentExpense = expenses.firstWhere(
        (e) => e.id == id,
        orElse: () => Expense(
          id: id,
          familyId: familyId,
          createdBy: activeUserId,
          createdByName: displayName,
          amount: 0,
          category: 'Expense',
          description: '',
          paymentMethod: 'UPI',
          expenseDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      await _expenseRepo.deleteExpense(id, familyId, activeUserId);
      state = state.copyWith(isLoading: false);
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();

      // Emit notification
      if (familyId.isNotEmpty && currentExpense.amount > 0) {
        _ref.read(notificationServiceProvider).notifyExpenseDeleted(
          familyId: familyId,
          expenseId: id,
          memberName: displayName,
          amount: currentExpense.amount,
          category: currentExpense.category,
          deletedByUserId: authUserId ?? activeUserId,
        );
      }

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
      return false;
    }
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required String category,
    required String description,
    required String paymentMethod,
    required DateTime expenseDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id ?? _ref.read(currentUserProvider)?.id;
      final activeUserId = authUserId ?? (HiveService.settings.get('active_user_id') as String? ?? '');
      final family = _familyRepo.getCurrentFamily(activeUserId);
      final familyId = family?.id ?? '';
      final displayName = _ref.read(authProvider).displayName ??
          Supabase.instance.client.auth.currentUser?.userMetadata?['display_name'] as String? ??
          HiveService.profiles.get(activeUserId)?.displayName ??
          'User';

      final currentExpense = _expenseRepo.getExpenses(familyId).firstWhere((e) => e.id == id);
      final oldAmount = currentExpense.amount;

      await _expenseRepo.updateExpense(
        currentExpense.copyWith(
          amount: amount,
          category: category,
          description: description,
          paymentMethod: paymentMethod,
          expenseDate: expenseDate,
        ),
      );
      state = state.copyWith(isLoading: false);
      await loadExpenses();
      // Trigger background sync
      _ref.read(syncServiceProvider).syncNow();

      // Emit notification
      if (familyId.isNotEmpty) {
        _ref.read(notificationServiceProvider).notifyExpenseUpdated(
          familyId: familyId,
          expenseId: id,
          memberName: displayName,
          oldAmount: oldAmount,
          newAmount: amount,
          category: category,
          updatedByUserId: authUserId ?? activeUserId,
        );

        // Check budget thresholds
        final budget = _ref.read(budgetProvider).currentBudget;
        if (budget != null && budget.monthlyBudget > 0) {
          final now = DateTime.now();
          final familyMonthExpenses = state.expenses.where((e) {
            return e.expenseDate.year == now.year && e.expenseDate.month == now.month;
          });
          final familyMonthTotal = familyMonthExpenses.fold<double>(0, (sum, item) => sum + item.amount);
          _ref.read(notificationServiceProvider).checkBudgetThresholds(
            familyId: familyId,
            totalSpent: familyMonthTotal,
            budgetLimit: budget.monthlyBudget,
            month: now.month,
            year: now.year,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final familyRepo = ref.watch(familyRepositoryProvider);
  return ExpenseNotifier(expenseRepo, familyRepo, ref);
});

// ==========================================
// 4. Budget State & Provider
// ==========================================

class BudgetState {
  final bool isLoading;
  final Budget? currentBudget;
  final String? error;

  BudgetState({
    required this.isLoading,
    this.currentBudget,
    this.error,
  });

  factory BudgetState.initial() => BudgetState(isLoading: false);

  BudgetState copyWith({
    bool? isLoading,
    Budget? currentBudget,
    String? error,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      currentBudget: currentBudget ?? this.currentBudget,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetState &&
        other.isLoading == isLoading &&
        other.currentBudget == currentBudget &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isLoading, currentBudget, error);
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _budgetRepo;
  final FamilyRepository _familyRepo;
  Timer? _debounceTimer;

  BudgetNotifier(this._budgetRepo, this._familyRepo) : super(BudgetState.initial()) {
    HiveService.budgets.watch().listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () => loadBudget());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void reset() {
    state = BudgetState.initial();
  }

  Future<void> loadBudget() async {
    if (state.isLoading) return;

    try {
      final now = DateTime.now();
      final activeUserId = HiveService.settings.get('active_user_id') ?? '';
      final familyId = _familyRepo.getCurrentFamily(activeUserId)?.id ?? '';
      final budget = _budgetRepo.getBudget(familyId, now.month, now.year);
      final newState = BudgetState(isLoading: false, currentBudget: budget);
      if (state != newState) {
        state = newState;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }

  Future<void> setBudget(double amount) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final budget = await _budgetRepo.setBudget(
        familyId: _familyRepo.getCurrentFamily(HiveService.settings.get('active_user_id') ?? '')?.id ?? '',
        userId: HiveService.settings.get('active_user_id') ?? '',
        monthlyBudget: amount,
        month: now.month,
        year: now.year,
      );
      state = BudgetState(isLoading: false, currentBudget: budget);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHelper.getReadableErrorMessage(e));
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final familyRepo = ref.watch(familyRepositoryProvider);
  return BudgetNotifier(budgetRepo, familyRepo);
});

// ==========================================
// 5. Connection Status & Provider
// ==========================================

enum ConnectionStatus { checking, online, offline, sandbox }

class ConnectionNotifier extends StateNotifier<ConnectionStatus> {
  Timer? _timer;

  ConnectionNotifier() : super(ConnectionStatus.checking) {
    checkConnection();
    // Run connection checks every 30 seconds to reduce overhead
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => checkConnection());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      state = ConnectionStatus.sandbox;
      return;
    }

    try {
      final results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) {
        state = ConnectionStatus.offline;
        return;
      }

      // Try to query profiles table for connection health check
      await Supabase.instance.client.from('profiles').select('id').limit(1);
      state = ConnectionStatus.online;
    } on PostgrestException catch (e) {
      // If profiles table responds or throws permission/empty, Supabase is reachable!
      debugPrint('Connection check: PostgrestException (Supabase is reachable): $e');
      state = ConnectionStatus.online;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      state = ConnectionStatus.offline;
    }
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionStatus>((ref) {
  return ConnectionNotifier();
});

// ==========================================
// 6. Blacklisted Suggestions Provider
// ==========================================

class BlacklistSuggestionsNotifier extends StateNotifier<Set<String>> {
  BlacklistSuggestionsNotifier() : super({}) {
    _loadBlacklist();
  }

  static const _prefKey = 'blacklisted_suggestions';

  Future<void> _loadBlacklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey);
      if (list != null) {
        state = list.toSet();
      }
    } catch (e) {
      debugPrint('Error loading blacklisted suggestions: $e');
    }
  }

  Future<void> blacklist(String key) async {
    state = {...state, key};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, state.toList());
    } catch (e) {
      debugPrint('Error saving blacklisted suggestions: $e');
    }
  }

  Future<void> clearBlacklist() async {
    state = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (e) {
      debugPrint('Error clearing blacklisted suggestions: $e');
    }
  }
}

final blacklistSuggestionsProvider = StateNotifierProvider<BlacklistSuggestionsNotifier, Set<String>>((ref) {
  return BlacklistSuggestionsNotifier();
});

// ==========================================
// 7. Package Info Provider
// ==========================================

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});