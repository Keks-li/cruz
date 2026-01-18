class Zone {
  final int id;
  final String name;
  final DateTime createdAt;

  const Zone({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
