package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import joppe.backend.admin.dto.AnalyticsOverviewResponse;
import joppe.backend.admin.service.AdminAnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/analytics")
@RequiredArgsConstructor
@Tag(name = "Admin - Analytics", description = "Dashboard KPI metrics, sales velocity, and inventory health aggregations")
public class AdminAnalyticsController {

    private final AdminAnalyticsService adminAnalyticsService;

    @GetMapping("/overview")
    @PreAuthorize("hasAnyAuthority('ORDER_MANAGE', 'CATALOG_READ', 'INVENTORY_READ', 'ROLE_ADMIN', 'ROLE_STAFF')")
    @Operation(summary = "Get aggregated store overview metrics, revenue summary, 7-day sales trend, and inventory status")
    public AnalyticsOverviewResponse getOverview() {
        return adminAnalyticsService.getOverview();
    }
}
