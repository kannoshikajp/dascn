package joppe.backend.domain.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record ReceiptItemResponse(
        UUID id,
        UUID variantId,
        String productName,
        String variantName,
        String sku,
        String thumbnailUrl,
        Integer quantity,
        BigDecimal importPrice,
        BigDecimal subtotal
) {
}
