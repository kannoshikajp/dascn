package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public record CreateProductRequest(
        @NotBlank(message = "Product name is required")
        @Size(max = 255)
        String productName,

        @NotBlank(message = "SKU is required")
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

        String thumbnailUrl,
        String description,
        String attributes,
        BigDecimal listPrice,
        BigDecimal salePrice,
        Integer stockQuantity
) {}
