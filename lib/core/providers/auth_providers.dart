import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spendly/models/profile.dart';

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
    // If no user is logged in or we are in mock mode, return null
    try {
      final client = Supabase.instance.client;
      final data = await client.from('profiles').select().eq('id', arg).maybeSingle();
      if (data != null) {
        return Profile.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching profile for $arg: $e');
    }
    return null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = Supabase.instance.client;
      final data = await client.from('profiles').select().eq('id', arg).maybeSingle();
      if (data != null) {
        return Profile.fromJson(data);
      }
      return null;
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
