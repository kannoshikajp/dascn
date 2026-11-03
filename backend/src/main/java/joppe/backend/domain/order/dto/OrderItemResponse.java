package joppe.backend.domain.order.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record OrderItemResponse(
        UUID id,
        UUID variantId,
        String skuSnapshot,
        String productNameSnapshot,
        String variantNameSnapshot,
        Integer quantity,
        BigDecimal unitPrice,
        BigDecimal subtotal,
        Integer warrantyMonthsSnapshot,
        String thumbnailUrl,
        List<String> serialNumbers
) {
    public OrderItemResponse(
            UUID id,
            UUID variantId,
            String skuSnapshot,
            String productNameSnapshot,
            String variantNameSnapshot,
            Integer quantity,
            BigDecimal unitPrice,
            BigDecimal subtotal,
            Integer warrantyMonthsSnapshot,
            String thumbnailUrl
    ) {
        this(id, variantId, skuSnapshot, productNameSnapshot, variantNameSnapshot, quantity, unitPrice, subtotal, warrantyMonthsSnapshot, thumbnailUrl, List.of());
    }
}
