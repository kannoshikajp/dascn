class RevenueSummaryModel {
  final double totalRevenue;
  final double pendingRevenue;
  final int totalOrders;
  final int pendingOrders;

  const RevenueSummaryModel({
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.totalOrders,
    required this.pendingOrders,
  });

  factory RevenueSummaryModel.fromJson(Map<String, dynamic> json) {
    return RevenueSummaryModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingRevenue: (json['pendingRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailySalesPointModel {
  final String date;
  final String dateLabel;
  final int orderCount;
  final double totalRevenue;

  const DailySalesPointModel({
    required this.date,
    required this.dateLabel,
    required this.orderCount,
    required this.totalRevenue,
  });

  factory DailySalesPointModel.fromJson(Map<String, dynamic> json) {
    return DailySalesPointModel(
      date: json['date'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InventoryHealthSummaryModel {
  final int totalProducts;
  final int activeProducts;
  final int healthyCount;
  final int lowStockCount;
  final int outOfStockCount;

  const InventoryHealthSummaryModel({
    required this.totalProducts,
    required this.activeProducts,
    required this.healthyCount,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  factory InventoryHealthSummaryModel.fromJson(Map<String, dynamic> json) {
    return InventoryHealthSummaryModel(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      activeProducts: (json['activeProducts'] as num?)?.toInt() ?? 0,
      healthyCount: (json['healthyCount'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['lowStockCount'] as num?)?.toInt() ?? 0,
      outOfStockCount: (json['outOfStockCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsOverviewModel {
  final RevenueSummaryModel revenueSummary;
  final List<DailySalesPointModel> salesTrend;
  final InventoryHealthSummaryModel inventoryHealth;

  const AnalyticsOverviewModel({
    required this.revenueSummary,
    required this.salesTrend,
    required this.inventoryHealth,
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewModel(
      revenueSummary: RevenueSummaryModel.fromJson(
        (json['revenueSummary'] as Map<String, dynamic>?) ?? {},
      ),
      salesTrend: ((json['salesTrend'] as List<dynamic>?) ?? [])
          .map((item) => DailySalesPointModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      inventoryHealth: InventoryHealthSummaryModel.fromJson(
        (json['inventoryHealth'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}
