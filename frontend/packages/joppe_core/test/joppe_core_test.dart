import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_core/joppe_core.dart';

void main() {
  test('UserProfile JSON serialization and permission check', () {
    final profile = UserProfile.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'email': 'admin@joppe.vn',
      'fullName': 'Admin User',
      'role': 'ROLE_ADMIN',
      'permissions': ['AUTH_ME', 'USER_READ'],
      'isActive': true,
    });

    expect(profile.email, 'admin@joppe.vn');
    expect(profile.hasPermission('AUTH_ME'), isTrue);
    expect(profile.hasPermission('PRODUCT_DELETE'), isFalse);
    expect(profile.toJson()['role'], 'ROLE_ADMIN');
  });

  test('CategoryItem JSON serialization and deserialization', () {
    final item = CategoryItem.fromJson({
      'id': 10,
      'parentId': 2,
      'parentName': 'Laptops',
      'categoryName': 'Gaming Laptops',
      'slug': 'gaming-laptops',
      'iconUrl': 'https://joppe.vn/icon.png',
      'isActive': true,
      'createdAt': '2026-03-30T10:00:00.000Z',
      'productCount': 42,
      'childCount': 3,
    });

    expect(item.id, 10);
    expect(item.parentId, 2);
    expect(item.parentName, 'Laptops');
    expect(item.categoryName, 'Gaming Laptops');
    expect(item.slug, 'gaming-laptops');
    expect(item.productCount, 42);
    expect(item.childCount, 3);
    expect(item.isActive, isTrue);

    final json = item.toJson();
    expect(json['id'], 10);
    expect(json['slug'], 'gaming-laptops');
  });

  test('CategoryNode JSON hierarchical tree serialization', () {
    final node = CategoryNode.fromJson({
      'id': 1,
      'parentId': null,
      'categoryName': 'Electronics',
      'slug': 'electronics',
      'iconUrl': null,
      'isActive': true,
      'productCount': 100,
      'children': [
        {
          'id': 2,
          'parentId': 1,
          'categoryName': 'Laptops',
          'slug': 'laptops',
          'iconUrl': null,
          'isActive': true,
          'productCount': 60,
          'children': [
            {
              'id': 3,
              'parentId': 2,
              'categoryName': 'Gaming',
              'slug': 'gaming',
              'iconUrl': null,
              'isActive': true,
              'productCount': 25,
              'children': [],
            }
          ],
        }
      ],
    });

    expect(node.id, 1);
    expect(node.children.length, 1);
    expect(node.children.first.categoryName, 'Laptops');
    expect(node.children.first.children.length, 1);
    expect(node.children.first.children.first.categoryName, 'Gaming');
    expect(node.children.first.children.first.productCount, 25);

    final json = node.toJson();
    expect((json['children'] as List).length, 1);
  });

  test('ProductItem JSON multi-category serialization', () {
    final product = ProductItem.fromJson({
      'id': 'a1111111-1111-1111-1111-111111111111',
      'productName': 'ASUS ROG Strix G16',
      'slug': 'asus-rog-strix-g16',
      'brandId': 1,
      'brandName': 'ASUS',
      'shortDescription': 'Gaming powerhouse',
      'warrantyMonths': 24,
      'thumbnailUrl': 'https://joppe.vn/g16.png',
      'isActive': true,
      'minPrice': 42000000.0,
      'maxPrice': 45000000.0,
      'totalStock': 15,
      'categories': [
        {'id': 10, 'categoryName': 'Laptops', 'slug': 'laptops', 'isPrimary': true},
        {'id': 20, 'categoryName': 'Gaming', 'slug': 'gaming', 'isPrimary': false},
      ],
      'variants': [
        {
          'id': 'v1111111-1111-1111-1111-111111111111',
          'sku': 'SKU-ROG-01',
          'variantName': 'Default Variant',
          'listPrice': 45000000.0,
          'salePrice': 42000000.0,
          'quantityOnHand': 15,
          'quantityReserved': 0,
          'availableQuantity': 15,
          'weightGram': 2500.0,
          'isActive': true,
        }
      ],
    });

    expect(product.productName, 'ASUS ROG Strix G16');
    expect(product.categories.length, 2);
    expect(product.categories.first.isPrimary, isTrue);
    expect(product.categories.last.isPrimary, isFalse);
    expect(product.variants.length, 1);
    expect(product.variants.first.sku, 'SKU-ROG-01');
    expect(product.totalStock, 15);
    expect(product.minPrice, 42000000.0);

    final json = product.toJson();
    expect((json['categories'] as List).length, 2);
    expect((json['variants'] as List).length, 1);
  });

  test('ProductVariantSummary JSON and parsed attributes', () {
    final variant = ProductVariantSummary.fromJson({
      'id': 'v2',
      'sku': 'SKU-ROG-32GB',
      'variantName': '32GB RAM / RTX 4070',
      'attributes': '{"RAM": "32GB", "GPU": "RTX 4070"}',
      'listPrice': 55000000.0,
      'salePrice': 52000000.0,
      'quantityOnHand': 8,
      'quantityReserved': 1,
      'availableQuantity': 7,
      'weightGram': 2400.0,
      'isActive': true,
    });

    expect(variant.sku, 'SKU-ROG-32GB');
    expect(variant.attributes, isNotNull);
    final attrs = variant.parsedAttributes;
    expect(attrs['RAM'], '32GB');
    expect(attrs['GPU'], 'RTX 4070');
    expect(variant.availableQuantity, 7);

    final json = variant.toJson();
    expect(json['sku'], 'SKU-ROG-32GB');
    expect(json['attributes'], '{"RAM": "32GB", "GPU": "RTX 4070"}');
  });

  group('VnPayService and VnPayPaymentModel Tests', () {
    test('VnPayPaymentModel safely decodes Base64 data URI in qrBytes', () {
      final model = VnPayPaymentModel(
        paymentId: 'pay-123',
        paymentUrl: 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
        orderCode: 'ORD-999',
        txnRef: 'ORD-999_123',
        amount: 5000000,
        qrCodeBase64: 'data:image/png;base64,SGVsbG8gV09STEI=',
      );

      expect(model.qrBytes, isNotNull);
      expect(model.qrBytes!.length, greaterThan(0));
    });

    test('buildFallbackPaymentUrl includes all required VNPay params and HMAC-SHA512 hash', () {
      final client = ApiClient(baseUrl: 'https://joppe.penguinlab.org');
      final vnPay = VnPayService(client);

      final url = vnPay.buildFallbackPaymentUrl(
        orderCode: 'JP-2026-TEST',
        amount: 1500000,
        txnRef: 'JP-2026-TEST_999999',
        bankCode: 'NCB',
      );

      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'sandbox.vnpayment.vn');
      expect(uri.path, '/paymentv2/vpcpay.html');

      final q = uri.queryParameters;
      expect(q['vnp_Version'], '2.1.0');
      expect(q['vnp_Command'], 'pay');
      expect(q['vnp_TmnCode'], 'H04KMMWQ');
      expect(q['vnp_Amount'], '150000000'); // 1,500,000 * 100
      expect(q['vnp_CurrCode'], 'VND');
      expect(q['vnp_TxnRef'], 'JP-2026-TEST_999999');
      expect(q['vnp_OrderInfo'], contains('JP-2026-TEST'));
      expect(q['vnp_Locale'], 'vn');
      expect(q['vnp_ReturnUrl'], 'https://joppe.penguinlab.org/api/v1/payment/vnpay/return');
      expect(q['vnp_IpAddr'], '127.0.0.1');
      expect(q['vnp_BankCode'], 'NCB');
      expect(q['vnp_CreateDate'], isNotNull);
      expect(q['vnp_CreateDate']!.length, 14); // yyyyMMddHHmmss
      expect(q['vnp_SecureHash'], isNotNull);
      expect(q['vnp_SecureHash']!.length, 128); // 512-bit hex string
    });
  });

  test('CustomerAiChatResponse JSON serialization and referenced products', () {
    final response = CustomerAiChatResponse.fromJson({
      'answer': 'Cấu hình i5 13400F + RTX 4060 rất cân bằng.',
      'referencedProducts': [
        {
          'id': 'p-1',
          'sku': 'CPU-I5-13400F',
          'name': 'Intel Core i5-13400F',
          'minPrice': 5200000,
          'maxPrice': 5500000,
          'totalStock': 12,
        }
      ],
      'quickReplies': ['Tối ưu ngân sách', 'Nâng cấp lên 32GB RAM'],
      'executedTools': ['search_products'],
    });

    expect(response.answer, contains('i5 13400F'));
    expect(response.referencedProducts.length, 1);
    expect(response.referencedProducts.first.sku, 'CPU-I5-13400F');
    expect(response.referencedProducts.first.minPrice, 5200000);
    expect(response.quickReplies.length, 2);
    expect(response.executedTools.first, 'search_products');
  });
}
