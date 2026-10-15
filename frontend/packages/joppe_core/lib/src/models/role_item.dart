class RoleItem {
  final int id;
  final String roleName;
  final String? description;
  final List<String> permissions;

  const RoleItem({
    required this.id,
    required this.roleName,
    this.description,
    this.permissions = const [],
  });

  bool get isSystemRole =>
      roleName == 'ROLE_ADMIN' ||
      roleName == 'ROLE_STAFF' ||
      roleName == 'ROLE_CUSTOMER';

  factory RoleItem.fromJson(Map<String, dynamic> json) {
    return RoleItem(
      id: json['id'] as int,
      roleName: json['roleName'] as String,
      description: json['description'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roleName': roleName,
        'description': description,
        'permissions': permissions,
      };
}
