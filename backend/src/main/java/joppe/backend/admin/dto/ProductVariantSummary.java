package joppe.backend.admin.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record ProductVariantSummary(
        UUID id,
        String sku,
        String variantName,
        BigDecimal listPrice,
        BigDecimal salePrice,
        Integer quantityOnHand,
        Integer quantityReserved,
        Integer availableQuantity,
        BigDecimal weightGram,
        Boolean isActive
) {}
