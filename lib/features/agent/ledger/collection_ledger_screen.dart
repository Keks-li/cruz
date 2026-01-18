import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/agent_providers.dart';

class CollectionLedgerScreen extends ConsumerWidget {
  const CollectionLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.agentPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded, 
                          color: AppTheme.agentPrimaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.customerName ?? 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.agentTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${payment.productName ?? 'Product'} • ${_formatDate(payment.timestamp)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
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
                            'GHC${payment.amountPaid.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.agentPrimaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (payment.boxesEquivalent != null)
                            Text(
                              '${payment.boxesEquivalent} Boxes',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.agentPrimaryColor)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.dangerColor),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
