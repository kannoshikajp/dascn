package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.dto.CreateAdminOrderRequest;
import joppe.backend.admin.dto.ManualPaymentConfirmRequest;
import joppe.backend.admin.dto.UpdateOrderStatusRequest;
import joppe.backend.admin.dto.UpdatePaymentStatusRequest;
import joppe.backend.domain.order.OrderService;
import joppe.backend.domain.order.dto.OrderResponse;
import joppe.backend.domain.order.dto.OrderSummaryResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/orders")
@RequiredArgsConstructor
@Tag(name = "Admin - Orders", description = "Administrative endpoints for viewing and processing customer orders")
@PreAuthorize("hasAuthority('ORDER_MANAGE')")
public class AdminOrderController {

    private final OrderService orderService;

    private UUID getStaffUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    @PostMapping
    @Operation(summary = "Create order on behalf of customer / walk-in POS counter sale")
    public ResponseEntity<OrderResponse> createOrder(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateAdminOrderRequest request) {
        OrderResponse created = orderService.createAdminOrder(getStaffUserId(jwt), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping
    @Operation(summary = "List customer orders with optional filters (order status, payment status, keyword search)")
    public List<OrderSummaryResponse> listOrders(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String paymentStatus,
            @RequestParam(required = false) String search) {
        return orderService.listAdminOrders(status, paymentStatus, search);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get full order details including line items by ID")
    public OrderResponse getOrderById(@PathVariable UUID id) {
        return orderService.getAdminOrder(id);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update order status (e.g. PENDING, CONFIRMED, PACKING, SHIPPED, DELIVERED, CANCELLED)")
    public OrderResponse updateOrderStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateOrderStatusRequest request) {
        return orderService.updateOrderStatusByAdmin(id, request.status());
    }

    @PatchMapping("/{id}/payment-status")
    @Operation(summary = "Update payment status (e.g. UNPAID, PAID, REFUNDED)")
    public OrderResponse updatePaymentStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePaymentStatusRequest request) {
        return orderService.updatePaymentStatusByAdmin(id, request.paymentStatus());
    }

    @PostMapping("/{id}/manual-payment-confirm")
    @Operation(summary = "Manually confirm payment with bank transaction/slip reference and audit trail")
    public OrderResponse manualPaymentConfirm(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody ManualPaymentConfirmRequest request) {
        return orderService.manualPaymentConfirm(getStaffUserId(jwt), id, request);
    }
}
