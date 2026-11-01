package joppe.backend.admin.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record ProductVariantSummary(
        UUID id,
        String sku,
        String parentSku,
        String variantName,
        String compositeSlug,
        String thumbnailUrl,
        String description,
        List<String> albumUrls,
        List<UUID> albumMediaIds,
        String attributes,
        BigDecimal listPrice,
        BigDecimal salePrice,
        Integer quantityOnHand,
        Integer quantityReserved,
        Integer availableQuantity,
        BigDecimal weightGram,
        Boolean isActive
) {}
