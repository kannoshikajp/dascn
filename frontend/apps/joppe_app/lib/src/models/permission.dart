/// Model quyền hạn trong hệ thống Joppe RBAC (Permission)
class Permission {
  final int id;
  final String permissionName;
  final String? description;
  final String? category;

  const Permission({
    required this.id,
    required this.permissionName,
    this.description,
    this.category,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: (json['id'] as num).toInt(),
      permissionName: (json['permissionName'] as String?) ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permissionName': permissionName,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    };
  }
}
