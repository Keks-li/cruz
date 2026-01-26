import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_edit_request.dart';

class PaymentEditRequestRepository {
  final SupabaseClient _supabase;

  PaymentEditRequestRepository(this._supabase);

  /// Fetch all pending payment edit requests (for admin)
  Future<List<PaymentEditRequest>> fetchPendingRequests() async {
    try {
      final response = await _supabase
          .from('payment_edit_requests')
          .select('''
            *,
            profiles!agent_id(full_name),
            payments!payment_id(
              customers!customer_id(full_name)
            )
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final request = Map<String, dynamic>.from(json as Map<String, dynamic>);
        if (request['profiles'] != null) {
          request['agent_name'] = request['profiles']['full_name'];
        }
        if (request['payments'] != null && request['payments']['customers'] != null) {
          request['customer_name'] = request['payments']['customers']['full_name'];
        }
        return PaymentEditRequest.fromJson(request);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  /// Fetch all payment edit requests (for history)
  Future<List<PaymentEditRequest>> fetchAllRequests() async {
    try {
      final response = await _supabase
          .from('payment_edit_requests')
          .select('''
            *,
            profiles!agent_id(full_name),
            payments!payment_id(
              customers!customer_id(full_name)
            )
          ''')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final request = Map<String, dynamic>.from(json as Map<String, dynamic>);
        if (request['profiles'] != null) {
          request['agent_name'] = request['profiles']['full_name'];
        }
        if (request['payments'] != null && request['payments']['customers'] != null) {
          request['customer_name'] = request['payments']['customers']['full_name'];
        }
        return PaymentEditRequest.fromJson(request);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch all requests: $e');
    }
  }

  /// Approve a payment edit request
  Future<void> approveRequest(String requestId, String adminId) async {
    try {
      // Get the request details first
      final requestResponse = await _supabase
          .from('payment_edit_requests')
          .select('payment_id, new_amount')
          .eq('id', requestId)
          .single();

      final paymentId = requestResponse['payment_id'] as String;
      final newAmount = (requestResponse['new_amount'] as num).toDouble();

      // Update the original payment amount
      await _supabase
          .from('payments')
          .update({'amount_paid': newAmount})
          .eq('id', paymentId);

      // Mark request as approved
      await _supabase
          .from('payment_edit_requests')
          .update({
            'status': 'approved',
            'reviewed_by': adminId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  /// Reject a payment edit request
  Future<void> rejectRequest(String requestId, String adminId) async {
    try {
      await _supabase
          .from('payment_edit_requests')
          .update({
            'status': 'rejected',
            'reviewed_by': adminId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  /// Create a new payment edit request (for agents)
  Future<PaymentEditRequest> createRequest({
    required String paymentId,
    required String agentId,
    required double originalAmount,
    required double newAmount,
    required String reason,
  }) async {
    try {
      final data = {
        'payment_id': paymentId,
        'agent_id': agentId,
        'original_amount': originalAmount,
        'new_amount': newAmount,
        'reason': reason,
        'status': 'pending',
      };

      final response = await _supabase
          .from('payment_edit_requests')
          .insert(data)
          .select()
          .single();

      return PaymentEditRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create edit request: $e');
    }
  }
}
