import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/responsive.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import '../../../data/models/product.dart';
import 'product_detail_screen.dart';

class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);
    final cyclesAsync = ref.watch(cyclesListProvider);
    final currentCycleAsync = ref.watch(currentAdminCycleProvider);

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Product Catalog',
              style: TextStyle(
                color: AppTheme.adminTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            currentCycleAsync.when(
              data: (cycle) => Text(
                cycle != null ? '${cycle.name}${cycle.isActive ? " (Active)" : ""}' : 'All Cycles',
                style: TextStyle(
                  fontSize: 12,
                  color: cycle?.isActive == true ? AppTheme.adminAccentRevenue : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          cyclesAsync.when(
            data: (cycles) {
              final currentCycle = currentCycleAsync.value;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.adminPrimaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.adminPrimaryColor.withOpacity(0.15)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: currentCycle?.id,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.adminPrimaryColor),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.adminPrimaryColor, fontSize: 13),
                    items: cycles.map((c) {
                      return DropdownMenuItem<int?>(
                        value: c.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.isActive ? Icons.play_circle_filled_rounded : Icons.history_rounded,
                              size: 16,
                              color: c.isActive ? AppTheme.adminAccentRevenue : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text('${c.name}${c.isActive ? ' (Active)' : ''}'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      ref.read(selectedCycleIdProvider.notifier).state = newId;
                      ref.invalidate(productsListProvider);
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          // Separate products by single and double
          final singleProducts = products.where((p) => p.isSingle).toList();
          final doubleProducts = products.where((p) => p.isDouble).toList();

          // Filter by search query
          List<Product> filterProducts(List<Product> list) {
            if (_searchQuery.isEmpty) return list;
            final query = _searchQuery.toLowerCase();
            return list.where((p) {
              final name = p.name.toLowerCase();
              final code = (p.code ?? '').toLowerCase();
              final rate = p.boxRate.toString();
              return name.contains(query) || code.contains(query) || rate.contains(query);
            }).toList();
          }

          final filteredSingle = filterProducts(singleProducts);
          final filteredDouble = filterProducts(doubleProducts);

          return ResponsiveWrapper(
            child: Column(
              children: [
                // Top Action & Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    children: [
                      // Add Product Button
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(
                          context,
                          ref,
                          initialType: _tabController.index == 1 ? 'double' : 'single',
                        ),
                        icon: const Icon(Icons.add_rounded, size: 22),
                        label: const Text(
                          'ADD NEW PRODUCT',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          backgroundColor: AppTheme.adminPrimaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminTextColor),
                          decoration: InputDecoration(
                            hintText: 'Search product name, code, or rate...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.adminPrimaryColor),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Bar: Single vs Double
                      Container(
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppTheme.adminPrimaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey.shade600,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Single Products (${singleProducts.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.layers_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Double Products (${doubleProducts.length})'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Single Products Tab
                      _buildProductGridOrList(filteredSingle, 'single'),

                      // Double Products Tab
                      _buildProductGridOrList(filteredDouble, 'double'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProductGridOrList(List<Product> list, String productType) {
    if (list.isEmpty) {
      final isDouble = productType == 'double';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDouble ? Icons.layers_outlined : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No $productType products match "$_searchQuery"'
                    : 'No $productType products in this cycle yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search terms.'
                    : 'Create a new $productType product for this cycle using the button above.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = Responsive.isDesktop(context);
    if (isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) => _buildProductCard(context, ref, list[index]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildProductCard(context, ref, list[index]),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product) {
    final customerCountsAsync = ref.watch(productCustomerCountsProvider);
    final customerCount = customerCountsAsync.when(
      data: (counts) => counts[product.id] ?? 0,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final isDouble = product.isDouble;

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
          boxShadow: AppTheme.cardShadow,
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDouble
                          ? Colors.purple.shade50
                          : AppTheme.adminPrimaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isDouble ? Icons.layers_rounded : Icons.inventory_2_rounded,
                      color: isDouble ? Colors.purple.shade700 : AppTheme.adminPrimaryColor,
                    ),
                  ),
                  // Customer count badge
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
                            product.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppTheme.adminTextColor,
                            ),
                          ),
                        ),
                        // Type Badge (Single / Double)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDouble ? Colors.purple.shade100 : Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDouble ? 'DOUBLE' : 'SINGLE',
                            style: TextStyle(
                              color: isDouble ? Colors.purple.shade800 : Colors.blueGrey.shade800,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, {String initialType = 'single'}) {
    String selectedType = initialType; // 'single' | 'double'
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final boxRateController = TextEditingController();
    final totalBoxesController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final isSingle = selectedType == 'single';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              'Add New Product',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Segmented Selector: Single vs Double
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.adminInputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = 'single'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSingle ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSingle ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'SINGLE PRODUCT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSingle ? AppTheme.adminPrimaryColor : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = 'double'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSingle ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isSingle ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'DOUBLE PRODUCT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: !isSingle ? Colors.purple.shade700 : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // If Double: show Name input
                  if (!isSingle) ...[
                    _buildDialogField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'e.g. Bronze Package',
                      icon: Icons.inventory_2_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product Code (Always shown for both)
                  _buildDialogField(
                    controller: codeController,
                    label: isSingle ? 'Product Code' : 'Product Code (Short Code)',
                    hint: isSingle ? 'e.g. CRZ 15 or B1' : 'e.g. BP-01',
                    icon: Icons.qr_code_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Box Rate
                  _buildDialogField(
                    controller: boxRateController,
                    label: 'Box Rate',
                    hint: '0.00',
                    icon: Icons.payments_rounded,
                    prefixText: 'GHC ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Total Boxes
                  _buildDialogField(
                    controller: totalBoxesController,
                    label: 'Total Boxes',
                    hint: '26',
                    icon: Icons.inventory_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
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
                        if (isLoading) return;
                        
                        final code = codeController.text.trim();
                        final name = isSingle ? code : nameController.text.trim();

                        if (code.isEmpty || (selectedType == 'double' && name.isEmpty) ||
                            boxRateController.text.isEmpty ||
                            totalBoxesController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
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
                          final currentCycle = await ref.read(currentAdminCycleProvider.future);
                          await productRepo.createProduct(
                            name: name,
                            code: code,
                            type: selectedType,
                            boxRate: boxRate,
                            totalBoxes: totalBoxes,
                            cycleId: currentCycle?.id,
                          );

                          ref.invalidate(productsListProvider);
                          if (context.mounted) Navigator.pop(dialogContext);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${selectedType.toUpperCase()} Product added successfully', 
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
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
          );
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) {
    String selectedType = product.type;
    final codeController = TextEditingController(text: product.code ?? product.name);
    final nameController = TextEditingController(text: product.name);
    final boxRateController = TextEditingController(text: product.boxRate.toStringAsFixed(0));
    final totalBoxesController = TextEditingController(text: product.totalBoxes.toString());
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final isSingle = selectedType == 'single';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Text(
              'Edit Product',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Segmented Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.adminInputFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = 'single'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSingle ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isSingle ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'SINGLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSingle ? AppTheme.adminPrimaryColor : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedType = 'double'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSingle ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isSingle ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                              ),
                              child: Center(
                                child: Text(
                                  'DOUBLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: !isSingle ? Colors.purple.shade700 : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isSingle) ...[
                    _buildDialogField(
                      controller: nameController,
                      label: 'Product Name',
                      hint: 'e.g. Bronze Package',
                      icon: Icons.inventory_2_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDialogField(
                    controller: codeController,
                    label: isSingle ? 'Product Code' : 'Product Code (Short Code)',
                    hint: isSingle ? 'e.g. CRZ 15' : 'e.g. BP-01',
                    icon: Icons.qr_code_rounded,
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
                        if (isLoading) return;
                        setState(() => isLoading = true);

                        final code = codeController.text.trim();
                        final name = isSingle ? code : nameController.text.trim();
                        final boxRate = double.tryParse(boxRateController.text);
                        final totalBoxes = int.tryParse(totalBoxesController.text);

                        if (boxRate == null || totalBoxes == null || code.isEmpty || name.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid fields')),
                            );
                          }
                          setState(() => isLoading = false);
                          return;
                        }

                        try {
                          final productRepo = ref.read(productRepositoryProvider);
                          await productRepo.updateProduct(
                            id: product.id.toString(),
                            name: name,
                            code: code,
                            type: selectedType,
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
          );
        },
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
                        if (isLoading) return;
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
