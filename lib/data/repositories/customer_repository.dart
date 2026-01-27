import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerRepository {
  final SupabaseClient _supabase;

  CustomerRepository(this._supabase);

  /// Create a new customer (product is optional - can be added later)
  Future<Customer> createCustomer({
    required String fullName,
    required String phone,
    required int zoneId,
    int? productId,
    required String assignedAgentId,
    double initialBalanceDue = 0,
    int totalBoxes = 0,
    required double registrationFeePaid,
  }) async {
    try {
      final data = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        'zone_id': zoneId,
        'assigned_agent_id': assignedAgentId,
        'balance_due': initialBalanceDue,
        'total_boxes_assigned': totalBoxes,
        'boxes_paid': 0,
        'registration_fee_paid': registrationFeePaid,
        'is_active': true,
      };
      
      // Only add product_id if provided
      if (productId != null) {
        data['product_id'] = productId;
      }

      final response = await _supabase
          .from('customers')
          .insert(data)
          .select()
          .single();

      return Customer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  /// Fetch all customers assigned to a specific agent
  Future<List<Customer>> fetchCustomersByAgent(String agentId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('''
            *,
            products(name),
            zones!inner(name)
          ''')
          .eq('assigned_agent_id', agentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) {
            final customer = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (customer['products'] != null) {
              customer['product_name'] = customer['products']['name'];
            }
            if (customer['zones'] != null) {
              customer['zone_name'] = customer['zones']['name'];
            }
            return Customer.fromJson(customer);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// Fetch all customers (admin view)
  Future<List<Customer>> fetchAllCustomers() async {
    try {
      final response = await _supabase
          .from('customers')
          .select('''
            *,
            products(name),
            zones(name),
            profiles!assigned_agent_id(full_name)
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) {
            final customer = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (customer['products'] != null) {
              customer['product_name'] = customer['products']['name'];
            }
            if (customer['zones'] != null) {
              customer['zone_name'] = customer['zones']['name'];
            }
            if (customer['profiles'] != null) {
              customer['agent_name'] = customer['profiles']['full_name'];
            }
            return Customer.fromJson(customer);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// Update a customer's assigned agent (transfer)
  Future<void> updateCustomerAgent(String customerId, String newAgentId) async {
    try {
      await _supabase
          .from('customers')
          .update({'assigned_agent_id': newAgentId})
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to transfer customer: $e');
    }
  }

  /// Update customer basic info
  Future<void> updateCustomer({
    required String customerId,
    String? fullName,
    String? phone,
    int? zoneId,
    String? assignedAgentId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (zoneId != null) updateData['zone_id'] = zoneId;
      if (assignedAgentId != null) updateData['assigned_agent_id'] = assignedAgentId;

      if (updateData.isEmpty) return;

      await _supabase
          .from('customers')
          .update(updateData)
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  /// Toggle customer active status
  Future<void> toggleCustomerActive(String customerId, bool isActive) async {
    try {
      await _supabase
          .from('customers')
          .update({'is_active': isActive})
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to update customer status: $e');
    }
  }

  /// Get a customer by ID with product details
  Future<Customer?> getCustomerById(String id) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('''
            *,
            products(name, box_rate),
            zones!inner(name)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final customer = Map<String, dynamic>.from(response as Map<String, dynamic>);
      if (customer['products'] != null) {
        customer['product_name'] = customer['products']['name'];
      }
      if (customer['zones'] != null) {
        customer['zone_name'] = customer['zones']['name'];
      }
      return Customer.fromJson(customer);
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }
}
