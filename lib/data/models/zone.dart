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
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.parse(rawId.toString());
    return Zone(
      id: id,
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
