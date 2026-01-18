enum UserRole {
  admin('ADMIN'),
  agent('AGENT');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.agent,
    );
  }
}

class Profile {
  final String id;
  final UserRole role;
  final bool isActive;
  final String? fullName;
  final String? email;

  const Profile({
    required this.id,
    required this.role,
    required this.isActive,
    this.fullName,
    this.email,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: UserRole.fromString(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'is_active': isActive,
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
    };
  }

  Profile copyWith({
    String? id,
    UserRole? role,
    bool? isActive,
    String? fullName,
    String? email,
  }) {
    return Profile(
      id: id ?? this.id,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
    );
  }
}
