import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/models/profile.dart';
import 'package:spendly/core/services/hive_service.dart';
import 'package:spendly/models/hive/profile_model.dart';

// 1. Session Provider
// Watches the stream of Supabase Auth state changes and maps it to Session.
final sessionProvider = StreamProvider<Session?>((ref) {
  // If Supabase is not initialized (e.g. mock sandbox mode), return empty stream.
  try {
    return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session);
  } catch (e) {
    debugPrint('Supabase Auth stream error: $e');
    return const Stream.empty();
  }
});

// 2. Current User Provider
// Exposes the currently authenticated native Supabase User.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session != null) {
    return session.user;
  }
  // Try direct lookup if stream is not loaded yet
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
});

// 3. Profile Provider
// AsyncNotifier that loads the Profile model for the currently logged-in user.
class ProfileNotifier extends FamilyAsyncNotifier<Profile?, String> {
  @override
  FutureOr<Profile?> build(String arg) async {
    Profile? cachedProfile;
    try {
      final cachedModel = HiveService.profiles.get(arg);
      if (cachedModel != null) {
        cachedProfile = cachedModel.toDomain();
      }
    } catch (e) {
      debugPrint('Error loading cached profile from Hive: $e');
    }

    if (cachedProfile != null) {
      // Return cached profile immediately and refresh in background
      Future.microtask(() => refreshSilently());
      return cachedProfile;
    }

    return await _fetchRemoteProfile();
  }

  Future<Profile?> _fetchRemoteProfile() async {
    try {
      final client = Supabase.instance.client;
      final data = await client.from('profiles').select().eq('id', arg).maybeSingle();
      if (data != null) {
        final profile = Profile.fromJson(data);
        await HiveService.profiles.put(arg, ProfileModel.fromDomain(profile));
        return profile;
      }
    } catch (e) {
      debugPrint('Error fetching remote profile for $arg: $e');
    }
    return null;
  }

  Future<void> refreshSilently() async {
    try {
      final profile = await _fetchRemoteProfile();
      if (profile != null) {
        state = AsyncValue.data(profile);
      }
    } catch (e) {
      debugPrint('Error silently refreshing profile: $e');
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchRemoteProfile();
    });
  }
}

final profileNotifierProvider = AsyncNotifierProviderFamily<ProfileNotifier, Profile?, String>(() {
  return ProfileNotifier();
});

// Helper provider to resolve current user's profile
final profileProvider = Provider<AsyncValue<Profile?>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return const AsyncValue.data(null);
  }
  return ref.watch(profileNotifierProvider(user.id));
});
