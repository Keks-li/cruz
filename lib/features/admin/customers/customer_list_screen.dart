import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/customer_product.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Customers',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.adminTextColor),
                decoration: InputDecoration(
                  hintText: 'Search Name or Phone...',
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
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.adminPrimaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                final filteredCustomers = customers.where((customer) {
                  if (_searchQuery.isEmpty) return true;
                  final phone = customer.phone ?? '';
                  return customer.fullName.toLowerCase().contains(_searchQuery) ||
                         phone.contains(_searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: filteredCustomers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          customer.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.adminTextColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              customer.phone ?? 'No phone',
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: customer.agentName != null 
                                ? AppTheme.adminPrimaryColor.withOpacity(0.05) 
                                : AppTheme.adminAccentAlert.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (customer.agentName ?? 'Unassigned').toUpperCase(),
                            style: TextStyle(
                              color: customer.agentName != null ? AppTheme.adminPrimaryColor : AppTheme.adminAccentAlert,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerProfileScreen(customerId: customer.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load customers',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(allCustomersProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminPrimaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
}

// ============ CUSTOMER PROFILE SCREEN ============
class CustomerProfileScreen extends ConsumerStatefulWidget {
  final String customerId;
  
  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Customer?>(
      future: ref.read(customerRepositoryProvider).getCustomerById(widget.customerId),
      builder: (context, customerSnapshot) {
        if (!customerSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final customer = customerSnapshot.data!;

        return FutureBuilder(
          future: Future.wait([
            (customer.productId != '0' && customer.productId != 'null') 
                ? ref.read(productRepositoryProvider).getProductById(customer.productId)
                : Future.value(null),
            ref.read(paymentRepositoryProvider).fetchPaymentsByCustomer(widget.customerId),
            ref.read(customerProductRepositoryProvider).fetchProductsByCustomer(widget.customerId),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')), 
                body: Center(child: Text('Error: ${snapshot.error}'))
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final product = snapshot.data![0];
            final allPayments = snapshot.data![1] as List<Payment>;
            final customerProducts = snapshot.data![2] as List<CustomerProduct>;
            
            // Filter payments by date range
            final payments = _startDate != null && _endDate != null
                ? allPayments.where((payment) {
                    return payment.timestamp.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                           payment.timestamp.isBefore(_endDate!.add(const Duration(days: 1)));
                  }).toList()
                : allPayments;
            
            final boxesLeft = customer.totalBoxesAssigned - customer.boxesPaid;

            return Scaffold(
              backgroundColor: AppTheme.adminBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.adminTextColor),
                ),
                title: const Text(
                  'Customer Profile',
                  style: TextStyle(
                    color: AppTheme.adminTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.cardShadow,
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.fullName,
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.adminTextColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      customer.phone ?? 'No phone',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: customer.isActive ? AppTheme.adminAccentRevenue.withOpacity(0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  customer.isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: TextStyle(
                                    color: customer.isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade600,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showEditDialog(customer),
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  label: const Text('EDIT PROFILE'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.adminPrimaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _toggleActive(customer),
                                  icon: Icon(customer.isActive ? Icons.block_flipped : Icons.check_circle_rounded, size: 18),
                                  label: Text(customer.isActive ? 'DEACTIVATE' : 'ACTIVATE'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: customer.isActive ? AppTheme.adminAccentAlert : AppTheme.adminAccentRevenue,
                                    side: BorderSide(color: customer.isActive ? AppTheme.adminAccentAlert.withOpacity(0.3) : AppTheme.adminAccentRevenue.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildInfoTile('ASSIGNED AGENT', customer.agentName ?? 'Unassigned', Icons.person_pin_rounded, onAction: () => _showTransferDialog(customer), actionLabel: 'Transfer'),
                        const SizedBox(width: 16),
                        _buildInfoTile('ZONE LOCATION', customer.zoneName ?? 'N/A', Icons.location_on_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Products Section
                    const Text(
                      'ASSIGNED PRODUCTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder(
                      future: ref.read(customerProductRepositoryProvider).fetchProductsByCustomer(widget.customerId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final customerProducts = snapshot.data!;

                        if (customerProducts.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No products assigned',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: customerProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final cp = customerProducts[index];
                            final isActive = cp.isActive;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive ? Colors.grey.shade200 : AppTheme.dangerColor.withOpacity(0.3),
                                ),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isActive 
                                          ? AppTheme.adminAccentRevenue.withOpacity(0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      color: isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cp.productName ?? 'Unknown Product',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isActive ? AppTheme.adminTextColor : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '${cp.boxesPaid}/${cp.boxesAssigned} boxes',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive 
                                                    ? AppTheme.adminAccentRevenue.withOpacity(0.1)
                                                    : AppTheme.dangerColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isActive ? 'ACTIVE' : 'TERMINATED',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: isActive ? AppTheme.adminAccentRevenue : AppTheme.dangerColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    onChanged: (value) async {
                                      try {
                                        await ref.read(customerProductRepositoryProvider).toggleProductActive(cp.id, value);
                                        
                                        // Refresh the screen
                                        setState(() {});
                                        
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Product ${value ? "activated" : "deactivated"}',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              backgroundColor: value ? AppTheme.adminAccentRevenue : AppTheme.dangerColor,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: AppTheme.dangerColor,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    activeColor: AppTheme.adminAccentRevenue,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'PORTFOLIO STATUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show all products from customer_products table
                    if (customerProducts.isNotEmpty)
                      ...customerProducts.map((cp) {
                        final cpBoxesLeft = cp.boxesAssigned - cp.boxesPaid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.cardShadow,
                            border: Border.all(color: cp.isActive ? Colors.grey.shade100 : AppTheme.dangerColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            cp.productName ?? 'Product ${cp.productId}',
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cp.isActive ? AppTheme.adminTextColor : Colors.grey),
                                          ),
                                          if (!cp.isActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.dangerColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'TERMINATED',
                                                style: TextStyle(
                                                  color: AppTheme.dangerColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'GHC ${cp.pricePerBox?.toStringAsFixed(0) ?? '0'} / box • ${cp.boxesAssigned} Boxes',
                                        style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'GHC ${cp.totalPrice?.toStringAsFixed(0) ?? '0'}',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.adminTextColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'OUTSTANDING',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'GHC ${cp.balanceDue.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.adminAccentAlert),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.adminAccentAlert.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$cpBoxesLeft BOXES LEFT',
                                      style: const TextStyle(color: AppTheme.adminAccentAlert, fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: cp.boxesAssigned > 0 ? (cp.boxesPaid / cp.boxesAssigned) : 0,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.adminAccentRevenue),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()
                    else
                      // Fallback to legacy single product display
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product?.name ?? 'Unknown',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.adminTextColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'GHC ${product?.boxRate.toStringAsFixed(0)} / box • ${customer.totalBoxesAssigned} Boxes',
                                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'GHC ${product?.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.adminTextColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OUTSTANDING',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'GHC ${customer.balanceDue.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.adminAccentAlert),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.adminAccentAlert.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$boxesLeft BOXES LEFT',
                                    style: const TextStyle(color: AppTheme.adminAccentAlert, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: customer.totalBoxesAssigned > 0 ? (customer.boxesPaid / customer.totalBoxesAssigned) : 0,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.adminAccentRevenue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PAYMENT HISTORY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => _selectDateRange(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.adminPrimaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  _startDate != null && _endDate != null
                                      ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                      : 'Filter',
                                  style: const TextStyle(color: AppTheme.adminPrimaryColor, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    payments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade200),
                                  const SizedBox(height: 12),
                                  Text('No payments found', style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 16, bottom: 40),
                            itemCount: payments.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final payment = payments[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
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
                                      child: const Icon(Icons.check_rounded, color: AppTheme.adminAccentRevenue),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            payment.timestamp.toString().substring(0, 16),
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            payment.agentName ?? 'Unknown Agent',
                                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.adminTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '+GHC ${payment.amountPaid.toStringAsFixed(0)}',
                                          style: const TextStyle(color: AppTheme.adminAccentRevenue, fontWeight: FontWeight.w900, fontSize: 16),
                                        ),
                                        Text(
                                          '${payment.boxesEquivalent ?? 0} BOXES',
                                          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {VoidCallback? onAction, String? actionLabel}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.adminTextColor)),
            if (onAction != null) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: onAction,
                child: Text(actionLabel ?? 'Edit', style: const TextStyle(color: AppTheme.adminPrimaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Customer customer) {
    final nameController = TextEditingController(text: customer.fullName);
    final phoneController = TextEditingController(text: customer.phone);
    int? selectedZoneId = customer.zoneId;
    String? selectedAgentId = customer.assignedAgentId; // Pre-select current agent

    final zonesAsync = ref.read(zonesListProvider);
    final agentsAsync = ref.read(agentsListProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 16),
                zonesAsync.when(
                  data: (zones) => DropdownButtonFormField<int>(
                    value: selectedZoneId,
                    decoration: const InputDecoration(labelText: 'Zone'),
                    items: zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone.id,
                        child: Text(zone.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedZoneId = value);
                    },
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error loading zones: $error'),
                ),
                const SizedBox(height: 16),
                agentsAsync.when(
                  data: (agents) {
                    final activeAgents = agents.where((a) => a.isActive).toList();
                    return DropdownButtonFormField<String>(
                      value: selectedAgentId,
                      decoration: const InputDecoration(labelText: 'Assigned Agent'),
                      items: activeAgents.map((agent) {
                        return DropdownMenuItem(
                          value: agent.id,
                          child: Text(agent.fullName ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedAgentId = value);
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error loading agents: $error'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(customerRepositoryProvider).updateCustomer(
                    customerId: customer.id,
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    zoneId: selectedZoneId,
                    assignedAgentId: selectedAgentId,
                  );
                  
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  
                  // Refresh the screen
                  if (this.context.mounted) {
                    this.setState(() {});
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer updated successfully'),
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (this.context.mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: AppTheme.dangerColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActive(Customer customer) async {
    try {
      await ref.read(customerRepositoryProvider).toggleCustomerActive(customer.id, !customer.isActive);
      
      // Refresh providers
      ref.invalidate(allCustomersProvider);
      
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer ${customer.isActive ? 'deactivated' : 'activated'}'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showTransferDialog(Customer customer) {
    final agentsAsync = ref.read(agentsListProvider);
    String? selectedAgentId = customer.assignedAgentId; // Pre-select current agent

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Transfer Customer'),
          content: agentsAsync.when(
            data: (agents) {
              final activeAgents = agents.where((a) => a.isActive).toList();
              
              if (activeAgents.isEmpty) {
                return const Text('No active agents available');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Transfer ${customer.fullName} to:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedAgentId,
                    decoration: const InputDecoration(labelText: 'Select Agent'),
                    items: activeAgents.map((agent) {
                      return DropdownMenuItem(
                        value: agent.id,
                        child: Text(agent.fullName ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedAgentId = value);
                    },
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedAgentId == null || selectedAgentId == customer.assignedAgentId
                  ? null
                  : () async {
                      try {
                        await ref.read(customerRepositoryProvider).updateCustomerAgent(
                          customer.id,
                          selectedAgentId!,
                        );
                        
                        // Refresh providers
                        ref.invalidate(allCustomersProvider);
                        
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (this.context.mounted) {
                          this.setState(() {});
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer transferred successfully'),
                              backgroundColor: AppTheme.secondaryColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (this.context.mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppTheme.dangerColor,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
