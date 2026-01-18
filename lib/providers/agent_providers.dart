import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/payment.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';
import '../data/models/zone.dart';
import '../providers/auth_provider.dart';

/// Provider for agent's lifetime collection (money and boxes)
final agentStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return {'money': 0.0, 'boxes': 0.0};
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final money = await paymentRepo.fetchAgentLifetimeCollection(currentUser.id);
  final boxes = await paymentRepo.fetchAgentTotalBoxesCollected(currentUser.id);
  
  return {'money': money, 'boxes': boxes};
});

/// Provider for agent's payment history
final agentPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchPaymentsByAgent(currentUser.id);
});

/// Provider for agent's assigned customers
final assignedCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final customerRepo = ref.watch(customerRepositoryProvider);
  return await customerRepo.fetchCustomersByAgent(currentUser.id);
});

/// Provider for zones (from zones table)
final zonesProvider = FutureProvider<List<Zone>>((ref) async {
  final zoneRepo = ref.watch(zoneRepositoryProvider);
  return await zoneRepo.fetchZones();
});

/// Provider for products (reused from admin but accessible to agents)
final agentProductsProvider = FutureProvider<List<Product>>((ref) async {
  final productRepo = ref.watch(productRepositoryProvider);
  return await productRepo.fetchProducts();
});
