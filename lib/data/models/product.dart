class Product {
  final int id;
  final String name;
  final String? code;
  final String type; // 'single' | 'double'
  final int? cycleId;
  final double boxRate;
  final int totalBoxes;
  // READ-ONLY: This is a generated column calculated by Postgres
  final double totalPrice;

  const Product({
    required this.id,
    required this.name,
    this.code,
    this.type = 'single',
    this.cycleId,
    required this.boxRate,
    required this.totalBoxes,
    required this.totalPrice,
  });

  bool get isSingle => type == 'single';
  bool get isDouble => type == 'double';

  /// Returns user-friendly name, e.g. for single: 'CRZ 1', for double: 'Bronze Package (BP-01)'
  String get displayName {
    if (isDouble && code != null && code!.trim().isNotEmpty && code != name) {
      return '$name ($code)';
    }
    return name.isNotEmpty ? name : (code ?? '');
  }

  factory Product.fromJson(Map<String, dynamic> json) {
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

    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return Product(
      id: parseIntOrZero(json['id']),
      name: json['name'] as String? ?? json['code'] as String? ?? '',
      code: json['code'] as String?,
      type: json['type'] as String? ?? 'single',
      cycleId: parseNullableInt(json['cycle_id']),
      boxRate: parseDoubleOrZero(json['box_rate']),
      totalBoxes: parseIntOrZero(json['total_boxes']),
      totalPrice: parseDoubleOrZero(json['total_price']),
    );
  }

  /// Calculate total_price before creating/updating products
  Map<String, dynamic> toJsonForInsert() {
    return {
      'name': name,
      if (code != null) 'code': code,
      'type': type,
      if (cycleId != null) 'cycle_id': cycleId,
      'box_rate': boxRate,
      'total_boxes': totalBoxes,
      'total_price': boxRate * totalBoxes,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (code != null) 'code': code,
      'type': type,
      if (cycleId != null) 'cycle_id': cycleId,
      'box_rate': boxRate,
      'total_boxes': totalBoxes,
      'total_price': boxRate * totalBoxes,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? code,
    String? type,
    int? cycleId,
    double? boxRate,
    int? totalBoxes,
    double? totalPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      cycleId: cycleId ?? this.cycleId,
      boxRate: boxRate ?? this.boxRate,
      totalBoxes: totalBoxes ?? this.totalBoxes,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
