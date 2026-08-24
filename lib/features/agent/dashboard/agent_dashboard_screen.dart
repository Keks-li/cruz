import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/agent_providers.dart';
import '../../auth/login_screen.dart';
import '../customers/lookup_client_screen.dart';
import '../registration/new_registration_screen.dart';
import '../ledger/collection_ledger_screen.dart';

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyCollectionAsync = ref.watch(agentDailyCollectionProvider);
    final customerCountAsync = ref.watch(agentCustomerCountProvider);
    final dailyPaymentsAsync = ref.watch(agentDailyPaymentsProvider);
    final selectedDate = ref.watch(agentSelectedDateProvider);
    final registrationStatsAsync = ref.watch(agentRegistrationStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.agentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agent Dashboard',
              style: TextStyle(
                color: AppTheme.agentTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            ref.watch(agentActiveCycleProvider).when(
              data: (cycle) => Text(
                cycle != null ? 'Cycle: ${cycle.name}' : 'No Active Cycle',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.agentPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerColor, size: 22),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Single Consolidated Hero Card
            _buildDailyCollectionCard(
              context,
              ref,
              dailyCollectionAsync,
              customerCountAsync,
              registrationStatsAsync,
              selectedDate,
            ),
            const SizedBox(height: 20),

            // Primary Actions: 2 Equal-weight Cards
            _buildActionGrid(context),
            const SizedBox(height: 14),

            // Secondary Action: Ledger Row
            _buildLedgerRow(context),
            const SizedBox(height: 28),

            // Collections History for Selected Date
            _buildCollectionsHistorySection(context, ref, dailyPaymentsAsync, selectedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCollectionCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<double> dailyCollectionAsync,
    AsyncValue<int> customerCountAsync,
    AsyncValue<Map<String, dynamic>> registrationStatsAsync,
    DateTime selectedDate,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.agentPrimaryColor,
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
                "TODAY'S COLLECTION",
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          dailyCollectionAsync.when(
            data: (collection) => Text(
              'GHC ${collection.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            loading: () => const SizedBox(
              height: 34,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            error: (_, __) => const Text(
              'Error loading',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              customerCountAsync.when(
                data: (count) => _buildMetricChip(
                  Icons.people_alt_rounded,
                  '$count Customers',
                ),
                loading: () => _buildMetricChip(Icons.people_alt_rounded, '... Customers'),
                error: (_, __) => const SizedBox.shrink(),
              ),
              registrationStatsAsync.when(
                data: (stats) {
                  final rawCount = stats['count'];
                  final count = rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? 0;
                  return _buildMetricChip(
                    Icons.how_to_reg_rounded,
                    '$count New Clients',
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            'Customers',
            'Lookup & Collect',
            Icons.people_rounded,
            AppTheme.agentPrimaryColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LookupClientScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionCard(
            context,
            'Register New',
            'New Customer',
            Icons.person_add_rounded,
            AppTheme.agentAccentRegister,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NewRegistrationScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.agentTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CollectionLedgerScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.agentAccentSync.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.agentAccentSync,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collection Ledger',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.agentTextColor,
                    ),
                  ),
                  Text(
                    'Full payment history & edit requests',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsHistorySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> dailyPaymentsAsync,
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
              child: CircularProgressIndicator(color: AppTheme.agentPrimaryColor),
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dangerColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppTheme.dangerColor, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Failed to load collections',
                  style: const TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(agentDailyPaymentsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryItem(dynamic payment) {
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
              color: AppTheme.agentPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: AppTheme.agentPrimaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.productName ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.agentTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.customerName ?? 'Customer',
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
                  color: AppTheme.agentPrimaryColor,
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
              primary: AppTheme.agentPrimaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.agentTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(agentSelectedDateProvider.notifier).state = picked;
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
