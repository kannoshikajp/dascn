package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record UpdateVariantRequest(
        @NotBlank(message = "SKU is required")
        @Size(max = 100)
        String sku,

        @NotBlank(message = "Variant name is required")
        @Size(max = 255)
        String variantName,

        String thumbnailUrl,

        String description,

        List<UUID> mediaIds,

        String attributes,

        BigDecimal listPrice,

        BigDecimal salePrice,

        Integer quantityOnHand,

        Integer reorderLevel,

        BigDecimal weightGram,

        Boolean isActive
) {}
