import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import '../../../data/models/product.dart';
import '../../../data/models/payment.dart';

/// State provider for selected date in product detail screen
final productDetailSelectedDateProvider = StateProvider.family<DateTime, int>((ref, productId) {
  return DateTime.now();
});

/// Provider for product assignment history by date
final productPaymentHistoryProvider = FutureProvider.family<List<Payment>, ({int productId, DateTime date})>((ref, params) async {
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  
  // Fetch payments for this product on the selected date
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = DateTime(params.date.year, params.date.month, params.date.day, 23, 59, 59);
  
  final response = await ref.watch(supabaseClientProvider)
      .from('payments')
      .select('''
        *,
        product_id,
        customers!left(full_name, product_id, products!left(name)),
        profiles!agent_id(full_name)
      ''')
      .gte('timestamp', startOfDay.toIso8601String())
      .lte('timestamp', endOfDay.toIso8601String())
      .order('timestamp', ascending: false);

  // Filter: Include payment if:
  // 1. payment.product_id matches (NEW)
  // 2. OR payment.product_id is null AND customer.main_product_id matches (LEGACY)
  final payments = (response as List)
      .where((json) {
        final paymentProductIdRaw = json['product_id'];
        if (paymentProductIdRaw != null) {
          // New logic: check direct payment->product link
          final paymentProductId = paymentProductIdRaw.toString();
          return paymentProductId == params.productId.toString();
        } else {
          // Legacy logic: check customer->main_product link
          // This only works for legacy single-product customers
          final customerProductId = json['customers']?['product_id']?.toString();
          return customerProductId == params.productId.toString();
        }
      })
      .map((json) {
        final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
        if (payment['customers'] != null) {
          payment['customer_name'] = payment['customers']['full_name'];
          if (payment['customers']['products'] != null) {
            payment['product_name'] = payment['customers']['products']['name'];
          }
        }
        if (payment['profiles'] != null) {
          payment['agent_name'] = payment['profiles']['full_name'];
        }
        return Payment.fromJson(payment);
      })
      .toList();

  return payments;
});

class ProductDetailScreen extends ConsumerWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(productDetailSelectedDateProvider(product.id));
    final customerCountsAsync = ref.watch(productCustomerCountsProvider);
    final paymentHistoryAsync = ref.watch(
      productPaymentHistoryProvider((productId: product.id, date: selectedDate)),
    );

    final customerCount = customerCountsAsync.when(
      data: (counts) => counts[product.id] ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.adminTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Card
            _buildProductInfoCard(context, customerCount),
            const SizedBox(height: 24),

            // Customer Count Card
            _buildCustomerCountCard(customerCount),
            const SizedBox(height: 24),

            // Date Picker Card
            _buildDatePickerCard(context, ref, selectedDate),
            const SizedBox(height: 32),

            // Payment History for Selected Date
            _buildPaymentHistorySection(ref, paymentHistoryAsync, selectedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(BuildContext context, int customerCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.adminPrimaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.totalBoxes} Boxes • GHC ${product.boxRate.toStringAsFixed(0)}/box',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL VALUE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GHC ${product.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$customerCount Customers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCountCard(int customerCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.adminAccentRevenue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppTheme.adminAccentRevenue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUSTOMERS ASSIGNED',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$customerCount',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.adminTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.adminAccentRevenue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyle(
                color: AppTheme.adminAccentRevenue,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VIEWING HISTORY FOR',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.adminTextColor,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _selectDate(context, ref, selectedDate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.adminPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Change Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistorySection(
    WidgetRef ref,
    AsyncValue<List<Payment>> paymentHistoryAsync,
    DateTime selectedDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COLLECTIONS - ${_formatDate(selectedDate)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              paymentHistoryAsync.when(
                data: (payments) => '${payments.length} transactions',
                loading: () => '...',
                error: (_, __) => 'Error',
              ),
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        paymentHistoryAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No collections for this date',
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: payments.map((payment) => _buildPaymentHistoryItem(payment)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppTheme.adminPrimaryColor),
            ),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error', style: const TextStyle(color: AppTheme.dangerColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryItem(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.adminAccentRevenue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: AppTheme.adminAccentRevenue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.customerName ?? 'Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.adminTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${payment.agentName ?? 'Agent'}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GHC ${payment.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.adminAccentRevenue,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (payment.boxesEquivalent != null)
                Text(
                  '${payment.boxesEquivalent} Boxes',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.adminPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.adminTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(productDetailSelectedDateProvider(product.id).notifier).state = picked;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
