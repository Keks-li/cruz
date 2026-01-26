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
        title: const Text(
          'Agent Dashboard',
          style: TextStyle(
            color: AppTheme.agentTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card - Today's Collection with Date Picker
            _buildDailyCollectionCard(
              context,
              ref,
              dailyCollectionAsync,
              customerCountAsync,
              selectedDate,
            ),
            const SizedBox(height: 24),
            
            // Total Registered Customers Card (Point 6)
            _buildCustomerCountCard(customerCountAsync),
            const SizedBox(height: 16),

            // Registration Stats Card (NEW - shows total registrations and fees)
            _buildRegistrationStatsCard(registrationStatsAsync),
            const SizedBox(height: 24),

            // Action Grid
            _buildActionGrid(context),
            const SizedBox(height: 32),

            // Collections History for Selected Date (Point 6)
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
    DateTime selectedDate,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                  fontSize: 13,
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
          const SizedBox(height: 20),
          Row(
            children: [
              customerCountAsync.when(
                data: (count) => _buildMetricChip(
                  Icons.people_alt_rounded,
                  '$count Customers',
                ),
                loading: () => _buildMetricChip(Icons.people_alt_rounded, '...'),
                error: (_, __) => _buildMetricChip(Icons.people_alt_rounded, 'Error'),
              ),
            ],
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
              color: AppTheme.agentAccentRegister.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: AppTheme.agentAccentRegister,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL REGISTERED CUSTOMERS',
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
                      color: AppTheme.agentTextColor,
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

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Customers',
                Icons.people_rounded,
                AppTheme.agentPrimaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LookupClientScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                'Register New',
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
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          'Collection Ledger',
          Icons.receipt_long_rounded,
          AppTheme.agentAccentSync,
          isFullWidth: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CollectionLedgerScreen()),
            );
          },
        ),
      ],
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
          error: (error, _) => Center(
            child: Text('Error: $error', style: const TextStyle(color: AppTheme.dangerColor)),
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

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color accentColor, {
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: isFullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: accentColor),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.agentTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
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
