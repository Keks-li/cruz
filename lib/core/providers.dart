import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/agent_repository.dart';
import '../data/repositories/zone_repository.dart';
import '../data/repositories/settings_repository.dart';

/// Global Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProductRepository(supabase);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return CustomerRepository(supabase);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PaymentRepository(supabase);
});

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AgentRepository(supabase);
});

final zoneRepositoryProvider = Provider<ZoneRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ZoneRepository(supabase);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SettingsRepository(supabase);
});
