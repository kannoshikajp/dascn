package joppe.backend.admin.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record ProductResponse(
        UUID id,
        String productName,
        String sku,
        String parentSku,
        String slug,
        Integer brandId,
        String brandName,
        Boolean isActive,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        List<ProductCategorySummary> categories,
        List<ProductVariantSummary> variants,
        BigDecimal minPrice,
        BigDecimal maxPrice,
        Integer totalStock
) {}
