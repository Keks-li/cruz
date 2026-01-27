import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_providers.dart';
import 'widgets/revenue_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/price_edit_approval_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final dailyCollectionsAsync = ref.watch(dailyCollectionsProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.adminPrimaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AppTheme.adminPrimaryColor, size: 22),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final totalRevenue = stats['totalRevenue'] ?? 0.0;
          final projectedRevenue = stats['projectedRevenue'] ?? 0.0;
          final registrationIncome = stats['registrationIncome'] ?? 0.0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Price Edit Approval Card
                const PriceEditApprovalCard(),
                RevenueCard(
                  title: 'TOTAL SYSTEM REVENUE',
                  value: 'GHC ${totalRevenue.toStringAsFixed(2)}',
                  insight: 'Total revenue reached GHC ${totalRevenue.toStringAsFixed(2)} across all active agents.',
                ),
                const SizedBox(height: 24),
                StatCard(
                  label: 'PROJECTED REVENUE',
                  value: 'GHC ${projectedRevenue.toStringAsFixed(2)}',
                  icon: Icons.trending_up_rounded,
                ),
                StatCard(
                  label: 'REGISTRATION INCOME',
                  value: 'GHC ${registrationIncome.toStringAsFixed(2)}',
                  icon: Icons.how_to_reg_rounded,
                ),
                
                // Daily Collection Check
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COLLECTION CHECK',
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w700, 
                                    letterSpacing: 1.2,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Daily Activity',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.adminTextColor,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.adminPrimaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700, 
                                        color: AppTheme.adminPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        dailyCollectionsAsync.when(
                          data: (payments) {
                            if (payments.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade200),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No collections for this date',
                                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final totalAmount = payments.fold<double>(
                              0.0,
                              (sum, payment) => sum + payment.amountPaid,
                            );
                            final totalBoxes = payments.fold<double>(
                              0.0,
                              (sum, payment) => sum + (payment.boxesEquivalent ?? 0),
                            );

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.adminPrimaryColor.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSummaryItem('GHC ${totalAmount.toStringAsFixed(0)}', 'Total', AppTheme.adminAccentRevenue),
                                      _buildSummaryItem(totalBoxes.toStringAsFixed(0), 'Boxes', AppTheme.adminPrimaryColor),
                                      _buildSummaryItem(payments.length.toString(), 'Transact.', AppTheme.adminTextColor),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: payments.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final payment = payments[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 44,
                                            width: 44,
                                            decoration: BoxDecoration(
                                              color: AppTheme.adminAccentRevenue.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.payments_rounded, color: AppTheme.adminAccentRevenue, size: 20),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  payment.customerName ?? 'Unknown',
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                                ),
                                                Text(
                                                  '${payment.agentName ?? 'Unknown'} • ${payment.productName ?? 'Product'}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'GHC${payment.amountPaid.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.adminTextColor,
                                                ),
                                              ),
                                              if (payment.boxesEquivalent != null)
                                                Text(
                                                  '${payment.boxesEquivalent} boxes',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimaryColor)),
                          error: (error, _) => Center(child: Text('Error: $error')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
