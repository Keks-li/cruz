import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_providers.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/payment.dart';

/// Selected date provider for admin agent profile view
final adminAgentSelectedDateProvider = StateProvider.family<DateTime, String>((ref, agentId) {
  return DateTime.now();
});

class AgentProfileScreen extends ConsumerWidget {
  final Profile agent;

  const AgentProfileScreen({super.key, required this.agent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(adminAgentSelectedDateProvider(agent.id));
    final dailyCollectionAsync = ref.watch(
      agentDailyCollectionForAdminProvider((agentId: agent.id, date: selectedDate)),
    );
    final dailyPaymentsAsync = ref.watch(
      agentDailyPaymentsForAdminProvider((agentId: agent.id, date: selectedDate)),
    );
    final customerCountAsync = ref.watch(
      agentCustomerCountForAdminProvider(agent.id),
    );
    final dailyRegistrationsAsync = ref.watch(
      agentDailyRegistrationsForAdminProvider((agentId: agent.id, date: selectedDate)),
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
          'Agent Profile',
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
            // Agent Info Card
            _buildAgentInfoCard(context),
            const SizedBox(height: 24),

            // Daily Collection Card with Date Picker (Point 9)
            _buildDailyCollectionCard(context, ref, selectedDate, dailyCollectionAsync),
            const SizedBox(height: 16),

            // Daily Registrations Card
            _buildDailyRegistrationsCard(selectedDate, dailyRegistrationsAsync),
            const SizedBox(height: 16),

            // Customer Count Card
            _buildCustomerCountCard(customerCountAsync),
            const SizedBox(height: 32),

            // Collections History for Selected Date
            _buildCollectionsHistorySection(ref, dailyPaymentsAsync, selectedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: agent.isActive
                  ? AppTheme.adminAccentRevenue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: agent.isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade400,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.fullName ?? 'Agent',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.adminTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  agent.email ?? 'No email',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: agent.isActive
                        ? AppTheme.adminAccentRevenue.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    agent.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: agent.isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade600,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCollectionCard(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    AsyncValue<double> dailyCollectionAsync,
  ) {
    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL COLLECTED",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              // Date Picker Button
              InkWell(
                onTap: () => _selectDate(context, ref, selectedDate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          dailyCollectionAsync.when(
            data: (collection) => Text(
              'GHC ${collection.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            loading: () => const SizedBox(
              height: 36,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            error: (_, __) => const Text(
              'Error loading',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRegistrationsCard(
    DateTime selectedDate,
    AsyncValue<int> dailyRegistrationsAsync,
  ) {
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
              Icons.person_add_rounded,
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
                  'TOTAL REGISTERED ${_formatDateLabel(selectedDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                dailyRegistrationsAsync.when(
                  data: (count) => Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminTextColor,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('Error', style: TextStyle(color: AppTheme.dangerColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCountCard(AsyncValue<int> customerCountAsync) {
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
              color: AppTheme.adminPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppTheme.adminPrimaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PRODUCTS REGISTERED',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                customerCountAsync.when(
                  data: (count) => Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminTextColor,
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('Error', style: TextStyle(color: AppTheme.dangerColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsHistorySection(
    WidgetRef ref,
    AsyncValue<List<Payment>> dailyPaymentsAsync,
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
              dailyPaymentsAsync.when(
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
        dailyPaymentsAsync.when(
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
                  payment.productName ?? 'Product',
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
      ref.read(adminAgentSelectedDateProvider(agent.id).notifier).state = picked;
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

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'TODAY';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'YESTERDAY';
    }
    return 'ON ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
