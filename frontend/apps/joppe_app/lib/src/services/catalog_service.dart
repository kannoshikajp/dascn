import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import '../models/category_node.dart';
import '../models/component_category.dart';
import '../models/product.dart';
import 'app_api_client.dart';

/// Dịch vụ quản lý và đồng bộ danh mục & sản phẩm từ máy chủ Joppe REST API
/// Tích hợp trực tiếp với package joppe_core.StoreCatalogService
class CatalogService extends ChangeNotifier {
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;

  CatalogService._internal() {
    fetchCatalog();
  }

  core.ApiClient get apiClient => AppApiClient.instance;
  core.StoreCatalogService get _coreCatalog => core.StoreCatalogService(apiClient);

  List<Product> _remoteProducts = [];
  List<ComponentCategory> _remoteCategories = [];
  List<CategoryNode> _remoteCategoryTree = [];
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;

  List<Product> get allProducts {
    if (_remoteProducts.isNotEmpty) {
      return List.unmodifiable(_remoteProducts);
    }
    return _getDefaultApiProducts();
  }

  List<CategoryNode> get categoryTree {
    if (_remoteCategoryTree.isNotEmpty) {
      return _remoteCategoryTree;
    }
    return _getDefaultCategoryTree();
  }

  List<ComponentCategory> get buildSlots {
    final defaultSlots = _getDefaultBuildSlots();
    final Map<String, ComponentCategory> slotMap = {
      for (final slot in defaultSlots) slot.id: slot,
    };

    for (final remote in _remoteCategories) {
      if (remote.isRequiredForBuild) {
        slotMap[remote.id] = remote;
      }
    }

    final slots = slotMap.values.toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return List.unmodifiable(slots);
  }

  List<ComponentCategory> get allCategories {
    final coreSlots = buildSlots;
    final otherCategories = <ComponentCategory>[];

    final source = _remoteCategories.isNotEmpty ? _remoteCategories : _getDefaultApiCategories();
    for (final cat in source) {
      if (!cat.isRequiredForBuild) {
        final isDuplicate = coreSlots.any(
          (s) => s.id == cat.id || (s.slug != null && cat.slug != null && s.slug == cat.slug),
        );
        if (!isDuplicate) {
          otherCategories.add(cat);
        }
      }
    }

    return List.unmodifiable([...coreSlots, ...otherCategories]);
  }

  /// Danh mục sản phẩm thực tế từ API dùng cho duyệt, phân loại và tìm kiếm trên cửa hàng (HomeScreen)
  List<ComponentCategory> get storeCategories {
    if (_remoteCategories.isNotEmpty) {
      return List.unmodifiable(_remoteCategories);
    }
    return allCategories;
  }

  Future<void> fetchCatalog({bool force = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _coreCatalog.getRawProducts(),
        _coreCatalog.getRawCategoryTree(),
      ]);

      final rawProducts = results[0];
      final rawTree = results[1];

      final mappedProducts = <Product>[];
      for (final p in rawProducts) {
        try {
          mappedProducts.add(mapJsonToProduct(p));
        } catch (_) {}
      }

      if (mappedProducts.isNotEmpty || force) {
        _remoteProducts = mappedProducts;
      }

      final treeNodes = rawTree.map((m) => CategoryNode.fromJson(m)).toList();
      if (treeNodes.isNotEmpty || force) {
        _remoteCategoryTree = treeNodes;
      }

      final flattenedCategories = _flattenCategories(rawTree);
      if (flattenedCategories.isNotEmpty || force) {
        _remoteCategories = flattenedCategories;
      }

      _isOnline = true;
    } catch (e) {
      _isOnline = false;
      _errorMessage = 'Không thể đồng bộ từ máy chủ ($e).';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ComponentCategory> _flattenCategories(List<Map<String, dynamic>> rawList) {
    final categories = <ComponentCategory>[];

    void parseNodes(List<dynamic> nodes) {
      for (final rawNode in nodes) {
        if (rawNode is Map) {
          final node = Map<String, dynamic>.from(rawNode);
          final rawId = node['id']?.toString() ?? '';
          final name = node['categoryName']?.toString() ?? '';
          final slug = node['slug']?.toString() ?? '';

          final classification = _classifyCategory(slug, name);

          categories.add(
            ComponentCategory(
              id: classification.isBuildComponent
                  ? classification.canonicalId
                  : (slug.isNotEmpty ? slug : rawId),
              name: classification.isBuildComponent ? classification.canonicalName : name,
              shortName: classification.isBuildComponent ? classification.shortName : name,
              description: classification.isBuildComponent
                  ? classification.description
                  : 'Danh mục $name chính hãng tại JOPPE',
              icon: classification.icon,
              isRequiredForBuild: classification.isBuildComponent,
              displayOrder: classification.isBuildComponent
                  ? classification.displayOrder
                  : categories.length + 10,
              slug: slug.isNotEmpty ? slug : null,
            ),
          );

          if (node['children'] is List && (node['children'] as List).isNotEmpty) {
            parseNodes(node['children'] as List);
          }
        }
      }
    }

    parseNodes(rawList);
    return categories;
  }

  List<Product> searchProducts(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return allProducts;

    return allProducts.where((p) {
      final nameMatch = p.name.toLowerCase().contains(clean);
      final brandMatch = p.brand.toLowerCase().contains(clean);
      final catMatch = p.category.toLowerCase().contains(clean);
      final specsMatch = p.specs.any((s) => s.toLowerCase().contains(clean));
      return nameMatch || brandMatch || catMatch || specsMatch;
    }).toList();
  }

  List<Product> filterProducts(String filter) {
    if (filter == 'Tất cả' || filter.trim().isEmpty) return allProducts;

    final cleanFilter = filter.toLowerCase().replaceAll(RegExp(r'^/'), '').trim();

    return allProducts.where((product) {
      if (product.categorySlugs.any((s) => s.toLowerCase() == cleanFilter)) return true;

      final filterId = int.tryParse(cleanFilter);
      if (filterId != null && product.categoryIds.contains(filterId)) return true;

      if (product.category.toLowerCase() == cleanFilter ||
          product.category.toLowerCase().contains(cleanFilter)) {
        return true;
      }
      if (product.brand.toLowerCase() == cleanFilter) return true;

      final compType = product.componentType?.toLowerCase() ?? '';
      if (compType == cleanFilter) return true;

      if (cleanFilter == 'main' || cleanFilter == 'mainboard') {
        return compType == 'mainboard' || product.category.toLowerCase().contains('main');
      }
      if (cleanFilter == 'gpu' || cleanFilter == 'vga') {
        return compType == 'gpu' || product.category.toLowerCase().contains('vga') || product.category.toLowerCase().contains('card');
      }
      if (cleanFilter == 'cpu') {
        return compType == 'cpu' || product.category.toLowerCase().contains('cpu');
      }
      if (cleanFilter == 'ram') {
        return compType == 'ram' || product.category.toLowerCase().contains('ram');
      }
      if (cleanFilter == 'ssd' || cleanFilter == 'storage' || cleanFilter == 'hdd') {
        return compType == 'storage' || product.category.toLowerCase().contains('ổ cứng');
      }
      if (cleanFilter == 'psu' || cleanFilter == 'power') {
        return compType == 'psu' || product.category.toLowerCase().contains('nguồn');
      }
      if (cleanFilter == 'case') {
        return compType == 'case' || product.category.toLowerCase().contains('case') || product.category.toLowerCase().contains('vỏ');
      }
      if (cleanFilter == 'cooler' || cleanFilter == 'cooling') {
        return compType == 'cooler' || product.category.toLowerCase().contains('tản');
      }
      if (cleanFilter == 'laptop' || cleanFilter == 'laptop-gaming') {
        return compType == 'laptop' || product.category.toLowerCase().contains('laptop');
      }
      if (cleanFilter == 'pc-part') {
        return ['cpu', 'mainboard', 'ram', 'gpu', 'storage', 'psu', 'cooler', 'case'].contains(compType);
      }
      if (cleanFilter == 'pc-ai') {
        return product.name.toLowerCase().contains('ai') || product.specs.any((s) => s.toLowerCase().contains('ai'));
      }
      if (cleanFilter == 'pc-gaming') {
        return product.category.toLowerCase().contains('gaming') || product.name.toLowerCase().contains('gaming');
      }
      if (cleanFilter == 'pc') {
        return compType == 'pc_prebuilt' || product.category.toLowerCase().contains('pc');
      }
      if (cleanFilter == 'monitor' || cleanFilter == 'màn hình') {
        return compType == 'monitor';
      }
      if (cleanFilter == 'gear') {
        return compType == 'gear';
      }
      if (cleanFilter == 'asus') {
        return product.brand.toLowerCase() == 'asus';
      }

      return product.specs.any((s) => s.toLowerCase().contains(cleanFilter));
    }).toList();
  }

  Future<List<Product>> queryApiProducts({
    String? search,
    int? categoryId,
    int? brandId,
  }) async {
    try {
      final rawList = await _coreCatalog.getRawProducts(
        search: search,
        categoryId: categoryId,
        brandId: brandId,
      );
      if (rawList.isNotEmpty) {
        final mapped = <Product>[];
        for (final p in rawList) {
          try {
            mapped.add(mapJsonToProduct(p));
          } catch (_) {}
        }
        if (mapped.isNotEmpty) {
          _remoteProducts = mapped;
          notifyListeners();
          return mapped;
        }
      }
    } catch (_) {}
    return search != null
        ? searchProducts(search)
        : (categoryId != null ? filterProducts(categoryId.toString()) : allProducts);
  }

  static Product mapJsonToProduct(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final productName = json['productName']?.toString() ?? 'Sản phẩm JOPPE';
    final brandName = json['brandName']?.toString();
    final warrantyMonths = (json['warrantyMonths'] as num?)?.toInt() ?? 12;
    final totalStock = (json['totalStock'] as num?)?.toInt() ?? 10;
    String rawThumbnail = json['thumbnailUrl']?.toString() ?? '';

    String categoryName = 'Laptop Gaming';
    final categorySlugs = <String>[];
    final categoryIds = <int>[];
    if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
      final categoriesList = json['categories'] as List;
      dynamic primary;
      for (final c in categoriesList) {
        if (c is Map) {
          final s = c['slug']?.toString();
          if (s != null && s.isNotEmpty) categorySlugs.add(s);
          final cid = (c['id'] as num?)?.toInt();
          if (cid != null) categoryIds.add(cid);

          if (c['isPrimary'] == true) {
            primary = c;
          }
        }
      }
      primary ??= categoriesList.first;
      if (primary is Map && primary['categoryName'] != null) {
        categoryName = primary['categoryName'].toString();
      }
    }

    String brand = brandName ?? 'ASUS';
    if (brandName == null && json['categories'] is List) {
      for (final cat in json['categories'] as List) {
        if (cat is Map && cat['categoryName'] != null) {
          final catName = cat['categoryName'].toString().toUpperCase();
          if (catName.contains('ASUS')) brand = 'ASUS';
          if (catName.contains('GIGABYTE')) brand = 'GIGABYTE';
          if (catName.contains('MSI')) brand = 'MSI';
          if (catName.contains('INTEL')) brand = 'INTEL';
          if (catName.contains('AMD')) brand = 'AMD';
        }
      }
    }

    double calculatedPrice = 0.0;
    double? calculatedOriginalPrice;
    final specsList = <String>[];
    final techSpecsMap = <String, String>{};
    final albumUrls = <String>[];
    String? versionCode = json['versionCode']?.toString();
    String? variantCode;
    String? compositeSlug;
    String? variantId;

    if (json['variants'] is List && (json['variants'] as List).isNotEmpty) {
      final variants = json['variants'] as List;

      for (final rawV in variants) {
        if (rawV is Map) {
          final vMap = Map<String, dynamic>.from(rawV);
          final vThumb = vMap['thumbnailUrl']?.toString();
          if (rawThumbnail.isEmpty && vThumb != null && vThumb.trim().isNotEmpty && vThumb.trim() != 'null') {
            rawThumbnail = vThumb.trim();
          }

          if (vMap['albumUrls'] is List) {
            for (final a in vMap['albumUrls'] as List) {
              if (a != null && a.toString().trim().isNotEmpty && a.toString().trim() != 'null') {
                final resolved = AppApiClient.instance.resolveMediaUrl(a.toString());
                if (!albumUrls.contains(resolved)) {
                  albumUrls.add(resolved);
                }
              }
            }
          }
        }
      }

      if (rawThumbnail.isEmpty && albumUrls.isNotEmpty) {
        rawThumbnail = albumUrls.first;
      }

      final firstRaw = variants.first;
      final firstVariant = firstRaw is Map ? Map<String, dynamic>.from(firstRaw) : null;

      if (firstVariant != null) {
        variantId = firstVariant['id']?.toString();
        versionCode ??= firstVariant['versionCode']?.toString();
        variantCode = firstVariant['variantCode']?.toString();
        compositeSlug = firstVariant['compositeSlug']?.toString() ??
            (json['slug'] != null && variantCode != null ? '${json['slug']}-$variantCode' : null);

        final listPrice = (firstVariant['listPrice'] as num?)?.toDouble() ?? 0.0;
        final salePrice = (firstVariant['salePrice'] as num?)?.toDouble() ?? 0.0;

        if (salePrice > 0) {
          calculatedPrice = salePrice;
          if (listPrice > salePrice) calculatedOriginalPrice = listPrice;
        } else if (listPrice > 0) {
          calculatedPrice = listPrice;
        }

        final attrRaw = firstVariant['attributes'];
        if (attrRaw != null) {
          try {
            Map<String, dynamic> attrMap = {};
            if (attrRaw is Map) {
              attrMap = Map<String, dynamic>.from(attrRaw);
            } else if (attrRaw is String && attrRaw.trim().isNotEmpty) {
              final decoded = jsonDecode(attrRaw);
              if (decoded is Map) {
                attrMap = Map<String, dynamic>.from(decoded);
              }
            }

            attrMap.forEach((key, val) {
              final strVal = val.toString();
              techSpecsMap[key] = strVal;
              specsList.add('$key: $strVal');
            });
          } catch (_) {}
        }
      }
    }

    final resolvedImageUrl = rawThumbnail.trim().isNotEmpty && rawThumbnail.trim() != 'null'
        ? AppApiClient.instance.resolveMediaUrl(rawThumbnail.trim())
        : '';

    if (calculatedPrice <= 0) {
      final minPrice = (json['minPrice'] as num?)?.toDouble() ?? 0.0;
      if (minPrice > 0) {
        calculatedPrice = minPrice;
      } else {
        calculatedPrice = 44990000.0;
      }
    }

    final specsRaw = json['specifications'];
    if (specsRaw != null && specsRaw is String && specsRaw.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(specsRaw);
        if (parsed is Map) {
          parsed.forEach((k, v) {
            techSpecsMap[k.toString()] = v.toString();
            if (!specsList.any((s) => s.startsWith('${k.toString()}:'))) {
              specsList.add('${k.toString()}: ${v.toString()}');
            }
          });
        }
      } catch (_) {
        if (specsList.isEmpty) {
          specsList.addAll(specsRaw.split('\n').where((s) => s.trim().isNotEmpty));
        }
      }
    }

    final lowerName = productName.toLowerCase();
    final lowerCat = categoryName.toLowerCase();
    String? compType;

    if (lowerCat.contains('laptop') || lowerName.contains('laptop') || lowerName.contains('strix')) {
      compType = 'laptop';
    } else if (lowerCat.contains('cpu') || lowerName.contains('core') || lowerName.contains('ryzen')) {
      compType = 'cpu';
    } else if (lowerCat.contains('vga') || lowerName.contains('rtx') || lowerName.contains('rx ') || lowerCat.contains('card')) {
      compType = 'gpu';
    } else if (lowerCat.contains('mainboard') || lowerCat.contains('bo mạch')) {
      compType = 'mainboard';
    } else if (lowerCat.contains('ram') || lowerCat.contains('bộ nhớ trong')) {
      compType = 'ram';
    } else if (lowerCat.contains('ssd') || lowerCat.contains('ổ cứng') || lowerCat.contains('storage')) {
      compType = 'storage';
    } else if (lowerCat.contains('nguồn') || lowerCat.contains('psu')) {
      compType = 'psu';
    } else if (lowerCat.contains('tản') || lowerCat.contains('cooler')) {
      compType = 'cooler';
    } else if (lowerCat.contains('case') || lowerCat.contains('vỏ')) {
      compType = 'case';
    } else if (lowerCat.contains('màn hình') || lowerCat.contains('monitor')) {
      compType = 'monitor';
    } else if (lowerCat.contains('gear') || lowerCat.contains('chuột') || lowerCat.contains('phím')) {
      compType = 'gear';
    } else {
      compType = 'pc_prebuilt';
    }

    return Product(
      id: id,
      variantId: variantId,
      name: productName,
      description: json['description']?.toString() ??
          json['shortDescription']?.toString() ??
          'Sản phẩm công nghệ cao cấp chính hãng phân phối tại hệ thống Joppe Store.',
      price: calculatedPrice,
      originalPrice: calculatedOriginalPrice,
      imageUrl: resolvedImageUrl,
      category: categoryName,
      brand: brand,
      warrantyMonths: warrantyMonths,
      specs: specsList.isNotEmpty ? specsList : ['Bảo hành $warrantyMonths tháng', 'Chính hãng $brand'],
      technicalSpecs: techSpecsMap,
      componentType: compType,
      categorySlugs: categorySlugs,
      categoryIds: categoryIds,
      inStock: totalStock > 0,
      isFeatured: true,
      rating: 4.9,
      reviewCount: 38,
      versionCode: versionCode,
      variantCode: variantCode,
      compositeSlug: compositeSlug,
      albumUrls: albumUrls,
    );
  }

  static ({
    bool isBuildComponent,
    String canonicalId,
    int displayOrder,
    String canonicalName,
    String shortName,
    String description,
    IconData icon,
  }) _classifyCategory(String slug, String name) {
    final s = slug.toLowerCase().trim();
    final n = name.toLowerCase().trim();

    if (s == 'cpu' || n == 'cpu' || n.contains('vi xử lý')) {
      return (
        isBuildComponent: true,
        canonicalId: 'cpu',
        displayOrder: 1,
        canonicalName: 'CPU - Bộ Vi Xử Lý',
        shortName: 'CPU',
        description: 'Bộ vi xử lý trung tâm (Intel / AMD)',
        icon: Icons.memory,
      );
    }
    if (s == 'main' || s == 'mainboard' || n.contains('mainboard') || n.contains('bo mạch')) {
      return (
        isBuildComponent: true,
        canonicalId: 'mainboard',
        displayOrder: 2,
        canonicalName: 'Mainboard - Bo Mạch Chủ',
        shortName: 'Mainboard',
        description: 'Bo mạch chủ (Z890, B760, X870...)',
        icon: Icons.developer_board,
      );
    }
    if (s == 'ram' || n.contains('ram') || n.contains('bộ nhớ trong')) {
      return (
        isBuildComponent: true,
        canonicalId: 'ram',
        displayOrder: 3,
        canonicalName: 'RAM - Bộ Nhớ Trong',
        shortName: 'RAM',
        description: 'Bộ nhớ RAM DDR5 / DDR4',
        icon: Icons.storage,
      );
    }
    if (s == 'gpu' || s == 'vga' || n.contains('gpu') || n.contains('vga') || n.contains('card đồ họa')) {
      return (
        isBuildComponent: true,
        canonicalId: 'gpu',
        displayOrder: 4,
        canonicalName: 'VGA - Card Đồ Họa',
        shortName: 'GPU',
        description: 'Card màn hình rời (RTX 40 / 50 Series)',
        icon: Icons.videogame_asset,
      );
    }
    if (s == 'storage' || s == 'ssd' || s == 'hdd' || n.contains('ổ cứng') || n.contains('ssd')) {
      return (
        isBuildComponent: true,
        canonicalId: 'storage',
        displayOrder: 5,
        canonicalName: 'SSD - Ổ Cứng NVMe',
        shortName: 'SSD',
        description: 'Ổ cứng SSD NVMe Gen4 / Gen5',
        icon: Icons.save,
      );
    }
    if (s == 'psu' || s == 'power' || n.contains('nguồn') || n.contains('psu')) {
      return (
        isBuildComponent: true,
        canonicalId: 'psu',
        displayOrder: 6,
        canonicalName: 'PSU - Nguồn Máy Tính',
        shortName: 'Nguồn',
        description: 'Nguồn công suất thực 80 Plus Gold',
        icon: Icons.power,
      );
    }
    if (s == 'cooling' || s == 'cooler' || n.contains('tản nhiệt') || n.contains('tản')) {
      return (
        isBuildComponent: true,
        canonicalId: 'cooler',
        displayOrder: 7,
        canonicalName: 'Cooler - Tản Nhiệt PC',
        shortName: 'Tản Nhiệt',
        description: 'Tản nhiệt nước AIO / Khí tháp',
        icon: Icons.ac_unit,
      );
    }
    if (s == 'case' || n.contains('case') || n.contains('vỏ máy') || n.contains('thùng máy')) {
      return (
        isBuildComponent: true,
        canonicalId: 'case',
        displayOrder: 8,
        canonicalName: 'Case - Vỏ Máy Tính',
        shortName: 'Case',
        description: 'Vỏ case bể cá / Kính cường lực',
        icon: Icons.aspect_ratio,
      );
    }

    return (
      isBuildComponent: false,
      canonicalId: slug.isNotEmpty ? slug : name.toLowerCase(),
      displayOrder: 100,
      canonicalName: name,
      shortName: name,
      description: 'Danh mục $name chính hãng tại JOPPE',
      icon: _getIconForCategory(slug, name),
    );
  }

  static IconData _getIconForCategory(String slug, String name) {
    final lower = (slug + name).toLowerCase();
    if (lower.contains('laptop')) return Icons.laptop_chromebook;
    if (lower.contains('gaming')) return Icons.sports_esports;
    if (lower.contains('asus')) return Icons.computer;
    if (lower.contains('pc')) return Icons.desktop_windows;
    if (lower.contains('cpu')) return Icons.memory;
    if (lower.contains('gpu') || lower.contains('vga')) return Icons.videogame_asset;
    if (lower.contains('mainboard')) return Icons.developer_board;
    if (lower.contains('màn hình') || lower.contains('monitor')) return Icons.tv;
    if (lower.contains('gear')) return Icons.keyboard;
    return Icons.devices;
  }

  static List<ComponentCategory> _getDefaultBuildSlots() {
    return _getDefaultApiCategories().where((c) => c.isRequiredForBuild).toList();
  }

  static List<CategoryNode> _getDefaultCategoryTree() {
    return [
      const CategoryNode(
        id: 3,
        categoryName: 'Asus',
        slug: 'asus',
        productCount: 1,
        children: [],
      ),
      const CategoryNode(
        id: 1,
        categoryName: 'Laptop',
        slug: 'laptop',
        productCount: 0,
        children: [
          CategoryNode(
            id: 2,
            parentId: 1,
            categoryName: 'Gaming',
            slug: 'laptop-gaming',
            productCount: 1,
            children: [],
          ),
        ],
      ),
      const CategoryNode(
        id: 4,
        categoryName: 'PC',
        slug: 'pc',
        productCount: 0,
        children: [
          CategoryNode(
            id: 6,
            parentId: 4,
            categoryName: 'PC AI',
            slug: 'pc-ai',
            productCount: 0,
            children: [],
          ),
          CategoryNode(
            id: 7,
            parentId: 4,
            categoryName: 'PC Gaming',
            slug: 'pc-gaming',
            productCount: 0,
            children: [],
          ),
        ],
      ),
      const CategoryNode(
        id: 5,
        categoryName: 'Linh Kiện',
        slug: 'pc-part',
        productCount: 0,
        children: [
          CategoryNode(
            id: 8,
            parentId: 5,
            categoryName: 'CPU',
            slug: 'cpu',
            productCount: 0,
            children: [],
          ),
          CategoryNode(
            id: 9,
            parentId: 5,
            categoryName: 'RAM',
            slug: 'ram',
            productCount: 0,
            children: [],
          ),
          CategoryNode(
            id: 10,
            parentId: 5,
            categoryName: 'Mainboard',
            slug: 'main',
            productCount: 0,
            children: [],
          ),
          CategoryNode(
            id: 11,
            parentId: 5,
            categoryName: 'GPU',
            slug: 'gpu',
            productCount: 0,
            children: [],
          ),
          CategoryNode(
            id: 12,
            parentId: 5,
            categoryName: 'Tản Nhiệt',
            slug: 'cooling',
            productCount: 0,
            children: [],
          ),
        ],
      ),
    ];
  }

  static List<Product> _getDefaultApiProducts() {
    return [
      mapJsonToProduct({
        'id': '7ac13811-39f1-4509-a86f-e69c90e91fca',
        'productName': '2025 ROG Strix G16',
        'versionCode': '2025-ROG-Strix-G16',
        'slug': '2025-asus-rog-strix-g16',
        'brandId': 3,
        'brandName': 'ASUS',
        'isActive': true,
        'categories': [
          {'id': 3, 'categoryName': 'Asus', 'slug': 'asus', 'isPrimary': true},
          {'id': 2, 'categoryName': 'Gaming', 'slug': 'laptop-gaming', 'isPrimary': false}
        ],
        'variants': [
          {
            'id': 'd0639584-e26e-4e2a-9b25-3d70c1559d82',
            'sku': 'G615JMR-S5155W',
            'versionCode': '2025-ROG-Strix-G16',
            'variantCode': 'G615JMR-S5155W',
            'variantName': '2025 ROG Strix G16 | G615JMR-S5155W | i7-14650HX | RTX 5060 | 32GB | 1TB',
            'compositeSlug': '2025-asus-rog-strix-g16-g615jmr-s5155w',
            'thumbnailUrl': 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&w=800&q=80',
            'albumUrls': [
              'https://images.unsplash.com/photo-1603302576837-37561b2e2302?auto=format&fit=crop&w=800&q=80',
              'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?auto=format&fit=crop&w=800&q=80',
              'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?auto=format&fit=crop&w=800&q=80'
            ],
            'attributes': '{"CPU": "Core i7", "GPU": "RTX 5060", "RAM": "32 GB", "Color": "Eclipse Grey", "Storage": "1TB SSD"}',
            'listPrice': 49990000.00,
            'salePrice': 44990000.00,
            'quantityOnHand': 19,
            'availableQuantity': 10,
            'weightGram': 2500.00,
            'isActive': true
          }
        ],
        'minPrice': 44990000.00,
        'maxPrice': 49990000.00,
        'totalStock': 39
      }),
    ];
  }

  static List<ComponentCategory> _getDefaultApiCategories() {
    return const [
      ComponentCategory(
        id: 'cpu',
        name: 'CPU - Bộ Vi Xử Lý',
        shortName: 'CPU',
        description: 'Bộ vi xử lý trung tâm (Intel / AMD)',
        icon: Icons.memory,
        isRequiredForBuild: true,
        displayOrder: 1,
        slug: 'cpu',
      ),
      ComponentCategory(
        id: 'mainboard',
        name: 'Mainboard - Bo Mạch Chủ',
        shortName: 'Mainboard',
        description: 'Bo mạch chủ (Z890, B760, X870...)',
        icon: Icons.developer_board,
        isRequiredForBuild: true,
        displayOrder: 2,
        slug: 'main',
      ),
      ComponentCategory(
        id: 'ram',
        name: 'RAM - Bộ Nhớ Trong',
        shortName: 'RAM',
        description: 'Bộ nhớ RAM DDR5 / DDR4',
        icon: Icons.storage,
        isRequiredForBuild: true,
        displayOrder: 3,
        slug: 'ram',
      ),
      ComponentCategory(
        id: 'gpu',
        name: 'VGA - Card Đồ Họa',
        shortName: 'GPU',
        description: 'Card màn hình rời (RTX 40 / 50 Series)',
        icon: Icons.videogame_asset,
        isRequiredForBuild: true,
        displayOrder: 4,
        slug: 'gpu',
      ),
      ComponentCategory(
        id: 'storage',
        name: 'SSD - Ổ Cứng NVMe',
        shortName: 'SSD',
        description: 'Ổ cứng SSD NVMe Gen4 / Gen5',
        icon: Icons.save,
        isRequiredForBuild: true,
        displayOrder: 5,
        slug: 'storage',
      ),
      ComponentCategory(
        id: 'psu',
        name: 'PSU - Nguồn Máy Tính',
        shortName: 'Nguồn',
        description: 'Nguồn công suất thực 80 Plus Gold',
        icon: Icons.power,
        isRequiredForBuild: true,
        displayOrder: 6,
        slug: 'psu',
      ),
      ComponentCategory(
        id: 'cooler',
        name: 'Cooler - Tản Nhiệt PC',
        shortName: 'Tản Nhiệt',
        description: 'Tản nhiệt nước AIO / Khí tháp',
        icon: Icons.ac_unit,
        isRequiredForBuild: true,
        displayOrder: 7,
        slug: 'cooling',
      ),
      ComponentCategory(
        id: 'case',
        name: 'Case - Vỏ Máy Tính',
        shortName: 'Case',
        description: 'Vỏ case bể cá / Kính cường lực',
        icon: Icons.aspect_ratio,
        isRequiredForBuild: true,
        displayOrder: 8,
        slug: 'case',
      ),
      ComponentCategory(
        id: 'laptop',
        name: 'Laptop Gaming',
        shortName: 'Laptop',
        description: 'Laptop Gaming cấu hình cao',
        icon: Icons.laptop_chromebook,
        isRequiredForBuild: false,
        displayOrder: 9,
        slug: 'laptop-gaming',
      ),
      ComponentCategory(
        id: 'asus',
        name: 'Asus',
        shortName: 'Asus',
        description: 'Sản phẩm Asus chính hãng',
        icon: Icons.computer,
        isRequiredForBuild: false,
        displayOrder: 10,
        slug: 'asus',
      ),
    ];
  }

  @visibleForTesting
  void setRemoteProductsForTesting(List<Product> products) {
    _remoteProducts = products;
    notifyListeners();
  }

  @visibleForTesting
  void setRemoteCategoriesForTesting(List<ComponentCategory> categories) {
    _remoteCategories = categories;
    notifyListeners();
  }

  @visibleForTesting
  void setRemoteCategoryTreeForTesting(List<CategoryNode> tree) {
    _remoteCategoryTree = tree;
    notifyListeners();
  }
}
