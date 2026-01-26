import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/product.dart';
import '../data/models/profile.dart';
import '../data/models/payment.dart';
import '../data/models/zone.dart';
import '../data/models/customer.dart';

/// Provider for all products
final productsListProvider = FutureProvider<List<Product>>((ref) async {
  final productRepo = ref.watch(productRepositoryProvider);
  return await productRepo.fetchProducts();
});

/// Provider for all agents
final agentsListProvider = FutureProvider<List<Profile>>((ref) async {
  final agentRepo = ref.watch(agentRepositoryProvider);
  return await agentRepo.fetchAgents();
});

/// Provider for all zones
final zonesListProvider = FutureProvider<List<Zone>>((ref) async {
  final zoneRepo = ref.watch(zoneRepositoryProvider);
  return await zoneRepo.fetchZones();
});

/// Provider for all customers (admin view)
final allCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final customerRepo = ref.watch(customerRepositoryProvider);
  return await customerRepo.fetchAllCustomers();
});

/// Provider for daily collections by date
final dailyCollectionsProvider = FutureProvider.family<List<Payment>, DateTime>((ref, date) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchPaymentsByDate(date);
});

/// Provider for dashboard statistics
final dashboardStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  
  // Fetch total payment collections
  final totalPaymentCollections = await paymentRepo.fetchTotalRevenue();
  
  // Fetch projected revenue (sum of all balance_due)
  final balanceResponse = await supabase
      .from('customers')
      .select('balance_due');
  
  final projectedRevenue = (balanceResponse as List)
      .map((json) => (json['balance_due'] as num).toDouble())
      .fold<double>(0.0, (sum, balance) => sum + balance);
  
  // Calculate registration income (sum of actual fees paid by each customer)
  final registrationResponse = await supabase
      .from('customers')
      .select('registration_fee_paid');
  
  final registrationIncome = (registrationResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);
  
  // Total revenue = payment collections + registration income
  final totalRevenue = totalPaymentCollections + registrationIncome;
  
  return {
    'totalRevenue': totalRevenue,
    'projectedRevenue': projectedRevenue,
    'registrationIncome': registrationIncome,
  };
});

/// Provider for product active customer counts (Point 5)
final productCustomerCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  return await customerProductRepo.getAllProductCustomerCounts();
});

/// Provider for a specific agent's daily collection (Point 9)
final agentDailyCollectionForAdminProvider = FutureProvider.family<double, ({String agentId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchAgentDailyCollection(params.agentId, params.date);
});

/// Provider for a specific agent's daily payments (Point 9)
final agentDailyPaymentsForAdminProvider = FutureProvider.family<List<Payment>, ({String agentId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchAgentDailyPayments(params.agentId, params.date);
});

/// Provider for a specific agent's customer count (Point 9)
final agentCustomerCountForAdminProvider = FutureProvider.family<int, String>((ref, agentId) async {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final customers = await customerRepo.fetchCustomersByAgent(agentId);
  return customers.length;
});
