package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public record CreateProductRequest(
        @NotBlank(message = "Product name is required")
        @Size(max = 255)
        String productName,

        @Size(max = 255)
        String slug,

        Integer brandId,

        List<Integer> categoryIds,

        Integer primaryCategoryId,

        String shortDescription,

        String description,

        String specifications,

        Integer warrantyMonths,

        String thumbnailUrl,

        Boolean isActive,

        // Optional default initial variant fields
        String sku,
        BigDecimal listPrice,
        BigDecimal salePrice,
        Integer stockQuantity
) {}
