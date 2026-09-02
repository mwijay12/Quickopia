import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );
    // Note: the `profiles` row is created automatically by the Postgres
    // trigger from Prompt 1 (handle_new_user) — no manual insert needed here.
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    // Small retry loop: the profile-creation trigger runs as part of the
    // signup transaction, but on very first signup+login there's a rare
    // timing edge case on slower connections — retry once before giving up.
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (response != null) return Profile.fromMap(response);
      } catch (_) {
        // Retry if connection is still stabilizing
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }
}
