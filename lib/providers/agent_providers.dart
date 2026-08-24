import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/payment.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';
import '../data/models/zone.dart';
import '../data/models/cycle.dart';
import '../providers/auth_provider.dart';

/// Provider for selected date on agent dashboard (default: today)
final agentSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Provider for agent's daily collection based on selected date (Point 6, filtered by active cycle)
final agentDailyCollectionProvider = FutureProvider.autoDispose<double>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return 0.0;
  
  final selectedDate = ref.watch(agentSelectedDateProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  
  return await paymentRepo.fetchAgentDailyCollection(currentUser.id, selectedDate, cycleId: activeCycle?.id);
});

/// Provider for agent's daily payments list with product details (Point 6, filtered by active cycle)
final agentDailyPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final selectedDate = ref.watch(agentSelectedDateProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  
  return await paymentRepo.fetchAgentDailyPayments(currentUser.id, selectedDate, cycleId: activeCycle?.id);
});

/// Provider for agent's lifetime collection (money and boxes, filtered by active cycle)
final agentStatsProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return {'money': 0.0, 'boxes': 0.0};
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  final money = await paymentRepo.fetchAgentLifetimeCollection(currentUser.id, cycleId: activeCycle?.id);
  final boxes = await paymentRepo.fetchAgentTotalBoxesCollected(currentUser.id, cycleId: activeCycle?.id);
  
  return {'money': money, 'boxes': boxes};
});

/// Provider for agent's registration stats (count and total fees, filtered by active cycle)
final agentRegistrationStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final currentUser = await ref.watch(currentUserProvider.future);
    if (currentUser == null) return {'count': 0, 'totalFees': 0.0};
    
    final supabase = ref.watch(supabaseClientProvider);
    final activeCycle = await ref.watch(agentActiveCycleProvider.future);
    final cycleId = activeCycle?.id;
    
    // Fetch customers and their product registrations to calculate fees
    var query = supabase
        .from('customers')
        .select('''
          id,
          customer_products(registration_fee_paid, cycle_id)
        ''')
        .eq('assigned_agent_id', currentUser.id);

    if (cycleId != null) {
      query = query.eq('cycle_id', cycleId);
    }
    
    final response = await query;
    final customers = response as List;
    
    var totalCount = 0;
    final totalFees = customers.fold<double>(0.0, (sum, customer) {
      final products = customer['customer_products'] as List?;
      if (products == null || products.isEmpty) return sum;
      
      final matchingProducts = cycleId != null
          ? products.where((p) => p['cycle_id'] == cycleId).toList()
          : products;

      totalCount += matchingProducts.length;
      
      final customerFees = matchingProducts
          .map((p) => (p['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0.0, (pSum, fee) => pSum + fee);
          
      return sum + customerFees;
    });
    
    return {'count': totalCount, 'totalFees': totalFees};
  } catch (e) {
    return {'count': 0, 'totalFees': 0.0};
  }
});

/// Provider for agent's payment history (filtered by active cycle)
final agentPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  return await paymentRepo.fetchPaymentsByAgent(currentUser.id, cycleId: activeCycle?.id);
});

/// Provider for agent's assigned customers (filtered by active cycle)
final assignedCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final customerRepo = ref.watch(customerRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  return await customerRepo.fetchCustomersByAgent(currentUser.id, cycleId: activeCycle?.id);
});

/// Provider for total registered products count (filtered by active cycle)
final agentCustomerCountProvider = FutureProvider<int>((ref) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return 0;
  
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  final allProducts = await customerProductRepo.fetchProductsByAgent(currentUser.id, cycleId: activeCycle?.id);
  return allProducts.length;
});

/// Provider for zones (from zones table)
final zonesProvider = FutureProvider<List<Zone>>((ref) async {
  final zoneRepo = ref.watch(zoneRepositoryProvider);
  return await zoneRepo.fetchZones();
});

/// Provider for products (filtered by active cycle)
final agentProductsProvider = FutureProvider<List<Product>>((ref) async {
  final productRepo = ref.watch(productRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  return await productRepo.fetchProducts(cycleId: activeCycle?.id);
});

/// Provider for settings (for registration fee)
final settingsProvider = FutureProvider<({double registrationFee})>((ref) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final fee = await settingsRepo.getRegistrationFee();
  return (registrationFee: fee);
});

/// Provider for fetching products assigned to a specific customer (filtered by active cycle)
final customerProductsProvider = FutureProvider.family((ref, String customerId) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  return await customerProductRepo.fetchProductsByCustomer(customerId, cycleId: activeCycle?.id);
});

/// Provider for the currently active cycle (agent context)
final agentActiveCycleProvider = FutureProvider<Cycle?>((ref) async {
  final cycleRepo = ref.watch(cycleRepositoryProvider);
  return await cycleRepo.fetchActiveCycle();
});

/// Provider for fetching payment history of a specific customer (filtered by active cycle)
final customerPaymentHistoryProvider = FutureProvider.family<List<Payment>, String>((ref, customerId) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final activeCycle = await ref.watch(agentActiveCycleProvider.future);
  return await paymentRepo.fetchPaymentsByCustomer(customerId, cycleId: activeCycle?.id);
});
