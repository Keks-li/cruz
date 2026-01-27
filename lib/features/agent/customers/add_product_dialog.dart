import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/agent_providers.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';

/// Dialog for agents to add another product to an existing customer
class AddProductToCustomerDialog extends ConsumerStatefulWidget {
  final Customer customer;

  const AddProductToCustomerDialog({super.key, required this.customer});

  @override
  ConsumerState<AddProductToCustomerDialog> createState() => _AddProductToCustomerDialogState();
}

class _AddProductToCustomerDialogState extends ConsumerState<AddProductToCustomerDialog> {
  int? _selectedProductId;
  bool _isLoading = false;
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(agentProductsProvider);
    final customerProductsAsync = ref.watch(customerProductsProvider(widget.customer.id));
    final settingsAsync = ref.watch(settingsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Product To Customer',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentTextColor),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.agentPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.customer.fullName,
              style: const TextStyle(
                color: AppTheme.agentPrimaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT PRODUCT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          customerProductsAsync.when(
            data: (customerProducts) {
              // Get list of product IDs already assigned to this customer
              final assignedProductIds = customerProducts.map((cp) => cp.productId).toSet();
              
              return productsAsync.when(
                data: (products) {
                  // Filter out products customer already has
                  final availableProducts = products.where((p) => 
                    !assignedProductIds.contains(p.id)
                  ).toList();

              if (availableProducts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.agentInputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No additional products available',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.agentInputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedProductId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.inventory_2_rounded, color: AppTheme.agentPrimaryColor, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.agentInputFill,
                  ),
                  hint: const Text('Select product'),
                  items: availableProducts.map((product) {
                    return DropdownMenuItem(
                      value: product.id,
                      child: Text(
                        '${product.name} - GHC ${product.boxRate.toStringAsFixed(2)}/box',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductId = value;
                      _selectedProduct = availableProducts.firstWhere((p) => p.id == value);
                    });
                  },
                ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error loading products: $error'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Error loading customer products: $error'),
        ),
          if (_selectedProduct != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.agentPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.agentPrimaryColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PRODUCT',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      Text(
                        _selectedProduct!.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BOXES',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      Text(
                        '${_selectedProduct!.totalBoxes}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL VALUE',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
                      Text(
                        'GHC ${_selectedProduct!.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentPrimaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  settingsAsync.when(
                    data: (settings) {
                      final regFee = settings.registrationFee;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'REGISTRATION FEE',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                          Text(
                            'GHC ${regFee.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentAccentRegister),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedProductId != null && !_isLoading ? _addProduct : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.agentPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('ADD PRODUCT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ],
    );
  }

  Future<void> _addProduct() async {
    if (_selectedProductId == null || _selectedProduct == null) return;

    setState(() => _isLoading = true);

    try {
      final customerProductRepo = ref.read(customerProductRepositoryProvider);
      final settingsAsync = await ref.read(settingsProvider.future);
      final regFee = settingsAsync.registrationFee;

      // Check if customer already has this product
      final hasProduct = await customerProductRepo.customerHasProduct(
        widget.customer.id,
        _selectedProductId!,
      );

      if (hasProduct) {
        throw Exception('Customer already has this product');
      }

      await customerProductRepo.addProductToCustomer(
        customerId: widget.customer.id,
        productId: _selectedProductId!,
        boxesAssigned: _selectedProduct!.totalBoxes,
        balanceDue: _selectedProduct!.totalPrice,
        registrationFeePaid: regFee,
      );

      // Refresh customer data and customer products
      ref.invalidate(assignedCustomersProvider);
      ref.invalidate(customerProductsProvider(widget.customer.id));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedProduct!.name} added to ${widget.customer.fullName}'),
            backgroundColor: AppTheme.agentPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
