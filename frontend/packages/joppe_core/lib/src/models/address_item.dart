class AddressItem {
  final String id;
  final String userId;
  final String recipientName;
  final String recipientPhone;
  final String streetAddress;
  final String? ward;
  final String? district;
  final String province;
  final bool isDefault;
  final DateTime? createdAt;

  const AddressItem({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.recipientPhone,
    required this.streetAddress,
    this.ward,
    this.district,
    required this.province,
    this.isDefault = false,
    this.createdAt,
  });

  String get formattedAddress {
    final parts = [
      streetAddress,
      if (ward != null && ward!.isNotEmpty) ward!,
      if (district != null && district!.isNotEmpty) district!,
      province,
    ];
    return parts.join(', ');
  }

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      recipientName: json['recipientName'] as String? ?? '',
      recipientPhone: json['recipientPhone'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'streetAddress': streetAddress,
        'ward': ward,
        'district': district,
        'province': province,
        'isDefault': isDefault,
        'createdAt': createdAt?.toIso8601String(),
      };
}
