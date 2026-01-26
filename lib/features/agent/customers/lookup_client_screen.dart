import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/agent_providers.dart';
import '../../../providers/auth_provider.dart';
import 'add_product_dialog.dart';

class LookupClientScreen extends ConsumerStatefulWidget {
  const LookupClientScreen({super.key});

  @override
  ConsumerState<LookupClientScreen> createState() => _LookupClientScreenState();
}

class _LookupClientScreenState extends ConsumerState<LookupClientScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      ref.invalidate(assignedCustomersProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showCollectDialog(
    String customerId,
    String customerName,
    String productName,
    double balanceDue,
    double boxRate,
    int totalBoxes,
    int boxesPaid,
  ) {
    int boxesToCollect = 1;
    int boxesRemaining = totalBoxes - boxesPaid;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final totalToCollect = boxesToCollect * boxRate;

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collect Payment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Owing: $boxesRemaining',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.agentTextColor,
                  ),
                ),
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.agentPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.agentInputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDialogActionButton(
                        icon: Icons.remove_rounded,
                        onPressed: boxesToCollect > 1
                            ? () => setState(() => boxesToCollect--)
                            : null,
                      ),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          Text(
                            boxesToCollect.toString(),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.agentTextColor,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'BOXES',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      _buildDialogActionButton(
                        icon: Icons.add_rounded,
                        onPressed: boxesToCollect < boxesRemaining
                            ? () => setState(() => boxesToCollect++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL COLLECTION',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'GHC ${totalToCollect.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.agentPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              Column(
                children: [
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            try {
                              final paymentRepo = ref.read(paymentRepositoryProvider);
                              final customerRepo = ref.read(customerRepositoryProvider);
                              final currentUser = await ref.read(currentUserProvider.future);

                              if (currentUser == null) {
                                throw Exception('Not logged in');
                              }

                              // Verify customer is still active before collecting
                              final customer = await customerRepo.getCustomerById(customerId);
                              if (customer == null || !customer.isActive) {
                                throw Exception('Customer is inactive. Cannot collect payment.');
                              }

                              await paymentRepo.recordPayment(
                                customerId: customerId,
                                agentId: currentUser.id,
                                amount: totalToCollect,
                                productBoxRate: boxRate,
                              );

                              // Refresh data
                              ref.invalidate(assignedCustomersProvider);
                              ref.invalidate(agentPaymentsProvider);
                              ref.invalidate(agentStatsProvider);

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              if (this.context.mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Collected $boxesToCollect boxes (GHC ${totalToCollect.toStringAsFixed(2)})'),
                                    backgroundColor: AppTheme.agentPrimaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (this.context.mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppTheme.dangerColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.agentPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'CONFIRM COLLECTION',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogActionButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: onPressed == null ? Colors.grey.shade300 : AppTheme.agentPrimaryColor.withOpacity(0.1),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: onPressed == null ? Colors.grey : AppTheme.agentPrimaryColor,
        iconSize: 28,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  void _showAddProductDialog(dynamic customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddProductToCustomerDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(assignedCustomersProvider);

    return Scaffold(
      backgroundColor: AppTheme.agentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Customers',
          style: TextStyle(
            color: AppTheme.agentTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Lookup Client...',
                hintStyle: TextStyle(color: AppTheme.agentTextColor.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.agentPrimaryColor),
                filled: true,
                fillColor: AppTheme.agentInputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filteredCustomers = customers.where((customer) {
                  if (!customer.isActive) return false;
                  if (_searchQuery.isEmpty) return true;
                  final phone = customer.phone ?? '';
                  return customer.fullName.toLowerCase().contains(_searchQuery) ||
                         phone.contains(_searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No customers assigned yet' : 'No customers found',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    
                    return _buildCustomerCard(customer);
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
                      onPressed: () => ref.refresh(assignedCustomersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(dynamic customer) {
    final boxesRemaining = customer.totalBoxesAssigned - customer.boxesPaid;
    final customerProductsAsync = ref.watch(customerProductsProvider(customer.id));
    
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
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.agentPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.agentPrimaryColor),
          ),
          title: Text(
            customer.fullName,
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
                  Icon(Icons.phone_rounded, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    customer.phone ?? 'No phone',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildStatusBadge(boxesRemaining == 0),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showAddProductDialog(customer),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.agentAccentRegister.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, color: AppTheme.agentAccentRegister, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            'ADD',
                            style: TextStyle(
                              color: AppTheme.agentAccentRegister,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
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
          children: [
            // Show products from customer_products table
            customerProductsAsync.when(
              data: (customerProducts) {
                if (customerProducts.isEmpty) {
                  // Fall back to legacy single product display
                  return _buildProductRow(
                    productName: customer.productName ?? 'Unknown',
                    boxesAssigned: customer.totalBoxesAssigned,
                    boxesPaid: customer.boxesPaid,
                    boxRate: 0, // Will be fetched when collect is tapped
                    customerId: customer.id,
                    productId: customer.productId,
                    isLegacy: true,
                  );
                }
                
                // Show each product separately
                return Column(
                  children: customerProducts.map((cp) {
                    final cpBoxesRemaining = cp.boxesAssigned - cp.boxesPaid;
                    return _buildProductRow(
                      productName: cp.productName ?? 'Product ${cp.productId}',
                      boxesAssigned: cp.boxesAssigned,
                      boxesPaid: cp.boxesPaid,
                      boxRate: cp.pricePerBox ?? 0,
                      customerId: customer.id,
                      productId: cp.productId,
                      customerProductId: cp.id,
                      isLegacy: false,
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.agentPrimaryColor),
                  ),
                ),
              ),
              error: (_, __) => _buildProductRow(
                productName: customer.productName ?? 'Unknown',
                boxesAssigned: customer.totalBoxesAssigned,
                boxesPaid: customer.boxesPaid,
                boxRate: 0,
                customerId: customer.id,
                productId: customer.productId,
                isLegacy: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow({
    required String productName,
    required int boxesAssigned,
    required int boxesPaid,
    required double boxRate,
    required String customerId,
    required int productId,
    String? customerProductId,
    required bool isLegacy,
  }) {
    final boxesRemaining = boxesAssigned - boxesPaid;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.agentInputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.agentPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.agentPrimaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.agentTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owing: $boxesRemaining of $boxesAssigned boxes',
                  style: TextStyle(
                    color: boxesRemaining > 0 ? AppTheme.dangerColor : AppTheme.agentPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (boxesRemaining > 0)
            InkWell(
              onTap: () async {
                if (isLegacy) {
                  // Use legacy method for backwards compatibility
                  final productRepo = ref.read(productRepositoryProvider);
                  final product = await productRepo.getProductById(productId.toString());
                  if (product != null && mounted) {
                    _showCollectDialog(
                      customerId,
                      '', // Customer name not needed, dialog shows product
                      productName,
                      boxesRemaining * (product.boxRate),
                      product.boxRate,
                      boxesAssigned,
                      boxesPaid,
                    );
                  }
                } else {
                  // Use new customer_products method
                  _showCollectDialogForProduct(
                    customerId: customerId,
                    productName: productName,
                    boxRate: boxRate,
                    boxesAssigned: boxesAssigned,
                    boxesPaid: boxesPaid,
                    customerProductId: customerProductId!,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.agentPrimaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'COLLECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.agentPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'PAID',
                style: TextStyle(
                  color: AppTheme.agentPrimaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCollectDialogForProduct({
    required String customerId,
    required String productName,
    required double boxRate,
    required int boxesAssigned,
    required int boxesPaid,
    required String customerProductId,
  }) {
    int boxesToCollect = 1;
    int boxesRemaining = boxesAssigned - boxesPaid;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final totalToCollect = boxesToCollect * boxRate;

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Collect Payment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Owing: $boxesRemaining',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.agentTextColor,
                  ),
                ),
                Text(
                  'GHC ${boxRate.toStringAsFixed(2)} per box',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.agentPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.agentInputFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDialogActionButton(
                        icon: Icons.remove_rounded,
                        onPressed: boxesToCollect > 1
                            ? () => setState(() => boxesToCollect--)
                            : null,
                      ),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          Text(
                            boxesToCollect.toString(),
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.agentTextColor,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'BOXES',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      _buildDialogActionButton(
                        icon: Icons.add_rounded,
                        onPressed: boxesToCollect < boxesRemaining
                            ? () => setState(() => boxesToCollect++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL COLLECTION',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'GHC ${totalToCollect.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.agentPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.all(24),
            actions: [
              Column(
                children: [
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);

                            try {
                              final paymentRepo = ref.read(paymentRepositoryProvider);
                              final customerProductRepo = ref.read(customerProductRepositoryProvider);
                              final currentUser = await ref.read(currentUserProvider.future);

                              if (currentUser == null) {
                                throw Exception('Not logged in');
                              }

                              // Record payment
                              await paymentRepo.recordPayment(
                                customerId: customerId,
                                agentId: currentUser.id,
                                amount: totalToCollect,
                                productBoxRate: boxRate,
                              );

                              // Update customer_products table
                              await customerProductRepo.updateAfterPayment(
                                customerProductId: customerProductId,
                                amountPaid: totalToCollect,
                                boxesCollected: boxesToCollect,
                              );

                              // Refresh data
                              ref.invalidate(assignedCustomersProvider);
                              ref.invalidate(customerProductsProvider(customerId));
                              ref.invalidate(agentPaymentsProvider);
                              ref.invalidate(agentStatsProvider);

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              if (this.context.mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Collected $boxesToCollect boxes of $productName (GHC ${totalToCollect.toStringAsFixed(2)})'),
                                    backgroundColor: AppTheme.agentPrimaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (this.context.mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppTheme.dangerColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.agentPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'CONFIRM COLLECTION',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      foregroundColor: Colors.grey[600],
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? AppTheme.agentPrimaryColor.withOpacity(0.1) : AppTheme.agentAccentSync.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 14,
            color: isPaid ? AppTheme.agentPrimaryColor : AppTheme.agentAccentSync,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? 'PAID' : 'PENDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isPaid ? AppTheme.agentPrimaryColor : AppTheme.agentAccentSync,
            ),
          ),
        ],
      ),
    );
  }
}
