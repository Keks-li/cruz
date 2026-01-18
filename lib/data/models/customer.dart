class Customer {
  final String id;
  final String fullName;
  final String? phone;
  final int? zoneId;
  final String productId;
  final String? assignedAgentId;
  final int totalBoxesAssigned;
  final int boxesPaid;
  final double balanceDue;
  final double registrationFeePaid;
  final bool isActive;
  final DateTime createdAt;

  // Optional fields for joins
  final String? zoneName;
  final String? productName;
  final String? agentName;

  const Customer({
    required this.id,
    required this.fullName,
    this.phone,
    this.zoneId,
    required this.productId,
    this.assignedAgentId,
    required this.totalBoxesAssigned,
    required this.boxesPaid,
    required this.balanceDue,
    required this.registrationFeePaid,
    required this.isActive,
    required this.createdAt,
    this.zoneName,
    this.productName,
    this.agentName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      zoneId: json['zone_id'] as int?,
      productId: json['product_id'].toString(),
      assignedAgentId: json['assigned_agent_id'] as String?,
      totalBoxesAssigned: json['total_boxes_assigned'] as int? ?? 0,
      boxesPaid: json['boxes_paid'] as int? ?? 0,
      balanceDue: (json['balance_due'] as num).toDouble(),
      registrationFeePaid: (json['registration_fee_paid'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      zoneName: json['zone_name'] as String?,
      productName: json['product_name'] as String?,
      agentName: json['agent_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (zoneId != null) 'zone_id': zoneId,
      'product_id': int.parse(productId),
      if (assignedAgentId != null) 'assigned_agent_id': assignedAgentId,
      'total_boxes_assigned': totalBoxesAssigned,
      'boxes_paid': boxesPaid,
      'balance_due': balanceDue,
      'is_active': isActive,
    };
  }

  Customer copyWith({
    String? id,
    String? fullName,
    String? phone,
    int? zoneId,
    String? productId,
    String? assignedAgentId,
    int? totalBoxesAssigned,
    int? boxesPaid,
    double? balanceDue,
    double? registrationFeePaid,
    bool? isActive,
    DateTime? createdAt,
    String? zoneName,
    String? productName,
    String? agentName,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      zoneId: zoneId ?? this.zoneId,
      productId: productId ?? this.productId,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      totalBoxesAssigned: totalBoxesAssigned ?? this.totalBoxesAssigned,
      boxesPaid: boxesPaid ?? this.boxesPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      registrationFeePaid: registrationFeePaid ?? this.registrationFeePaid,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      zoneName: zoneName ?? this.zoneName,
      productName: productName ?? this.productName,
      agentName: agentName ?? this.agentName,
    );
  }
}
