package joppe.backend.domain.cart.dto;

import java.math.BigDecimal;
import java.util.List;

public record CartResponse(
        List<CartItemResponse> items,
        int totalItems,
        BigDecimal subtotalAmount
) {
    public static CartResponse empty() {
        return new CartResponse(List.of(), 0, BigDecimal.ZERO);
    }
}
