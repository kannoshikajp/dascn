package joppe.backend.admin.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import joppe.backend.admin.dto.AnalyticsOverviewResponse;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.DailySalesPoint;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.InventoryHealthSummary;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.RecentOrderDto;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.RevenueSummary;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.UserMetricSummary;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AdminAnalyticsService {

    private final OrderRepository orderRepository;
    private final ProductRepository productRepository;
    private final ProductVariantRepository productVariantRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public AnalyticsOverviewResponse getOverview() {
        // 1. Revenue & Order Counts
        BigDecimal totalRevenue = orderRepository.calculateTotalRevenue();
        BigDecimal pendingRevenue = orderRepository.calculatePendingRevenue();
        long totalOrders = orderRepository.count();
        long pendingOrders = orderRepository.countPendingOrders();

        RevenueSummary revenueSummary = new RevenueSummary(
                totalRevenue != null ? totalRevenue : BigDecimal.ZERO,
                pendingRevenue != null ? pendingRevenue : BigDecimal.ZERO,
                totalOrders,
                pendingOrders
        );

        // 2. 7-Day Sales Trend
        OffsetDateTime sevenDaysAgo = OffsetDateTime.now().minusDays(6).withHour(0).withMinute(0).withSecond(0).withNano(0);
        List<Order> recent7DayOrders = orderRepository.findOrdersSince(sevenDaysAgo);

        Map<LocalDate, List<Order>> ordersByDay = new HashMap<>();
        for (Order o : recent7DayOrders) {
            if (o.getCreatedAt() != null) {
                LocalDate date = o.getCreatedAt().toLocalDate();
                ordersByDay.computeIfAbsent(date, k -> new ArrayList<>()).add(o);
            }
        }

        List<DailySalesPoint> salesTrend = new ArrayList<>();
        DateTimeFormatter labelFormatter = DateTimeFormatter.ofPattern("dd/MM");
        LocalDate today = LocalDate.now();

        for (int i = 6; i >= 0; i--) {
            LocalDate d = today.minusDays(i);
            List<Order> dayOrders = ordersByDay.getOrDefault(d, Collections.emptyList());
            long count = dayOrders.size();
            BigDecimal dayRevenue = dayOrders.stream()
                    .map(Order::getFinalAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            salesTrend.add(new DailySalesPoint(
                    d,
                    d.format(labelFormatter),
                    count,
                    dayRevenue
            ));
        }

        // 3. Inventory Health
        long totalProducts = productRepository.count();
        long activeProducts = productRepository.countByIsActiveTrue();
        long healthyCount = productVariantRepository.countHealthyStockVariants();
        long lowStockCount = productVariantRepository.countLowStockVariants();
        long outOfStockCount = productVariantRepository.countOutOfStockVariants();

        InventoryHealthSummary inventoryHealth = new InventoryHealthSummary(
                totalProducts,
                activeProducts,
                healthyCount,
                lowStockCount,
                outOfStockCount
        );

        // 4. Recent Orders (Top 5)
        List<Order> topOrders = orderRepository.findTop5ByOrderByCreatedAtDesc();
        List<RecentOrderDto> recentOrders = topOrders.stream()
                .map(o -> new RecentOrderDto(
                        o.getId(),
                        o.getOrderCode(),
                        o.getRecipientName(),
                        o.getFinalAmount(),
                        o.getOrderStatus(),
                        o.getPaymentStatus(),
                        o.getCreatedAt() != null ? o.getCreatedAt().toString() : null
                ))
                .toList();

        // 5. User Metrics
        long totalUsers = userRepository.count();
        long activeUsers = userRepository.countByIsActiveTrue();
        UserMetricSummary userMetrics = new UserMetricSummary(totalUsers, activeUsers);

        return new AnalyticsOverviewResponse(
                revenueSummary,
                salesTrend,
                inventoryHealth,
                recentOrders,
                userMetrics
        );
    }
}
