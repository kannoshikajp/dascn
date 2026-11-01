package joppe.backend.domain.order;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.domain.order.dto.CheckoutRequest;
import joppe.backend.domain.order.dto.OrderResponse;
import joppe.backend.domain.order.dto.OrderSummaryResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
@Tag(name = "Orders (Customer)", description = "Customer endpoints for checkout, order history, and cancellation")
public class OrderController {

    private final OrderService orderService;

    private UUID getUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    @PostMapping("/checkout")
    @PreAuthorize("hasAuthority('ORDER_CREATE')")
    @Operation(summary = "Place order from current cart or specified variant items with atomic stock reservation")
    public ResponseEntity<OrderResponse> checkout(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CheckoutRequest request) {
        OrderResponse response = orderService.checkout(getUserId(jwt), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/my")
    @PreAuthorize("hasAuthority('ORDER_READ_OWN')")
    @Operation(summary = "Get list of orders placed by authenticated customer")
    public List<OrderSummaryResponse> getMyOrders(@AuthenticationPrincipal Jwt jwt) {
        return orderService.getMyOrders(getUserId(jwt));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ORDER_READ_OWN')")
    @Operation(summary = "Get detailed order information by ID for authenticated customer")
    public OrderResponse getOrderById(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        return orderService.getCustomerOrder(getUserId(jwt), id);
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAuthority('ORDER_READ_OWN')")
    @Operation(summary = "Cancel a PENDING order and automatically release reserved variant stock")
    public OrderResponse cancelOrder(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        return orderService.cancelOrder(getUserId(jwt), id);
    }
}
