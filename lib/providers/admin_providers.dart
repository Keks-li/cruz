import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/product.dart';
import '../data/models/profile.dart';
import '../data/models/payment.dart';
import '../data/models/payment_edit_request.dart';
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
  
  // Fetch total product value from customer_products table (boxes_assigned * price_per_box via products join)
  final cpProductsResponse = await supabase
      .from('customer_products')
      .select('boxes_assigned, products!inner(box_rate)');
  
  final cpProductTotal = (cpProductsResponse as List)
      .map((json) {
        final boxes = (json['boxes_assigned'] as num).toDouble();
        final boxRate = (json['products']['box_rate'] as num).toDouble();
        return boxes * boxRate;
      })
      .fold<double>(0.0, (sum, value) => sum + value);
  
  // Calculate registration income from customers table
  final customerRegResponse = await supabase
      .from('customers')
      .select('registration_fee_paid');
  
  final customerRegIncome = (customerRegResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);
  
  // Calculate registration income from customer_products table
  final cpRegResponse = await supabase
      .from('customer_products')
      .select('registration_fee_paid');
  
  final cpRegIncome = (cpRegResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);
  
  final registrationIncome = customerRegIncome + cpRegIncome;
  
  // Projected Revenue = total products assigned value + registration fees
  final projectedRevenue = cpProductTotal + registrationIncome;
  
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
  final supabase = ref.watch(supabaseClientProvider);
  
  // 1. Fetch standard payments
  final paymentsTotal = await paymentRepo.fetchAgentDailyCollection(params.agentId, params.date);

  // 2. Fetch registration fees from NEW products (customer_products) created on this date
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = DateTime(params.date.year, params.date.month, params.date.day, 23, 59, 59);

  final regFeesResponse = await supabase
      .from('customer_products')
      .select('registration_fee_paid, customers!inner(assigned_agent_id)')
      .eq('customers.assigned_agent_id', params.agentId)
      .gte('created_at', startOfDay.toIso8601String())
      .lte('created_at', endOfDay.toIso8601String());

  final regFeesTotal = (regFeesResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);

  return paymentsTotal + regFeesTotal;
});

/// Provider for a specific agent's daily payments (Point 9)
final agentDailyPaymentsForAdminProvider = FutureProvider.family<List<Payment>, ({String agentId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchAgentDailyPayments(params.agentId, params.date);
});

/// Provider for a specific agent's customer count (Point 9)
/// UPDATED: Now counts TOTAL PRODUCTS assigned, not just unique customers
final agentCustomerCountForAdminProvider = FutureProvider.family<int, String>((ref, agentId) async {
  final supabase = ref.watch(supabaseClientProvider);
  
  // Count items in customer_products where the linked customer belongs to this agent
  final response = await supabase
      .from('customer_products')
      .select('id, customers!inner(assigned_agent_id)')
      .eq('customers.assigned_agent_id', agentId);
      
  return (response as List).length;
});

/// Provider for pending payment edit requests (admin approval)
final pendingEditRequestsProvider = FutureProvider<List<PaymentEditRequest>>((ref) async {
  final requestRepo = ref.watch(paymentEditRequestRepositoryProvider);
  return await requestRepo.fetchPendingRequests();
});

/// Provider for all payment edit requests (history)
final allEditRequestsProvider = FutureProvider<List<PaymentEditRequest>>((ref) async {
  final requestRepo = ref.watch(paymentEditRequestRepositoryProvider);
  return await requestRepo.fetchAllRequests();
});
