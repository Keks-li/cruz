import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';
import '../models/customer.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository(this._supabase);

  /// Record a payment and update customer balance (TRANSACTION)
  /// This is the critical "Collect" feature logic
  Future<Payment> recordPayment({
    required String customerId,
    required String agentId,
    required double amount,
    required double productBoxRate,
    int? productId, // Nullable for legacy support
    DateTime? paymentDate, // Optional: allows agents to backdate a payment
    bool isApproved = true, // Default to true unless backdated
  }) async {
    try {
      // Calculate boxes collected
      final boxesCollected = (amount / productBoxRate).floor();

      // Insert the payment record WITH boxes_equivalent
      // If paymentDate is supplied, override the DB-default timestamp
      final paymentData = {
        'customer_id': customerId,
        'agent_id': agentId,
        'amount_paid': amount,
        'boxes_equivalent': boxesCollected,
        'is_approved': isApproved,
        if (productId != null) 'product_id': productId,
        if (paymentDate != null) 'timestamp': paymentDate.toIso8601String(),
      };

      final paymentResponse = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      // Only update balance if payment is approved (or wait for admin approval if false)
      if (isApproved) {
        // Update customer balance and boxes_paid
        final customerResponse = await _supabase
            .from('customers')
            .select('balance_due, boxes_paid')
            .eq('id', customerId)
            .single();

        final currentBalanceDue = (customerResponse['balance_due'] as num).toDouble();
        final rawBoxesPaid = customerResponse['boxes_paid'];
        final currentBoxesPaid = rawBoxesPaid is int ? rawBoxesPaid : int.tryParse(rawBoxesPaid.toString()) ?? 0;

        final newBalanceDue = currentBalanceDue - amount;
        final newBoxesPaid = currentBoxesPaid + boxesCollected;

        await _supabase
            .from('customers')
            .update({
              'balance_due': newBalanceDue,
              'boxes_paid': newBoxesPaid,
            })
            .eq('id', customerId);
      }

      return Payment.fromJson(paymentResponse as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to record payment: $e');
    }
  }

  /// Fetch pending unapproved payments (e.g. backdated ones needing admin approval)
  Future<List<Payment>> fetchPendingApprovals() async {
    try {
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            products!left(name),
            profiles!agent_id(full_name),
            customers!left(full_name, products!left(name))
          ''')
          .eq('is_approved', false)
          .order('timestamp', ascending: false);

      return (response as List).map((json) {
        final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
        if (payment['customers'] != null) {
          payment['customer_name'] = payment['customers']['full_name'];
          if (payment['products'] != null) {
            payment['product_name'] = payment['products']['name'];
          } else if (payment['customers']['products'] != null) {
            payment['product_name'] = payment['customers']['products']['name'];
          }
        }
        if (payment['profiles'] != null) {
          payment['agent_name'] = payment['profiles']['full_name'];
        }
        return Payment.fromJson(payment);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending approvals: $e');
    }
  }

  /// Approve a pending backdated payment, updating customer balances accordingly
  Future<void> approvePayment(String paymentId) async {
    try {
      // Fetch the unapproved payment details
      final paymentResponse = await _supabase
          .from('payments')
          .select('customer_id, product_id, amount_paid, boxes_equivalent')
          .eq('id', paymentId)
          .single();

      final customerId = paymentResponse['customer_id'] as String;
      final productId = paymentResponse['product_id'];
      final amountPaid = (paymentResponse['amount_paid'] as num).toDouble();
      final boxesCollected = (paymentResponse['boxes_equivalent'] as num?)?.toInt() ?? 0;

      // Mark the payment as approved
      await _supabase
          .from('payments')
          .update({'is_approved': true})
          .eq('id', paymentId);

      // Now apply the effect on customer balances
      final customerResponse = await _supabase
          .from('customers')
          .select('balance_due, boxes_paid')
          .eq('id', customerId)
          .single();

      final currentBalanceDue = (customerResponse['balance_due'] as num).toDouble();
      final rawBoxesPaid = customerResponse['boxes_paid'];
      final currentBoxesPaid = rawBoxesPaid is int ? rawBoxesPaid : int.tryParse(rawBoxesPaid.toString()) ?? 0;

      final newBalanceDue = currentBalanceDue - amountPaid;
      final newBoxesPaid = currentBoxesPaid + boxesCollected;

      await _supabase
          .from('customers')
          .update({
            'balance_due': newBalanceDue,
            'boxes_paid': newBoxesPaid,
          })
          .eq('id', customerId);

      // Also update the specific customer_product record if this payment was linked to one
      if (productId != null) {
        final cpResponse = await _supabase
            .from('customer_products')
            .select('id, balance_due, boxes_paid')
            .eq('customer_id', customerId)
            .eq('product_id', productId)
            .maybeSingle();

        if (cpResponse != null) {
          final cpId = cpResponse['id'] as String;
          final cpBalanceDue = (cpResponse['balance_due'] as num).toDouble();
          final cpRawBoxesPaid = cpResponse['boxes_paid'];
          final cpBoxesPaid = cpRawBoxesPaid is int ? cpRawBoxesPaid : int.tryParse(cpRawBoxesPaid.toString()) ?? 0;

          await _supabase
              .from('customer_products')
              .update({
                'balance_due': cpBalanceDue - amountPaid,
                'boxes_paid': cpBoxesPaid + boxesCollected,
              })
              .eq('id', cpId);
        }
      }

    } catch (e) {
      throw Exception('Failed to approve payment: $e');
    }
  }

  /// Fetch all payments for a specific agent
  Future<List<Payment>> fetchPaymentsByAgent(String agentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            products!left(name),
            customers!left(full_name, products!left(name))
          ''')
          .eq('agent_id', agentId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) {
            final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (payment['customers'] != null) {
              payment['customer_name'] = payment['customers']['full_name'];
              
              // Fallback logic: prefer direct product link, else legacy customer product
              if (payment['products'] != null) {
                payment['product_name'] = payment['products']['name'];
              } else if (payment['customers']['products'] != null) {
                payment['product_name'] = payment['customers']['products']['name'];
              }
            }
            return Payment.fromJson(payment);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  /// Fetch total system revenue (sum of all payments)
  Future<double> fetchTotalRevenue() async {
    try {
      final response = await _supabase
          .from('payments')
          .select('amount_paid')
          .eq('is_approved', true);

      if (response is List && response.isEmpty) {
        return 0.0;
      }

      final total = (response as List)
          .map((json) => double.tryParse(json['amount_paid'].toString()) ?? 0.0)
          .reduce((a, b) => a + b);

      return total;
    } catch (e) {
      throw Exception('Failed to fetch total revenue: $e');
    }
  }

  /// Fetch total revenue for a specific agent
  Future<double> fetchAgentLifetimeCollection(String agentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('amount_paid')
          .eq('agent_id', agentId)
          .eq('is_approved', true);

      if (response is List && response.isEmpty) {
        return 0.0;
      }

      final total = (response as List)
          .map((json) => double.tryParse(json['amount_paid'].toString()) ?? 0.0)
          .fold<double>(0.0, (sum, amount) => sum + amount);

      return total;
    } catch (e) {
      throw Exception('Failed to fetch agent collection: $e');
    }
  }

  /// Fetch total boxes collected by an agent
  Future<double> fetchAgentTotalBoxesCollected(String agentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('boxes_equivalent')
          .eq('agent_id', agentId)
          .eq('is_approved', true);

      if (response is List && response.isEmpty) {
        return 0.0;
      }

      final total = (response as List)
          .where((json) => json['boxes_equivalent'] != null)
          .map((json) => double.tryParse(json['boxes_equivalent'].toString()) ?? 0.0)
          .fold<double>(0.0, (sum, boxes) => sum + boxes);

      return total;
    } catch (e) {
      throw Exception('Failed to fetch agent boxes: $e');
    }
  }

  /// Fetch payments by specific date
  Future<List<Payment>> fetchPaymentsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('payments')
          .select('''
            *,
            products!left(name),
            customers!left(full_name, products!left(name)),
            profiles!agent_id(full_name)
          ''')
          .gte('timestamp', startOfDay.toIso8601String())
          .lte('timestamp', endOfDay.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) {
            final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (payment['customers'] != null) {
              payment['customer_name'] = payment['customers']['full_name'];
              
              if (payment['products'] != null) {
                payment['product_name'] = payment['products']['name'];
              } else if (payment['customers']['products'] != null) {
                payment['product_name'] = payment['customers']['products']['name'];
              }
            }
            if (payment['profiles'] != null) {
              payment['agent_name'] = payment['profiles']['full_name'];
            }
            return Payment.fromJson(payment);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch daily payments: $e');
    }
  }

  /// Fetch payments by customer ID
  Future<List<Payment>> fetchPaymentsByCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('''
            *,
            products!left(name),
            profiles!agent_id(full_name),
            customers!left(products!left(name))
          ''')
          .eq('customer_id', customerId)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) {
            final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (payment['profiles'] != null) {
              payment['agent_name'] = payment['profiles']['full_name'];
            }
            
            if (payment['products'] != null) {
              payment['product_name'] = payment['products']['name'];
            } else if (payment['customers'] != null && payment['customers']['products'] != null) {
              payment['product_name'] = payment['customers']['products']['name'];
            }
            return Payment.fromJson(payment);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customer payments: $e');
    }
  }

  /// Fetch agent's total collection for a specific date (Point 6)
  Future<double> fetchAgentDailyCollection(String agentId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('payments')
          .select('amount_paid')
          .eq('agent_id', agentId)
          .eq('is_approved', true)
          .gte('timestamp', startOfDay.toIso8601String())
          .lte('timestamp', endOfDay.toIso8601String());

      if (response is List && response.isEmpty) {
        return 0.0;
      }

      final total = (response as List)
          .map((json) => double.tryParse(json['amount_paid'].toString()) ?? 0.0)
          .fold<double>(0.0, (sum, amount) => sum + amount);

      return total;
    } catch (e) {
      throw Exception('Failed to fetch agent daily collection: $e');
    }
  }

  /// Fetch agent's payments for a specific date with product details (Point 6)
  Future<List<Payment>> fetchAgentDailyPayments(String agentId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final response = await _supabase
          .from('payments')
          .select('''
            *,
            products!left(name),
            customers!left(full_name, products!left(name))
          ''')
          .eq('agent_id', agentId)
          .gte('timestamp', startOfDay.toIso8601String())
          .lte('timestamp', endOfDay.toIso8601String())
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) {
            final payment = Map<String, dynamic>.from(json as Map<String, dynamic>);
            if (payment['customers'] != null) {
              payment['customer_name'] = payment['customers']['full_name'];
              if (payment['products'] != null) {
                payment['product_name'] = payment['products']['name'];
              } else if (payment['customers']['products'] != null) {
                payment['product_name'] = payment['customers']['products']['name'];
              }
            }
            return Payment.fromJson(payment);
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch agent daily payments: $e');
    }
  }

  /// Create a payment edit request (Point 8)
  Future<void> createPaymentEditRequest({
    required String paymentId,
    required String agentId,
    required double originalAmount,
    required double newAmount,
    required String reason,
  }) async {
    try {
      await _supabase.from('payment_edit_requests').insert({
        'payment_id': paymentId,
        'agent_id': agentId,
        'original_amount': originalAmount,
        'new_amount': newAmount,
        'reason': reason,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to create payment edit request: $e');
    }
  }
}
