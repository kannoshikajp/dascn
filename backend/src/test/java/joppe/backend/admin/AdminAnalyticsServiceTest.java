package joppe.backend.admin;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.dto.AnalyticsOverviewResponse;
import joppe.backend.admin.service.AdminAnalyticsService;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariantRepository;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminAnalyticsServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ProductVariantRepository productVariantRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private AdminAnalyticsService adminAnalyticsService;

    @Test
    void getOverview_aggregatesDataCorrectly() {
        when(orderRepository.calculateTotalRevenue()).thenReturn(new BigDecimal("150000000"));
        when(orderRepository.calculatePendingRevenue()).thenReturn(new BigDecimal("12000000"));
        when(orderRepository.count()).thenReturn(25L);
        when(orderRepository.countPendingOrders()).thenReturn(3L);

        Order sampleOrder = Order.builder()
                .id(UUID.randomUUID())
                .orderCode("ORD-20261029-001")
                .recipientName("Tran Van B")
                .finalAmount(new BigDecimal("15000000"))
                .orderStatus("COMPLETED")
                .paymentStatus("PAID")
                .createdAt(OffsetDateTime.now())
                .build();

        when(orderRepository.findOrdersSince(any(OffsetDateTime.class))).thenReturn(List.of(sampleOrder));
        when(orderRepository.findTop5ByOrderByCreatedAtDesc()).thenReturn(List.of(sampleOrder));

        when(productRepository.count()).thenReturn(100L);
        when(productRepository.countByIsActiveTrue()).thenReturn(95L);

        when(productVariantRepository.countHealthyStockVariants()).thenReturn(80L);
        when(productVariantRepository.countLowStockVariants()).thenReturn(15L);
        when(productVariantRepository.countOutOfStockVariants()).thenReturn(5L);

        when(userRepository.count()).thenReturn(50L);
        when(userRepository.countByIsActiveTrue()).thenReturn(48L);

        AnalyticsOverviewResponse res = adminAnalyticsService.getOverview();

        assertThat(res).isNotNull();

        // Revenue checks
        assertThat(res.revenueSummary().totalRevenue()).isEqualByComparingTo("150000000");
        assertThat(res.revenueSummary().pendingRevenue()).isEqualByComparingTo("12000000");
        assertThat(res.revenueSummary().totalOrders()).isEqualTo(25);
        assertThat(res.revenueSummary().pendingOrders()).isEqualTo(3);

        // Sales trend: 7 daily points
        assertThat(res.salesTrend()).hasSize(7);

        // Inventory health
        assertThat(res.inventoryHealth().totalProducts()).isEqualTo(100);
        assertThat(res.inventoryHealth().activeProducts()).isEqualTo(95);
        assertThat(res.inventoryHealth().healthyCount()).isEqualTo(80);
        assertThat(res.inventoryHealth().lowStockCount()).isEqualTo(15);
        assertThat(res.inventoryHealth().outOfStockCount()).isEqualTo(5);

        // Recent orders
        assertThat(res.recentOrders()).hasSize(1);
        assertThat(res.recentOrders().get(0).orderCode()).isEqualTo("ORD-20261029-001");

        // User metrics
        assertThat(res.userMetrics().totalUsers()).isEqualTo(50);
        assertThat(res.userMetrics().activeUsers()).isEqualTo(48);
    }
}
