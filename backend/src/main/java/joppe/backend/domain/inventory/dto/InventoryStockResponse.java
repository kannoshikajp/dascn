package joppe.backend.domain.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record InventoryStockResponse(
        UUID variantId,
        UUID productId,
        String productName,
        String variantName,
        String sku,
        String variantCode,
        String thumbnailUrl,
        BigDecimal salePrice,
        BigDecimal listPrice,
        Integer quantityOnHand,
        Integer quantityReserved,
        Integer stockAvailable,
        Integer reorderLevel,
        Boolean isLowStock,
        Boolean isOutOfStock
) {
}
