import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductRepository {
  final SupabaseClient _supabase;

  ProductRepository(this._supabase);

  /// Fetch all products (reads totalPrice from DB)
  Future<List<Product>> fetchProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Create a new product (DOES NOT send totalPrice - it's auto-calculated)
  Future<Product> createProduct({
    required String name,
    required double boxRate,
    required int totalBoxes,
  }) async {
    try {
      final data = {
        'name': name,
        'box_rate': boxRate,
        'total_boxes': totalBoxes,
        // DO NOT include total_price - database calculates it
      };

      final response = await _supabase
          .from('products')
          .insert(data)
          .select()
          .single();

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update an existing product
  Future<Product> updateProduct({
    required String id,
    String? name,
    double? boxRate,
    int? totalBoxes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (boxRate != null) data['box_rate'] = boxRate;
      if (totalBoxes != null) data['total_boxes'] = totalBoxes;
      // DO NOT include total_price - database calculates it

      final response = await _supabase
          .from('products')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Get a single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Add extra boxes to a product and update all customers with incomplete payments
  Future<Map<String, dynamic>> addExtraBoxesToProduct({
    required String productId,
    required int extraBoxes,
  }) async {
    try {
      // 1. Get the product to get its box_rate and current total_boxes
      final product = await getProductById(productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      final boxRate = product.boxRate;
      final additionalCost = extraBoxes * boxRate;
      
      // 2. Update the product's total_boxes
      final newTotalBoxes = product.totalBoxes + extraBoxes;
      await _supabase
          .from('products')
          .update({'total_boxes': newTotalBoxes})
          .eq('id', productId);
      
      // 3. Find all customers with this product who have incomplete payments
      final customersResponse = await _supabase
          .from('customers')
          .select('id, total_boxes_assigned, balance_due, full_name')
          .eq('product_id', int.parse(productId))
          .gt('balance_due', 0); // Only customers with outstanding balance
      
      final customers = customersResponse as List;
      int affectedCount = 0;
      
      // 4. Update each customer
      for (final customerData in customers) {
        final customerId = customerData['id'] as String;
        final rawTotalBoxes = customerData['total_boxes_assigned'];
        final currentTotalBoxes = rawTotalBoxes is int ? rawTotalBoxes : int.tryParse(rawTotalBoxes.toString()) ?? 0;
        final currentBalanceDue = (customerData['balance_due'] as num).toDouble();
        
        await _supabase
            .from('customers')
            .update({
              'total_boxes_assigned': currentTotalBoxes + extraBoxes,
              'balance_due': currentBalanceDue + additionalCost,
            })
            .eq('id', customerId);
        
        affectedCount++;
      }
      
      return {
        'affectedCustomers': affectedCount,
        'extraBoxes': extraBoxes,
        'additionalCost': additionalCost,
      };
    } catch (e) {
      throw Exception('Failed to add extra boxes to product: $e');
    }
  }
}
