class Cycle {
  final int id;
  final String name;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;

  const Cycle({
    required this.id,
    required this.name,
    required this.isActive,
    required this.startedAt,
    this.endedAt,
    this.notes,
  });

  factory Cycle.fromJson(Map<String, dynamic> json) {
    return Cycle(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? false,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'is_active': isActive,
        if (notes != null) 'notes': notes,
      };

  Cycle copyWith({
    int? id,
    String? name,
    bool? isActive,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
  }) {
    return Cycle(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
    );
  }
}
