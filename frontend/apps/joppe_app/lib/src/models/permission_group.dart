import 'permission.dart';

/// Model nhóm quyền trong hệ thống Joppe RBAC (PermissionGroup)
class PermissionGroup {
  final int id;
  final String groupName;
  final String? description;
  final bool isBuiltIn;
  final List<Permission> permissions;

  const PermissionGroup({
    required this.id,
    required this.groupName,
    this.description,
    this.isBuiltIn = false,
    this.permissions = const [],
  });

  factory PermissionGroup.fromJson(Map<String, dynamic> json) {
    var rawPerms = json['permissions'];
    List<Permission> parsedPermissions = [];
    if (rawPerms is List) {
      parsedPermissions = rawPerms
          .whereType<Map<String, dynamic>>()
          .map((p) => Permission.fromJson(p))
          .toList();
    }

    return PermissionGroup(
      id: (json['id'] as num).toInt(),
      groupName: (json['groupName'] as String?) ?? '',
      description: json['description'] as String?,
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? false,
      permissions: parsedPermissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      if (description != null) 'description': description,
      'isBuiltIn': isBuiltIn,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}
