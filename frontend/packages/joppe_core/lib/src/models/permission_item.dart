class PermissionItem {
  final int id;
  final String permissionName;
  final String? description;

  const PermissionItem({
    required this.id,
    required this.permissionName,
    this.description,
  });

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
      id: json['id'] as int,
      permissionName: json['permissionName'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'permissionName': permissionName,
        'description': description,
      };
}
