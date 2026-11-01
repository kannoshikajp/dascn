package joppe.backend.domain.cart;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import joppe.backend.domain.cart.dto.AddToCartRequest;
import joppe.backend.domain.cart.dto.CartResponse;
import joppe.backend.domain.cart.dto.MergeCartRequest;
import joppe.backend.domain.cart.dto.UpdateCartQuantityRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
@Tag(name = "Shopping Cart", description = "Endpoints for managing customer shopping cart")
@PreAuthorize("hasAuthority('CART_MANAGE')")
public class CartController {

    private final CartService cartService;

    private UUID getUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    @GetMapping
    @Operation(summary = "Get current authenticated user cart with full variant details and pricing")
    public CartResponse getCart(@AuthenticationPrincipal Jwt jwt) {
        return cartService.getCart(getUserId(jwt));
    }

    @PostMapping("/items")
    @Operation(summary = "Add an item variant to cart with availability and stock validation")
    public CartResponse addItem(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AddToCartRequest request) {
        return cartService.addItemToCart(getUserId(jwt), request);
    }

    @PutMapping("/items/{itemId}")
    @Operation(summary = "Update quantity of a line item in cart (quantity=0 removes item)")
    public CartResponse updateItemQuantity(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID itemId,
            @Valid @RequestBody UpdateCartQuantityRequest request) {
        return cartService.updateItemQuantity(getUserId(jwt), itemId, request);
    }

    @DeleteMapping("/items/{itemId}")
    @Operation(summary = "Remove an item from cart")
    public CartResponse removeItem(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID itemId) {
        return cartService.removeItemFromCart(getUserId(jwt), itemId);
    }

    @DeleteMapping
    @Operation(summary = "Clear all items from cart")
    public CartResponse clearCart(@AuthenticationPrincipal Jwt jwt) {
        return cartService.clearUserCart(getUserId(jwt));
    }

    @PostMapping("/merge")
    @Operation(summary = "Merge guest cart items into authenticated user cart on login")
    public CartResponse mergeCart(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody MergeCartRequest request) {
        return cartService.mergeCart(getUserId(jwt), request);
    }
}
