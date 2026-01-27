import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/agent_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/payment.dart';
import 'payment_edit_dialog.dart';

class CollectionLedgerScreen extends ConsumerStatefulWidget {
  const CollectionLedgerScreen({super.key});

  @override
  ConsumerState<CollectionLedgerScreen> createState() => _CollectionLedgerScreenState();
}

class _CollectionLedgerScreenState extends ConsumerState<CollectionLedgerScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh the provider every time this screen is opened
    // This uses a microtask to ensure it happens safely during init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(agentPaymentsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(agentPaymentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.agentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Collection Ledger',
          style: TextStyle(
            color: AppTheme.agentTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No collections recorded yet',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          // Group payments by customer (Point 7)
          final groupedPayments = _groupPaymentsByCustomer(payments);

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: groupedPayments.length,
            itemBuilder: (context, index) {
              final customerName = groupedPayments.keys.elementAt(index);
              final customerPayments = groupedPayments[customerName]!;
              
              return _buildCustomerPaymentCard(context, ref, customerName, customerPayments);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.agentPrimaryColor)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(agentPaymentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Group payments by customer name (Point 7)
  Map<String, List<Payment>> _groupPaymentsByCustomer(List<Payment> payments) {
    final grouped = <String, List<Payment>>{};
    for (final payment in payments) {
      final customerName = payment.customerName ?? 'Unknown Customer';
      if (!grouped.containsKey(customerName)) {
        grouped[customerName] = [];
      }
      grouped[customerName]!.add(payment);
    }
    return grouped;
  }

  /// Build expandable card for each customer showing their payment history (Point 7)
  Widget _buildCustomerPaymentCard(
    BuildContext context,
    WidgetRef ref,
    String customerName,
    List<Payment> payments,
  ) {
    // Calculate total for this customer
    final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    final totalBoxes = payments.fold<int>(0, (sum, p) => sum + (p.boxesEquivalent ?? 0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.agentPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded, 
              color: AppTheme.agentPrimaryColor,
              size: 24,
            ),
          ),
          title: Text(
            customerName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.agentTextColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.agentPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${payments.length} payments',
                      style: const TextStyle(
                        color: AppTheme.agentPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GHC ${totalAmount.toStringAsFixed(0)} • $totalBoxes Boxes',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: payments.map((payment) => _buildPaymentHistoryItem(context, ref, payment)).toList(),
        ),
      ),
    );
  }

  /// Individual payment item with Edit button (Point 8)
  Widget _buildPaymentHistoryItem(BuildContext context, WidgetRef ref, Payment payment) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.agentBackgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      payment.productName ?? 'Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.agentTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (payment.boxesEquivalent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.agentAccentSync.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${payment.boxesEquivalent} boxes',
                          style: const TextStyle(
                            color: AppTheme.agentAccentSync,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(payment.timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
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
              const SizedBox(height: 4),
              // Edit Button (Point 8)
              InkWell(
                onTap: () => _showEditDialog(context, ref, payment),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.agentAccentRegister.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 12, color: AppTheme.agentAccentRegister),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppTheme.agentAccentRegister,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show payment edit dialog (Point 8)
  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, Payment payment) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => PaymentEditDialog(payment: payment),
    );

    if (result != null && context.mounted) {
      try {
        final currentUser = await ref.read(currentUserProvider.future);
        if (currentUser == null) {
          throw Exception('Not logged in');
        }

        await ref.read(paymentRepositoryProvider).createPaymentEditRequest(
          paymentId: result['paymentId'],
          agentId: currentUser.id,
          originalAmount: result['originalAmount'],
          newAmount: result['newAmount'],
          reason: result['reason'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Edit request submitted successfully! Awaiting admin approval.'),
              backgroundColor: AppTheme.agentPrimaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
