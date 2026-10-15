package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public record CreateVariantRequest(
        @NotBlank(message = "SKU is required")
        @Size(max = 100)
        String sku,

        @NotBlank(message = "Variant name is required")
        @Size(max = 255)
        String variantName,

        String attributes,

        BigDecimal listPrice,

        BigDecimal salePrice,

        Integer quantityOnHand,

        Integer reorderLevel,

        BigDecimal weightGram,

        Boolean isActive
) {}
