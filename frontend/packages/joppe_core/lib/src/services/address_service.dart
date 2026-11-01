import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/address_item.dart';

class AddressService {
  final ApiClient _client;

  AddressService(this._client);

  Future<List<AddressItem>> getAddresses() async {
    final response = await _client.get(ApiConstants.addresses);
    if (response is List) {
      return response
          .map((e) => AddressItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<AddressItem> getAddressById(String id) async {
    final response = await _client.get('${ApiConstants.addresses}/$id');
    return AddressItem.fromJson(response as Map<String, dynamic>);
  }

  Future<AddressItem> createAddress({
    required String recipientName,
    required String recipientPhone,
    required String streetAddress,
    String? ward,
    String? district,
    required String province,
    bool isDefault = false,
  }) async {
    final response = await _client.post(ApiConstants.addresses, {
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'streetAddress': streetAddress,
      if (ward != null) 'ward': ward,
      if (district != null) 'district': district,
      'province': province,
      'isDefault': isDefault,
    });
    return AddressItem.fromJson(response as Map<String, dynamic>);
  }

  Future<AddressItem> updateAddress({
    required String id,
    required String recipientName,
    required String recipientPhone,
    required String streetAddress,
    String? ward,
    String? district,
    required String province,
    bool? isDefault,
  }) async {
    final response = await _client.put('${ApiConstants.addresses}/$id', {
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'streetAddress': streetAddress,
      if (ward != null) 'ward': ward,
      if (district != null) 'district': district,
      'province': province,
      if (isDefault != null) 'isDefault': isDefault,
    });
    return AddressItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> setDefaultAddress(String id) async {
    await _client.patch('${ApiConstants.addresses}/$id/default');
  }

  Future<void> deleteAddress(String id) async {
    await _client.delete('${ApiConstants.addresses}/$id');
  }
}
