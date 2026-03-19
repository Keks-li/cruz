/// Model for customer_products junction table
/// Represents a product assigned to a customer
class CustomerProduct {
  final String id;
  final String customerId;
  final int productId;
  final bool isActive;
  final int boxesAssigned;
  final int boxesPaid;
  final double balanceDue;
  final double registrationFeePaid;
  final DateTime createdAt;
  final bool deletionRequested; // For Admin Approval

  // Joined fields
  final String? productName;
  final double? pricePerBox;
  final double? totalPrice;
  final String? customerName; // From joins
  final String? agentName; // From joins

  const CustomerProduct({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.isActive,
    required this.boxesAssigned,
    required this.boxesPaid,
    required this.balanceDue,
    required this.registrationFeePaid,
    required this.createdAt,
    this.deletionRequested = false,
    this.productName,
    this.pricePerBox,
    this.totalPrice,
    this.customerName,
    this.agentName,
  });

  factory CustomerProduct.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from either int or String
    int parseIntOrZero(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }
    
    double parseDoubleOrZero(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    double? parseDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    String? getCustomerName(Map<String, dynamic> j) {
      if (j['customers'] != null) {
        return j['customers']['full_name'] as String?;
      }
      return null;
    }

    String? getAgentName(Map<String, dynamic> j) {
      if (j['customers'] != null && j['customers']['profiles'] != null) {
        return j['customers']['profiles']['full_name'] as String?;
      }
      return null;
    }

    return CustomerProduct(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      productId: parseIntOrZero(json['product_id']),
      isActive: json['is_active'] as bool? ?? true,
      boxesAssigned: parseIntOrZero(json['boxes_assigned']),
      boxesPaid: parseIntOrZero(json['boxes_paid']),
      balanceDue: parseDoubleOrZero(json['balance_due']),
      registrationFeePaid: parseDoubleOrZero(json['registration_fee_paid']),
      createdAt: DateTime.parse(json['created_at'] as String),
      deletionRequested: json['deletion_requested'] as bool? ?? false,
      productName: json['product_name'] as String?,
      pricePerBox: parseDoubleOrNull(json['price_per_box']),
      totalPrice: parseDoubleOrNull(json['total_price']),
      customerName: getCustomerName(json),
      agentName: getAgentName(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'product_id': productId,
      'is_active': isActive,
      'boxes_assigned': boxesAssigned,
      'boxes_paid': boxesPaid,
      'balance_due': balanceDue,
      'registration_fee_paid': registrationFeePaid,
    };
  }

  /// Calculate boxes left to pay
  int get boxesLeft => boxesAssigned - boxesPaid;

  /// Calculate progress percentage
  double get progressPercent => boxesAssigned > 0 ? boxesPaid / boxesAssigned : 0.0;

  CustomerProduct copyWith({
    String? id,
    String? customerId,
    int? productId,
    bool? isActive,
    int? boxesAssigned,
    int? boxesPaid,
    double? balanceDue,
    double? registrationFeePaid,
    DateTime? createdAt,
    String? productName,
    double? pricePerBox,
    double? totalPrice,
  }) {
    return CustomerProduct(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      isActive: isActive ?? this.isActive,
      boxesAssigned: boxesAssigned ?? this.boxesAssigned,
      boxesPaid: boxesPaid ?? this.boxesPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      registrationFeePaid: registrationFeePaid ?? this.registrationFeePaid,
      createdAt: createdAt ?? this.createdAt,
      productName: productName ?? this.productName,
      pricePerBox: pricePerBox ?? this.pricePerBox,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
