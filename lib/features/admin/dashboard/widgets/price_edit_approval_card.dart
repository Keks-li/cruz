import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../providers/admin_providers.dart';
import '../../../../providers/auth_provider.dart';

class PriceEditApprovalCard extends ConsumerWidget {
  const PriceEditApprovalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingEditRequestsProvider);

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
                    color: AppTheme.adminAccentRevenue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppTheme.adminAccentRevenue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRICE EDIT REQUESTS',
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
            pendingRequestsAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 48, color: Colors.grey.shade200),
                          const SizedBox(height: 12),
                          Text(
                            'No pending requests',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final isIncrease = request.newAmount > request.originalAmount;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
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
                                      request.customerName ?? 'Unknown Customer',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline_rounded,
                                            size: 14, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          request.agentName ?? 'Unknown Agent',
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isIncrease
                                      ? AppTheme.dangerColor.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isIncrease
                                          ? Icons.arrow_upward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 12,
                                      color: isIncrease
                                          ? AppTheme.dangerColor
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GHC ${request.amountDifference.abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: isIncrease
                                            ? AppTheme.dangerColor
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Original',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'GHC ${request.originalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.adminTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'GHC ${request.newAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.adminAccentRevenue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.message_outlined,
                                    size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    request.reason,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _handleApprove(context, ref, request.id);
                                  },
                                  icon: const Icon(Icons.check_circle_rounded,
                                      size: 18),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await _handleDecline(context, ref, request.id);
                                  },
                                  icon: const Icon(Icons.cancel_rounded,
                                      size: 18),
                                  label: const Text('Decline'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.dangerColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
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
                  child: CircularProgressIndicator(
                      color: AppTheme.adminPrimaryColor),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading requests',
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Approve Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to approve this price edit? The payment amount will be updated.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) return;

        final requestRepo = ref.read(paymentEditRequestRepositoryProvider);
        await requestRepo.approveRequest(requestId, currentUser.id);

        // Refresh the pending requests and dashboard stats
        ref.invalidate(pendingEditRequestsProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(dailyCollectionsProvider);
        ref.invalidate(allEditRequestsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request approved successfully',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDecline(BuildContext context, WidgetRef ref, String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Decline Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to decline this price edit? The original payment amount will remain unchanged.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) return;

        final requestRepo = ref.read(paymentEditRequestRepositoryProvider);
        await requestRepo.rejectRequest(requestId, currentUser.id);

        // Refresh the pending requests and dashboard stats
        ref.invalidate(pendingEditRequestsProvider);
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(dailyCollectionsProvider);
        ref.invalidate(allEditRequestsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request declined',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
