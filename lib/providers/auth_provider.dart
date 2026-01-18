import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers.dart';
import '../data/models/profile.dart';

/// Stream provider for auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Provider for the current authenticated user's profile
final currentUserProvider = FutureProvider<Profile?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.getCurrentUser();
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.isAuthenticated;
});
