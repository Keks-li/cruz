class Product {
  final int id;
  final String name;
  final double boxRate;
  final int totalBoxes;
  // READ-ONLY: This is a generated column calculated by Postgres
  final double totalPrice;

  const Product({
    required this.id,
    required this.name,
    required this.boxRate,
    required this.totalBoxes,
    required this.totalPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      boxRate: (json['box_rate'] as num).toDouble(),
      totalBoxes: json['total_boxes'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  /// IMPORTANT: Do NOT include totalPrice when creating/updating products
  /// It is a generated column in PostgreSQL
  Map<String, dynamic> toJsonForInsert() {
    return {
      'name': name,
      'box_rate': boxRate,
      'total_boxes': totalBoxes,
      // DO NOT send total_price - it's auto-calculated
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (name.isNotEmpty) 'name': name,
      'box_rate': boxRate,
      'total_boxes': totalBoxes,
      // DO NOT send total_price - it's auto-calculated
    };
  }

  Product copyWith({
    int? id,
    String? name,
    double? boxRate,
    int? totalBoxes,
    double? totalPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      boxRate: boxRate ?? this.boxRate,
      totalBoxes: totalBoxes ?? this.totalBoxes,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
