import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
