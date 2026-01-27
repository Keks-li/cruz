import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/payment.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';
import '../data/models/zone.dart';
import '../providers/auth_provider.dart';

/// Provider for selected date on agent dashboard (default: today)
final agentSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Provider for agent's daily collection based on selected date (Point 6)
final agentDailyCollectionProvider = FutureProvider.autoDispose<double>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return 0.0;
  
  final selectedDate = ref.watch(agentSelectedDateProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  
  return await paymentRepo.fetchAgentDailyCollection(currentUser.id, selectedDate);
});

/// Provider for agent's daily payments list with product details (Point 6)
final agentDailyPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final selectedDate = ref.watch(agentSelectedDateProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  
  return await paymentRepo.fetchAgentDailyPayments(currentUser.id, selectedDate);
});

/// Provider for agent's lifetime collection (money and boxes)
final agentStatsProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return {'money': 0.0, 'boxes': 0.0};
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final money = await paymentRepo.fetchAgentLifetimeCollection(currentUser.id);
  final boxes = await paymentRepo.fetchAgentTotalBoxesCollected(currentUser.id);
  
  return {'money': money, 'boxes': boxes};
});

/// Provider for agent's registration stats (count and total fees)
final agentRegistrationStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final currentUser = await ref.watch(currentUserProvider.future);
    if (currentUser == null) return {'count': 0, 'totalFees': 0.0};
    
    final supabase = ref.watch(supabaseClientProvider);
    
    // Fetch customers and their product registrations to calculate fees
    final response = await supabase
        .from('customers')
        .select('''
          id,
          customer_products(registration_fee_paid)
        ''')
        .eq('assigned_agent_id', currentUser.id);
    
    final customers = response as List;
    final count = customers.length;
    
    // Calculate total fees by summing up registration_fee_paid from all product assignments
    // AND calculate total count of product registrations (history of assignments)
    var totalCount = 0;
    final totalFees = customers.fold<double>(0.0, (sum, customer) {
      final products = customer['customer_products'] as List?;
      if (products == null || products.isEmpty) return sum;
      
      totalCount += products.length; // Count each product assignment as a registration
      
      final customerFees = products
          .map((p) => (p['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
          .fold<double>(0.0, (pSum, fee) => pSum + fee);
          
      return sum + customerFees;
    });
    
    return {'count': totalCount, 'totalFees': totalFees};
  } catch (e) {
    // Return safe default values on error
    return {'count': 0, 'totalFees': 0.0};
  }
});

/// Provider for agent's payment history
final agentPaymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchPaymentsByAgent(currentUser.id);
});

/// Provider for agent's assigned customers
final assignedCustomersProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  
  final customerRepo = ref.watch(customerRepositoryProvider);
  return await customerRepo.fetchCustomersByAgent(currentUser.id);
});

/// Provider for total registered products count (includes all products, even completed)
final agentCustomerCountProvider = FutureProvider<int>((ref) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return 0;
  
  // Count total products assigned to agent's customers (including completed/paid products)
  final allProducts = await customerProductRepo.fetchProductsByAgent(currentUser.id);
  return allProducts.length;
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

/// Provider for settings (for registration fee)
final settingsProvider = FutureProvider<({double registrationFee})>((ref) async {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final fee = await settingsRepo.getRegistrationFee();
  return (registrationFee: fee);
});

/// Provider for fetching products assigned to a specific customer
final customerProductsProvider = FutureProvider.family((ref, String customerId) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  return await customerProductRepo.fetchProductsByCustomer(customerId);
});
