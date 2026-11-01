package joppe.backend.domain.order.dto;

import java.math.BigDecimal;
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
        String thumbnailUrl
) {
}
