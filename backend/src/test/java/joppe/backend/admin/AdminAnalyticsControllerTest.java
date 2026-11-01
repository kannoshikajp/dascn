package joppe.backend.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.controller.AdminAnalyticsController;
import joppe.backend.admin.dto.AnalyticsOverviewResponse;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.DailySalesPoint;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.InventoryHealthSummary;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.RecentOrderDto;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.RevenueSummary;
import joppe.backend.admin.dto.AnalyticsOverviewResponse.UserMetricSummary;
import joppe.backend.admin.service.AdminAnalyticsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AdminAnalyticsControllerTest {

    private MockMvc mockMvc;

    @Mock
    private AdminAnalyticsService adminAnalyticsService;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new AdminAnalyticsController(adminAnalyticsService))
                .build();
    }

    @Test
    void getOverview_returnsHttp200AndAnalyticsPayload() throws Exception {
        AnalyticsOverviewResponse mockResponse = new AnalyticsOverviewResponse(
                new RevenueSummary(new BigDecimal("128000000"), new BigDecimal("15000000"), 42, 5),
                List.of(new DailySalesPoint(LocalDate.now(), "29/10", 8, new BigDecimal("24000000"))),
                new InventoryHealthSummary(184, 165, 150, 20, 14),
                List.of(new RecentOrderDto(UUID.randomUUID(), "ORD-20261029-001", "Nguyen Van A", new BigDecimal("12000000"), "COMPLETED", "PAID", "2026-10-29T10:00:00Z")),
                new UserMetricSummary(85, 80)
        );

        when(adminAnalyticsService.getOverview()).thenReturn(mockResponse);

        mockMvc.perform(get("/api/v1/admin/analytics/overview")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.revenueSummary.totalRevenue").value(128000000))
                .andExpect(jsonPath("$.revenueSummary.totalOrders").value(42))
                .andExpect(jsonPath("$.salesTrend[0].orderCount").value(8))
                .andExpect(jsonPath("$.inventoryHealth.totalProducts").value(184))
                .andExpect(jsonPath("$.recentOrders[0].orderCode").value("ORD-20261029-001"))
                .andExpect(jsonPath("$.userMetrics.totalUsers").value(85));
    }
}
