import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kanjad/basicdata/utilisateur.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
      emailRedirectTo:
          'http://localhost:3000/confirm', // Add email confirmation redirect
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Create user profile in the database
  Future<void> createUser(Utilisateur utilisateur) async {
    try {
      await _supabase.from('utilisateurs').insert(utilisateur.toMap());
    } catch (e, s) {
      print('Error creating user profile: $e\n$s');
      rethrow;
    }
  }
}
