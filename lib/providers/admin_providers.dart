import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../data/models/product.dart';
import '../data/models/profile.dart';
import '../data/models/payment.dart';
import '../data/models/payment_edit_request.dart';
import '../data/models/zone.dart';
import '../data/models/customer.dart';
import '../data/models/cycle.dart';

/// StateProvider for the cycle selected in admin dashboard/screens (null = use active cycle)
final selectedCycleIdProvider = StateProvider<int?>((ref) => null);

/// Provider for the resolved admin cycle (uses manual selection if set, otherwise active cycle)
final currentAdminCycleProvider = FutureProvider<Cycle?>((ref) async {
  final selectedCycleId = ref.watch(selectedCycleIdProvider);
  final allCycles = await ref.watch(cyclesListProvider.future);
  if (selectedCycleId != null) {
    try {
      return allCycles.firstWhere((c) => c.id == selectedCycleId);
    } catch (_) {}
  }
  return await ref.watch(activeCycleProvider.future);
});

/// Provider for all products (filtered by current cycle)
final productsListProvider = FutureProvider<List<Product>>((ref) async {
  final productRepo = ref.watch(productRepositoryProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  return await productRepo.fetchProducts(cycleId: currentCycle?.id);
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

/// Provider for all customers (admin view, filtered by current cycle)
final allCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final customerRepo = ref.watch(customerRepositoryProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  return await customerRepo.fetchAllCustomers(cycleId: currentCycle?.id);
});

/// Provider for daily collections by date (filtered by current cycle)
final dailyCollectionsProvider = FutureProvider.family<List<Payment>, DateTime>((ref, date) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  return await paymentRepo.fetchPaymentsByDate(date, cycleId: currentCycle?.id);
});

/// Provider for dashboard statistics (filtered by current cycle)
final dashboardStatsProvider = FutureProvider<Map<String, double>>((ref) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  final cycleId = currentCycle?.id;
  
  // Fetch total payment collections for this cycle
  final totalPaymentCollections = await paymentRepo.fetchTotalRevenue(cycleId: cycleId);
  
  // Fetch total product value from customer_products table for this cycle
  var cpQuery = supabase
      .from('customer_products')
      .select('boxes_assigned, products!inner(box_rate)');
  if (cycleId != null) {
    cpQuery = cpQuery.eq('cycle_id', cycleId);
  }
  final cpProductsResponse = await cpQuery;
  
  final cpProductTotal = (cpProductsResponse as List)
      .map((json) {
        final boxes = (json['boxes_assigned'] as num).toDouble();
        final boxRate = (json['products']['box_rate'] as num).toDouble();
        return boxes * boxRate;
      })
      .fold<double>(0.0, (sum, value) => sum + value);
  
  // Calculate registration income from customers table for this cycle
  var custQuery = supabase
      .from('customers')
      .select('registration_fee_paid');
  if (cycleId != null) {
    custQuery = custQuery.eq('cycle_id', cycleId);
  }
  final customerRegResponse = await custQuery;
  
  final customerRegIncome = (customerRegResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);
  
  // Calculate registration income from customer_products table for this cycle
  var cpRegQuery = supabase
      .from('customer_products')
      .select('registration_fee_paid');
  if (cycleId != null) {
    cpRegQuery = cpRegQuery.eq('cycle_id', cycleId);
  }
  final cpRegResponse = await cpRegQuery;
  
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

/// Provider for product active customer counts (Point 5, filtered by cycle)
final productCustomerCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  return await customerProductRepo.getAllProductCustomerCounts(cycleId: currentCycle?.id);
});

/// Provider for a specific agent's daily collection (Point 9, filtered by cycle)
final agentDailyCollectionForAdminProvider = FutureProvider.family<double, ({String agentId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  final cycleId = currentCycle?.id;
  
  // 1. Fetch standard payments
  final paymentsTotal = await paymentRepo.fetchAgentDailyCollection(params.agentId, params.date, cycleId: cycleId);

  // 2. Fetch registration fees from NEW products (customer_products) created on this date
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = DateTime(params.date.year, params.date.month, params.date.day, 23, 59, 59);

  var regQuery = supabase
      .from('customer_products')
      .select('registration_fee_paid, customers!inner(assigned_agent_id)')
      .eq('customers.assigned_agent_id', params.agentId)
      .gte('created_at', startOfDay.toIso8601String())
      .lte('created_at', endOfDay.toIso8601String());

  if (cycleId != null) {
    regQuery = regQuery.eq('cycle_id', cycleId);
  }

  final regFeesResponse = await regQuery;

  final regFeesTotal = (regFeesResponse as List)
      .map((json) => (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0.0, (sum, fee) => sum + fee);

  return paymentsTotal + regFeesTotal;
});

/// Provider for a specific agent's daily payments (Point 9, filtered by cycle)
final agentDailyPaymentsForAdminProvider = FutureProvider.family<List<Payment>, ({String agentId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  return await paymentRepo.fetchAgentDailyPayments(params.agentId, params.date, cycleId: currentCycle?.id);
});

/// Provider for a specific agent's customer count (Point 9, filtered by cycle)
final agentCustomerCountForAdminProvider = FutureProvider.family<int, String>((ref, agentId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  final cycleId = currentCycle?.id;
  
  var query = supabase
      .from('customer_products')
      .select('id, customers!inner(assigned_agent_id)')
      .eq('customers.assigned_agent_id', agentId);
      
  if (cycleId != null) {
    query = query.eq('cycle_id', cycleId);
  }
      
  final response = await query;
  return (response as List).length;
});

/// Provider for pending payment edit requests (admin approval)
final pendingEditRequestsProvider = FutureProvider<List<PaymentEditRequest>>((ref) async {
  final requestRepo = ref.watch(paymentEditRequestRepositoryProvider);
  return await requestRepo.fetchPendingRequests();
});

/// Provider for a specific agent's daily customer registrations count (filtered by cycle)
final agentDailyRegistrationsForAdminProvider = FutureProvider.family<int, ({String agentId, DateTime date})>((ref, params) async {
  final supabase = ref.watch(supabaseClientProvider);
  final currentCycle = await ref.watch(currentAdminCycleProvider.future);
  final cycleId = currentCycle?.id;
  
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = DateTime(params.date.year, params.date.month, params.date.day, 23, 59, 59);

  var query = supabase
      .from('customer_products')
      .select('id, customers!inner(assigned_agent_id)')
      .eq('customers.assigned_agent_id', params.agentId)
      .gte('created_at', startOfDay.toIso8601String())
      .lte('created_at', endOfDay.toIso8601String());

  if (cycleId != null) {
    query = query.eq('cycle_id', cycleId);
  }
      
  final response = await query;
  return (response as List).length;
});

/// Provider for pending backdated payment approvals
final pendingPaymentApprovalsProvider = FutureProvider<List<Payment>>((ref) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return await paymentRepo.fetchPendingApprovals();
});

/// Provider for all payment edit requests (history)
final allEditRequestsProvider = FutureProvider<List<PaymentEditRequest>>((ref) async {
  final requestRepo = ref.watch(paymentEditRequestRepositoryProvider);
  return await requestRepo.fetchAllRequests();
});

/// Provider for pending product deletions (admin approval)
final pendingDeletionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final customerProductRepo = ref.watch(customerProductRepositoryProvider);
  return await customerProductRepo.fetchPendingDeletions();
});

/// Provider for all business cycles
final cyclesListProvider = FutureProvider<List<Cycle>>((ref) async {
  final cycleRepo = ref.watch(cycleRepositoryProvider);
  return await cycleRepo.fetchCycles();
});

/// Provider for the currently active cycle
final activeCycleProvider = FutureProvider<Cycle?>((ref) async {
  final cycleRepo = ref.watch(cycleRepositoryProvider);
  return await cycleRepo.fetchActiveCycle();
});
