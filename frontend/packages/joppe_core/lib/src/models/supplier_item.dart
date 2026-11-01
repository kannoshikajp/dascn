class SupplierItem {
  final String id;
  final String supplierName;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;

  const SupplierItem({
    required this.id,
    required this.supplierName,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
    this.isActive = true,
    this.createdAt,
  });

  factory SupplierItem.fromJson(Map<String, dynamic> json) {
    return SupplierItem(
      id: json['id'] as String,
      supplierName: json['supplierName'] as String? ?? '',
      contactPerson: json['contactPerson'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplierName': supplierName,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}
