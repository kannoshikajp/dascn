package joppe.backend.domain.cart.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record CartItemResponse(
        UUID id,
        UUID variantId,
        UUID productId,
        String productName,
        String variantName,
        String sku,
        String variantCode,
        String compositeSlug,
        String thumbnailUrl,
        BigDecimal unitPrice,
        BigDecimal listPrice,
        Integer quantity,
        Integer stockAvailable,
        BigDecimal itemTotal
) {
}
