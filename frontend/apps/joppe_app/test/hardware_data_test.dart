import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/data/mock_data.dart';
import 'package:joppe_app/src/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Calculates discount percentage correctly with edge cases', () {
      const discountedProduct = Product(
        id: 'test-1',
        name: 'Test Product',
        description: 'Description',
        price: 80.0,
        originalPrice: 100.0,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(discountedProduct.discountPercentage, 20);

      const noDiscountProduct = Product(
        id: 'test-2',
        name: 'Regular Product',
        description: 'Description',
        price: 100.0,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(noDiscountProduct.discountPercentage, 0);

      const equalPriceProduct = Product(
        id: 'test-3',
        name: 'Equal Product',
        description: 'Description',
        price: 100.0,
        originalPrice: 100.0,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(equalPriceProduct.discountPercentage, 0);

      const zeroOriginalPriceProduct = Product(
        id: 'test-4',
        name: 'Zero Original Product',
        description: 'Description',
        price: 50.0,
        originalPrice: 0.0,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(zeroOriginalPriceProduct.discountPercentage, 0);

      const negativeOriginalPriceProduct = Product(
        id: 'test-5',
        name: 'Negative Original Product',
        description: 'Description',
        price: 50.0,
        originalPrice: -10.0,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(negativeOriginalPriceProduct.discountPercentage, 0);
    });

    test('Formats pure VND prices properly using static and instance formatters', () {
      const product = Product(
        id: 'test-p',
        name: 'High-end GPU',
        description: 'Super fast',
        price: 25400000.0,
        originalPrice: 30480000.0,
        imageUrl: 'https://example.com/gpu.jpg',
      );

      expect(product.price, 25400000.0);
      expect(product.originalPrice, 30480000.0);
      expect(product.formattedPrice, '25.400.000 ₫');
      expect(product.formattedOriginalPrice, '30.480.000 ₫');
      expect(product.priceVnd, 25400000.0);
      expect(product.formattedPriceVnd, '25.400.000 ₫');
      expect(product.formattedOriginalPriceVnd, '30.480.000 ₫');

      // Static formatVnd tests
      expect(Product.formatVnd(0), '0 ₫');
      expect(Product.formatVnd(500), '500 ₫');
      expect(Product.formatVnd(1000), '1.000 ₫');
      expect(Product.formatVnd(25400000), '25.400.000 ₫');
      expect(Product.formatVnd(-1500000), '-1.500.000 ₫');
      expect(Product.formatVnd(double.nan), '0 ₫');
      expect(Product.formatVnd(double.infinity), '0 ₫');
    });

    test('Supports technical specs map and component type', () {
      const cpu = Product(
        id: 'cpu-test',
        name: 'Intel CPU',
        description: 'Fast CPU',
        price: 500.0,
        imageUrl: 'https://example.com/cpu.jpg',
        componentType: 'cpu',
        technicalSpecs: {
          'Socket': 'LGA 1851',
          'Cores': '24',
        },
      );

      expect(cpu.componentType, 'cpu');
      expect(cpu.technicalSpecs['Socket'], 'LGA 1851');
      expect(cpu.technicalSpecs['Cores'], '24');
    });
  });

  group('HardwareMockData Catalog Integrity Tests', () {
    test('Has required build categories for PC Builder and unique category IDs', () {
      final categories = HardwareMockData.categories;
      expect(categories, isNotEmpty);

      final categoryIds = categories.map((c) => c.id).toList();
      expect(categoryIds.toSet().length, equals(categoryIds.length), reason: 'Category IDs must be unique');

      final requiredCategories = categories.where((c) => c.isRequiredForBuild).map((c) => c.id).toSet();
      expect(requiredCategories, containsAll({
        'cpu',
        'mainboard',
        'ram',
        'gpu',
        'storage',
        'psu',
        'cooler',
        'case',
      }));
    });

    test('All product IDs are unique across the entire catalog', () {
      final products = HardwareMockData.products;
      final ids = products.map((p) => p.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, equals(uniqueIds.length), reason: 'All product IDs must be unique');
    });

    test('All products have valid attributes, positive prices, and non-empty specs', () {
      final products = HardwareMockData.products;
      expect(products.length, greaterThanOrEqualTo(40));

      for (final p in products) {
        expect(p.id, isNotEmpty);
        expect(p.name, isNotEmpty);
        expect(p.price, greaterThan(0));
        expect(p.imageUrl, startsWith('https://'));
        expect(p.brand, isNotEmpty);
        expect(p.warrantyMonths, greaterThan(0));
        expect(p.specs, isNotEmpty);
        expect(p.technicalSpecs, isNotNull);
      }
    });

    test('Every component category has available products', () {
      final buildCategories = ['cpu', 'gpu', 'mainboard', 'ram', 'storage', 'psu', 'cooler', 'case'];
      for (final catId in buildCategories) {
        final items = HardwareMockData.getByComponentType(catId);
        expect(items, isNotEmpty, reason: 'Category $catId must have candidate products');
        expect(items.length, greaterThanOrEqualTo(3), reason: 'Category $catId should have at least 3 items');
      }
    });

    test('Query helpers return expected results', () {
      // 1. By component type
      final cpus = HardwareMockData.getByComponentType('cpu');
      expect(cpus, isNotEmpty);
      expect(cpus.every((p) => p.componentType == 'cpu'), isTrue);

      final gpus = HardwareMockData.getByComponentType('gpu');
      expect(gpus, isNotEmpty);
      expect(gpus.every((p) => p.componentType == 'gpu'), isTrue);

      // 2. By category
      final gear = HardwareMockData.getByCategory('Gaming Gear');
      expect(gear, isNotEmpty);

      // 3. Search query
      final rtxResults = HardwareMockData.searchProducts('RTX 5080');
      expect(rtxResults, isNotEmpty);
      expect(rtxResults.any((p) => p.name.contains('RTX 5080')), isTrue);

      final intelResults = HardwareMockData.searchProducts('Intel');
      expect(intelResults, isNotEmpty);

      // Search in technicalSpecs
      final lgaResults = HardwareMockData.searchProducts('LGA 1851');
      expect(lgaResults, isNotEmpty);

      // Empty search query returns all
      expect(HardwareMockData.searchProducts('').length, equals(HardwareMockData.products.length));

      // 4. Build PC components
      final buildComponents = HardwareMockData.getBuildPcComponents();
      expect(buildComponents, isNotEmpty);
      expect(buildComponents.any((p) => p.componentType == 'cpu'), isTrue);
      expect(buildComponents.any((p) => p.componentType == 'mainboard'), isTrue);
      expect(buildComponents.any((p) => p.componentType == 'ram'), isTrue);
      expect(buildComponents.any((p) => p.componentType == 'gpu'), isTrue);

      // 5. Smart filter helper
      expect(HardwareMockData.filterProducts('Tất cả').length, equals(HardwareMockData.products.length));
      expect(HardwareMockData.filterProducts('cpu').every((p) => p.componentType == 'cpu'), isTrue);
      expect(HardwareMockData.filterProducts('CPU').every((p) => p.componentType == 'cpu'), isTrue);
      expect(HardwareMockData.filterProducts('Khuyến Mãi').every((p) => p.discountPercentage > 0), isTrue);
    });

    test('mockProducts global list is synchronized with HardwareMockData', () {
      expect(mockProducts, isNotEmpty);
      expect(mockProducts.length, equals(HardwareMockData.products.length));
    });
  });
}
