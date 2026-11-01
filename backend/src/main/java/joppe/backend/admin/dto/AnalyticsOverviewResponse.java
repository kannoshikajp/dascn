package joppe.backend.admin.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record AnalyticsOverviewResponse(
        RevenueSummary revenueSummary,
        List<DailySalesPoint> salesTrend,
        InventoryHealthSummary inventoryHealth,
        List<RecentOrderDto> recentOrders,
        UserMetricSummary userMetrics
) {
    public record RevenueSummary(
            BigDecimal totalRevenue,
            BigDecimal pendingRevenue,
            long totalOrders,
            long pendingOrders
    ) {}

    public record DailySalesPoint(
            LocalDate date,
            String dateLabel,
            long orderCount,
            BigDecimal totalRevenue
    ) {}

    public record InventoryHealthSummary(
            long totalProducts,
            long activeProducts,
            long healthyCount,
            long lowStockCount,
            long outOfStockCount
    ) {}

    public record RecentOrderDto(
            UUID id,
            String orderCode,
            String recipientName,
            BigDecimal finalAmount,
            String orderStatus,
            String paymentStatus,
            String createdAt
    ) {}

    public record UserMetricSummary(
            long totalUsers,
            long activeUsers
    ) {}
}
