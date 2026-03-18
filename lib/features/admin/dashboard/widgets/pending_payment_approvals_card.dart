import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../providers/admin_providers.dart';

class PendingPaymentApprovalsCard extends ConsumerWidget {
  const PendingPaymentApprovalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovalsAsync = ref.watch(pendingPaymentApprovalsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BACKDATED PAYMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.adminTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            pendingApprovalsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No pending approvals',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final dateStr =
                        '${payment.timestamp.day.toString().padLeft(2, '0')}/${payment.timestamp.month.toString().padLeft(2, '0')}/${payment.timestamp.year}';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.customerName ??
                                          'Unknown Customer',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline_rounded,
                                          size: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          payment.agentName ?? 'Unknown Agent',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'GHC ${payment.amountPaid.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.adminPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 12,
                                          color: Colors.orange.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: Colors.orange.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleApprove(
                                context,
                                ref,
                                payment.id,
                                payment.amountPaid,
                                dateStr,
                                payment.customerName ?? 'Unknown',
                              ),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                              label: const Text('Review & Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading requests: $error',
                    style: TextStyle(color: AppTheme.dangerColor, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    WidgetRef ref,
    String paymentId,
    double amount,
    String dateStr,
    String customerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Approve Backdated Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to approve this backdated payment?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: $customerName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Amount: GHC ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $dateStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Approving will officially record the payment and update the customer\'s balance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final paymentRepo = ref.read(paymentRepositoryProvider);
        await paymentRepo.approvePayment(paymentId);

        // Refresh the pending requests and dashboard stats
        ref.invalidate(pendingPaymentApprovalsProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(dailyCollectionsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment approved successfully',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString().replaceAll("Exception: ", "")}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
