package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public record UpdateProductRequest(
        @NotBlank(message = "Product name is required")
        @Size(max = 255)
        String productName,

        @Size(max = 100)
        String sku,

        @Size(max = 100)
        String parentSku,

        @Size(max = 255)
        String slug,

        Integer brandId,

        List<Integer> categoryIds,

        Integer primaryCategoryId,

        Boolean isActive,

        BigDecimal listPrice,
        BigDecimal salePrice,
        Integer stockQuantity,
        String thumbnailUrl,
        String description
) {
    public UpdateProductRequest(
            String productName,
            String sku,
            String parentSku,
            String slug,
            Integer brandId,
            List<Integer> categoryIds,
            Integer primaryCategoryId,
            Boolean isActive
    ) {
        this(productName, sku, parentSku, slug, brandId, categoryIds, primaryCategoryId, isActive, null, null, null, null, null);
    }
}
