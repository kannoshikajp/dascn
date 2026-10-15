class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String role;
  final List<String> permissions;
  final bool isActive;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    this.permissions = const [],
    this.isActive = true,
    this.createdAt,
  });

  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasAnyPermission(Iterable<String> perms) => perms.any(permissions.contains);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'ROLE_CUSTOMER',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'avatarUrl': avatarUrl,
        'role': role,
        'permissions': permissions,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}
