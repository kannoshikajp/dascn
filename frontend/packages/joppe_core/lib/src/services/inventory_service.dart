import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/good_receipt_detail.dart';
import '../models/good_receipt_summary.dart';
import '../models/inventory_stock_item.dart';
import '../models/supplier_item.dart';

class InventoryService {
  final ApiClient _client;

  InventoryService(this._client);

  // ---------------------------------------------------------------------------
  // Suppliers Management
  // ---------------------------------------------------------------------------

  Future<List<SupplierItem>> listSuppliers({
    bool? isActive,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _client.get(ApiConstants.adminInventorySuppliers, queryParams);
    if (response is List) {
      return response
          .map((e) => SupplierItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SupplierItem> getSupplierById(String id) async {
    final response = await _client.get('${ApiConstants.adminInventorySuppliers}/$id');
    return SupplierItem.fromJson(response as Map<String, dynamic>);
  }

  Future<SupplierItem> createSupplier({
    required String supplierName,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    bool isActive = true,
  }) async {
    final response = await _client.post(ApiConstants.adminInventorySuppliers, {
      'supplierName': supplierName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      'isActive': isActive,
    });
    return SupplierItem.fromJson(response as Map<String, dynamic>);
  }

  Future<SupplierItem> updateSupplier({
    required String id,
    required String supplierName,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    bool? isActive,
  }) async {
    final response = await _client.put('${ApiConstants.adminInventorySuppliers}/$id', {
      'supplierName': supplierName,
      if (contactPerson != null) 'contactPerson': contactPerson,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (isActive != null) 'isActive': isActive,
    });
    return SupplierItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> toggleSupplierStatus(String id, bool isActive) async {
    await _client.patch('${ApiConstants.adminInventorySuppliers}/$id/status', {
      'isActive': isActive,
    });
  }

  Future<void> deleteSupplier(String id) async {
    await _client.delete('${ApiConstants.adminInventorySuppliers}/$id');
  }

  // ---------------------------------------------------------------------------
  // Goods Receipts (Inbound Inventory Batch Import)
  // ---------------------------------------------------------------------------

  Future<List<GoodReceiptSummary>> listReceipts({
    String? receiptType,
    String? status,
    String? supplierId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (receiptType != null && receiptType.isNotEmpty) queryParams['receiptType'] = receiptType;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (supplierId != null && supplierId.isNotEmpty) queryParams['supplierId'] = supplierId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _client.get(ApiConstants.adminInventoryReceipts, queryParams);
    if (response is List) {
      return response
          .map((e) => GoodReceiptSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<GoodReceiptDetail> getReceiptDetail(String id) async {
    final response = await _client.get('${ApiConstants.adminInventoryReceipts}/$id');
    return GoodReceiptDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<GoodReceiptDetail> createReceipt({
    required String supplierId,
    String? receiptCode,
    bool completeImmediately = false,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(ApiConstants.adminInventoryReceipts, {
      'supplierId': supplierId,
      if (receiptCode != null && receiptCode.isNotEmpty) 'receiptCode': receiptCode,
      'completeImmediately': completeImmediately,
      'items': items,
    });
    return GoodReceiptDetail.fromJson(response as Map<String, dynamic>);
  }

  Future<GoodReceiptDetail> completeReceipt(String id) async {
    final response = await _client.post('${ApiConstants.adminInventoryReceipts}/$id/complete');
    return GoodReceiptDetail.fromJson(response as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Warehouse Stock & Low Stock Audit
  // ---------------------------------------------------------------------------

  Future<List<InventoryStockItem>> listStock({
    bool? lowStockOnly,
    String? search,
    int? categoryId,
    int? brandId,
  }) async {
    final queryParams = <String, String>{};
    if (lowStockOnly != null) queryParams['lowStockOnly'] = lowStockOnly.toString();
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
    if (brandId != null) queryParams['brandId'] = brandId.toString();

    final response = await _client.get(ApiConstants.adminInventoryStock, queryParams);
    if (response is List) {
      return response
          .map((e) => InventoryStockItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<InventoryStockItem> adjustStock(
    String variantId, {
    required int quantityOnHand,
    required int reorderLevel,
  }) async {
    final response = await _client.patch('${ApiConstants.adminInventoryStock}/$variantId', {
      'quantityOnHand': quantityOnHand,
      'reorderLevel': reorderLevel,
    });
    return InventoryStockItem.fromJson(response as Map<String, dynamic>);
  }
}
