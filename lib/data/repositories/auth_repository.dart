import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Sign in with email and password, then fetch the user's profile
  Future<Profile> signIn(String email, String password) async {
    try {
      // Authenticate with Supabase
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // Fetch the user's profile from the profiles table
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      return Profile.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get the current authenticated user's profile
  Future<Profile?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return Profile.fromJson(profileData);
    } catch (e) {
      // User not logged in or profile doesn't exist
      return null;
    }
  }

  /// Sign up a new agent (self-registration)
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user account
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      // Create profile with AGENT role (inactive by default)
      final profileData = await _supabase
          .from('profiles')
          .insert({
            'id': authResponse.user!.id,
            'role': 'AGENT',
            'full_name': fullName,
            'email': email,
            'is_active': false, // Requires admin activation
          })
          .select()
          .single();

      return Profile.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  /// Create a new agent (admin function)
  Future<Profile> createAgent({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user in Supabase Auth
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true, // Auto-confirm email
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      // Create profile with AGENT role
      final profileData = await _supabase
          .from('profiles')
          .insert({
            'id': authResponse.user!.id,
            'role': 'AGENT',
            'full_name': fullName,
            'email': email,
            'is_active': true,
          })
          .select()
          .single();

      return Profile.fromJson(profileData);
    } on AuthException catch (e) {
      throw Exception('Failed to create agent: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Check if user is currently authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;
}
