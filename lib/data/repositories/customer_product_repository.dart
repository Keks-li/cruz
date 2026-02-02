import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_product.dart';

class CustomerProductRepository {
  final SupabaseClient _supabase;

  CustomerProductRepository(this._supabase);

  /// Fetch all products assigned to a customer with product details
  Future<List<CustomerProduct>> fetchProductsByCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_products')
          .select('''
            *,
            products!left(name, box_rate, total_price)
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) {
            final cp = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (cp['products'] != null) {
              cp['product_name'] = cp['products']['name'];
              cp['price_per_box'] = cp['products']['box_rate'];
              cp['total_price'] = cp['products']['total_price'];
            }
            return CustomerProduct.fromJson(cp);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customer products: $e');
    }
  }

  /// Add a new product to an existing customer
  Future<CustomerProduct> addProductToCustomer({
    required String customerId,
    required int productId,
    required int boxesAssigned,
    required double balanceDue,
    required double registrationFeePaid,
  }) async {
    try {
      final data = {
        'customer_id': customerId,
        'product_id': productId,
        'boxes_assigned': boxesAssigned,
        'boxes_paid': 0,
        'balance_due': balanceDue,
        'registration_fee_paid': registrationFeePaid,
        'is_active': true,
      };

      final response = await _supabase
          .from('customer_products')
          .insert(data)
          .select()
          .single();

      return CustomerProduct.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to add product to customer: $e');
    }
  }

  /// Toggle product active status for a customer (Point 4: Deactivate Products)
  Future<void> toggleProductActive(String customerProductId, bool isActive) async {
    try {
      await _supabase
          .from('customer_products')
          .update({'is_active': isActive})
          .eq('id', customerProductId);
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }

  /// Delete a customer product
  Future<void> deleteCustomerProduct(String customerProductId) async {
    try {
      await _supabase
          .from('customer_products')
          .delete()
          .eq('id', customerProductId);
    } catch (e) {
      throw Exception('Failed to delete customer product: $e');
    }
  }

  /// Get count of active customers for a product (Point 5: Product Dashboard badge)
  Future<int> getActiveCustomerCount(int productId) async {
    try {
      final response = await _supabase
          .from('customer_products')
          .select('id')
          .eq('product_id', productId)
          .eq('is_active', true);

      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get active customer count: $e');
    }
  }

  /// Get all active customer counts for all products (batch operation for Point 5)
  Future<Map<int, int>> getAllProductCustomerCounts() async {
    try {
      final response = await _supabase
          .from('customer_products')
          .select('product_id');

      final counts = <int, int>{};
      for (final row in response as List) {
        final rawProductId = row['product_id'];
        final productId = rawProductId is int ? rawProductId : int.tryParse(rawProductId.toString()) ?? 0;
        counts[productId] = (counts[productId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      throw Exception('Failed to get product customer counts: $e');
    }
  }

  /// Update customer product after payment
  Future<void> updateAfterPayment({
    required String customerProductId,
    required double amountPaid,
    required int boxesCollected,
  }) async {
    try {
      // Fetch current values
      final currentResponse = await _supabase
          .from('customer_products')
          .select('balance_due, boxes_paid')
          .eq('id', customerProductId)
          .single();

      final currentBalanceDue = (currentResponse['balance_due'] as num).toDouble();
      final rawBoxesPaid = currentResponse['boxes_paid'];
      final currentBoxesPaid = rawBoxesPaid is int ? rawBoxesPaid : int.tryParse(rawBoxesPaid.toString()) ?? 0;

      await _supabase
          .from('customer_products')
          .update({
            'balance_due': currentBalanceDue - amountPaid,
            'boxes_paid': currentBoxesPaid + boxesCollected,
          })
          .eq('id', customerProductId);
    } catch (e) {
      throw Exception('Failed to update customer product after payment: $e');
    }
  }

  /// Check if customer has a specific product
  Future<bool> customerHasProduct(String customerId, int productId) async {
    try {
      final response = await _supabase
          .from('customer_products')
          .select('id')
          .eq('customer_id', customerId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check customer product: $e');
    }
  }

  /// Fetch all products for customers assigned to a specific agent (includes all, even completed)
  Future<List<CustomerProduct>> fetchProductsByAgent(String agentId) async {
    try {
      final response = await _supabase
          .from('customer_products')
          .select('''
            *,
            customers!inner(assigned_agent_id)
          ''')
          .eq('customers.assigned_agent_id', agentId);

      return (response as List)
          .map((json) => CustomerProduct.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch agent products: $e');
    }
  }
}
