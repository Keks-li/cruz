/// Model for payment edit requests
/// Agents can request edits to payments; Admin approves/rejects
class PaymentEditRequest {
  final String id;
  final String paymentId;
  final String agentId;
  final double originalAmount;
  final double newAmount;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // Joined fields
  final String? agentName;
  final String? customerName;

  const PaymentEditRequest({
    required this.id,
    required this.paymentId,
    required this.agentId,
    required this.originalAmount,
    required this.newAmount,
    required this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.agentName,
    this.customerName,
  });

  factory PaymentEditRequest.fromJson(Map<String, dynamic> json) {
    return PaymentEditRequest(
      id: json['id'] as String,
      paymentId: json['payment_id'] as String,
      agentId: json['agent_id'] as String,
      originalAmount: (json['original_amount'] as num).toDouble(),
      newAmount: (json['new_amount'] as num).toDouble(),
      reason: json['reason'] as String,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      agentName: json['agent_name'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'agent_id': agentId,
      'original_amount': originalAmount,
      'new_amount': newAmount,
      'reason': reason,
      'status': status,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// Calculate the difference between new and original amount
  double get amountDifference => newAmount - originalAmount;

  PaymentEditRequest copyWith({
    String? id,
    String? paymentId,
    String? agentId,
    double? originalAmount,
    double? newAmount,
    String? reason,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    String? agentName,
    String? customerName,
  }) {
    return PaymentEditRequest(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      agentId: agentId ?? this.agentId,
      originalAmount: originalAmount ?? this.originalAmount,
      newAmount: newAmount ?? this.newAmount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      agentName: agentName ?? this.agentName,
      customerName: customerName ?? this.customerName,
    );
  }
}
