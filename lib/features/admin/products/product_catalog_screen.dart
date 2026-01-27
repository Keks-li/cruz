import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import 'product_detail_screen.dart';

class ProductCatalogScreen extends ConsumerWidget {
  const ProductCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Product Catalog',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddProductDialog(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'ADD NEW PRODUCT',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppTheme.adminPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            Text(
                              'No products in catalog yet',
                              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final customerCountsAsync = ref.watch(productCustomerCountsProvider);
                          final customerCount = customerCountsAsync.when(
                            data: (counts) => counts[product.id] ?? 0,
                            loading: () => 0,
                            error: (_, __) => 0,
                          );
                          
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
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
                                  Stack(
                                    children: [
                                      Container(
                                        height: 52,
                                        width: 52,
                                        decoration: BoxDecoration(
                                          color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.inventory_2_rounded, color: AppTheme.adminPrimaryColor),
                                      ),
                                      // Customer count badge (Point 5)
                                      if (customerCount > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.adminAccentRevenue,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '$customerCount',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                product.name,
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.adminTextColor),
                                              ),
                                            ),
                                            // Customer count text label
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.adminAccentRevenue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '$customerCount customers',
                                                style: const TextStyle(
                                                  color: AppTheme.adminAccentRevenue,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Box Rate: GHC ${product.boxRate.toStringAsFixed(0)} • ${product.totalBoxes} Boxes',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Total: GHC ${product.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800, 
                                            color: AppTheme.adminAccentRevenue,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add_box_rounded, color: AppTheme.adminAccentRevenue),
                                        onPressed: () => _showAddBoxesToProductDialog(context, ref, product),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: AppTheme.adminPrimaryColor),
                                        onPressed: () => _showEditProductDialog(context, ref, product),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final boxRateController = TextEditingController();
    final totalBoxesController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Add New Product',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameController,
                label: 'Product Name',
                hint: 'e.g. Bronze Package',
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: boxRateController,
                label: 'Box Rate',
                hint: '0.00',
                icon: Icons.payments_rounded,
                prefixText: 'GHC ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: totalBoxesController,
                label: 'Total Boxes',
                hint: '26',
                icon: Icons.inventory_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          boxRateController.text.isEmpty ||
                          totalBoxesController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      final boxRate = double.tryParse(boxRateController.text);
                      final totalBoxes = int.tryParse(totalBoxesController.text);

                      if (boxRate == null || totalBoxes == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid numbers')),
                          );
                        }
                        setState(() => isLoading = false);
                        return;
                      }

                      try {
                        final productRepo = ref.read(productRepositoryProvider);
                        await productRepo.createProduct(
                          name: nameController.text.trim(),
                          boxRate: boxRate,
                          totalBoxes: totalBoxes,
                        );

                        ref.invalidate(productsListProvider);
                        if (context.mounted) Navigator.pop(dialogContext);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product added successfully', style: TextStyle(fontWeight: FontWeight.w600)),
                              backgroundColor: AppTheme.adminAccentRevenue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppTheme.adminAccentAlert,
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
                backgroundColor: AppTheme.adminPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('ADD PRODUCT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, product) {
    final nameController = TextEditingController(text: product.name);
    final boxRateController = TextEditingController(text: product.boxRate.toString());
    final totalBoxesController = TextEditingController(text: product.totalBoxes.toString());
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Edit Product',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameController,
                label: 'Product Name',
                hint: 'e.g. Bronze Package',
                icon: Icons.inventory_2_rounded,
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: boxRateController,
                label: 'Box Rate',
                hint: '0.00',
                icon: Icons.payments_rounded,
                prefixText: 'GHC ',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: totalBoxesController,
                label: 'Total Boxes',
                hint: '26',
                icon: Icons.inventory_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      final boxRate = double.tryParse(boxRateController.text);
                      final totalBoxes = int.tryParse(totalBoxesController.text);

                      if (boxRate == null || totalBoxes == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter valid numbers')),
                          );
                        }
                        setState(() => isLoading = false);
                        return;
                      }

                      try {
                        final productRepo = ref.read(productRepositoryProvider);
                        await productRepo.updateProduct(
                          id: product.id.toString(),
                          name: nameController.text.trim(),
                          boxRate: boxRate,
                          totalBoxes: totalBoxes,
                        );

                        ref.invalidate(productsListProvider);
                        if (context.mounted) Navigator.pop(dialogContext);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product updated successfully', style: TextStyle(fontWeight: FontWeight.w600)),
                              backgroundColor: AppTheme.adminAccentRevenue,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppTheme.adminAccentAlert,
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
                backgroundColor: AppTheme.adminPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('UPDATE PRODUCT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBoxesToProductDialog(BuildContext context, WidgetRef ref, product) {
    final boxesController = TextEditingController();
    int extraBoxes = 0;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final additionalCost = extraBoxes * product.boxRate;
          final newTotalBoxes = product.totalBoxes + extraBoxes;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              'Add Extra Boxes',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: AppTheme.adminPrimaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Updating ${product.name}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.adminTextColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildDialogField(
                  controller: boxesController,
                  label: 'Extra Boxes to Add',
                  hint: '0',
                  icon: Icons.add_box_rounded,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() => extraBoxes = int.tryParse(value) ?? 0);
                  },
                ),
                if (extraBoxes > 0) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.adminAccentRevenue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.adminAccentRevenue.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NEW TOTAL', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            Text('$newTotalBoxes boxes', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('COST IMPACT', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                            Text('GHC ${additionalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminAccentRevenue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
              ElevatedButton(
                onPressed: extraBoxes > 0 && !isLoading
                    ? () async {
                        setState(() => isLoading = true);
                        try {
                          final productRepo = ref.read(productRepositoryProvider);
                          final result = await productRepo.addExtraBoxesToProduct(
                            productId: product.id.toString(),
                            extraBoxes: extraBoxes,
                          );
                          
                          final rawCount = result['affectedCustomers'];
                          final affectedCount = rawCount is int ? rawCount : int.tryParse(rawCount.toString()) ?? 0;
                          
                          ref.invalidate(productsListProvider);
                          Navigator.pop(dialogContext);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added $extraBoxes boxes. $affectedCount customer(s) affected.',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppTheme.adminAccentRevenue,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: AppTheme.adminAccentAlert,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminAccentRevenue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('ADD BOXES', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.adminTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade300),
            prefixText: prefixText,
            prefixIcon: Icon(icon, color: AppTheme.adminPrimaryColor, size: 18),
            filled: true,
            fillColor: AppTheme.adminInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
