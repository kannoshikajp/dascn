import 'permission_group.dart';

/// Model đại diện cho tài khoản người dùng Joppe E-Commerce
/// Tương thích với schema User trong OpenAPI (/api/v1/users/me và /api/v1/auth/...)
class UserAccount {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? avatarUrl;
  final DateTime createdAt;
  final String role; // 'Khách hàng', 'VIP Gamer', 'Quản trị viên', hoặc tên PermissionGroup
  final int rewardPoints;
  final bool isActive;
  final String? token;
  final PermissionGroup? permissionGroup;
  final List<String> permissions;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.avatarUrl,
    required this.createdAt,
    this.role = 'VIP Gamer',
    this.rewardPoints = 500,
    this.isActive = true,
    this.token,
    this.permissionGroup,
    this.permissions = const [],
  });

  /// Kiểm tra tài khoản có quyền cụ thể theo mã quyền hệ thống (API_SCHEMA.md)
  bool hasPermission(String permissionKey) {
    if (role == 'ROLE_ADMIN' || permissions.contains('ROLE_ADMIN') || role == 'Quản trị viên') {
      return true;
    }
    return permissions.contains(permissionKey);
  }

  /// Tạo bản sao cập nhật thông tin
  UserAccount copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? role,
    int? rewardPoints,
    bool? isActive,
    String? token,
    PermissionGroup? permissionGroup,
    List<String>? permissions,
  }) {
    return UserAccount(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      role: role ?? this.role,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
      permissionGroup: permissionGroup ?? this.permissionGroup,
      permissions: permissions ?? this.permissions,
    );
  }

  /// Chuyển đổi sang JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
      'rewardPoints': rewardPoints,
      'isActive': isActive,
      'permissions': permissions,
      if (token != null) 'token': token,
      if (permissionGroup != null) 'permissionGroup': permissionGroup!.toJson(),
    };
  }

  /// Khởi tạo từ JSON Map (Hỗ trợ cấu trúc trả về từ backend Spring Boot và mock data)
  factory UserAccount.fromJson(Map<String, dynamic> json, {String? token}) {
    PermissionGroup? parsedGroup;
    if (json['permissionGroup'] != null && json['permissionGroup'] is Map<String, dynamic>) {
      parsedGroup = PermissionGroup.fromJson(json['permissionGroup'] as Map<String, dynamic>);
    }

    String derivedRole = 'VIP Gamer';
    if (json['role'] != null) {
      derivedRole = json['role'].toString();
    } else if (parsedGroup != null && parsedGroup.groupName.isNotEmpty) {
      derivedRole = parsedGroup.groupName;
    }

    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
    } catch (_) {
      parsedCreatedAt = DateTime.now();
    }

    // Đọc danh sách permissions trực tiếp từ JWT/API payload theo API_SCHEMA.md
    List<String> parsedPermissions = [];
    if (json['permissions'] is List) {
      parsedPermissions = (json['permissions'] as List).map((e) => e.toString()).toList();
    } else if (parsedGroup != null) {
      parsedPermissions = parsedGroup.permissions.map((p) => p.permissionName).toList();
    }

    return UserAccount(
      id: (json['id'] as String?) ?? (json['userId'] as String?) ?? 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: parsedCreatedAt,
      role: derivedRole,
      rewardPoints: (json['rewardPoints'] as int?) ?? 500,
      isActive: (json['isActive'] as bool?) ?? true,
      token: token ?? (json['token'] as String?) ?? (json['accessToken'] as String?),
      permissionGroup: parsedGroup,
      permissions: parsedPermissions,
    );
  }
}
