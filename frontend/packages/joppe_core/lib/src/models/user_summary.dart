class UserSummary {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final int roleId;
  final String roleName;
  final bool isActive;
  final DateTime? createdAt;

  const UserSummary({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    required this.roleId,
    required this.roleName,
    this.isActive = true,
    this.createdAt,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      roleId: json['roleId'] as int? ?? 1,
      roleName: json['roleName'] as String? ?? 'ROLE_CUSTOMER',
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
        'roleId': roleId,
        'roleName': roleName,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}
