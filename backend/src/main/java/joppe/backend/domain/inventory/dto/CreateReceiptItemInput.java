package joppe.backend.domain.inventory.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.UUID;

public record CreateReceiptItemInput(
        @NotNull(message = "Variant ID is required")
        UUID variantId,

        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least 1")
        Integer quantity,

        @NotNull(message = "Import price is required")
        @DecimalMin(value = "0.0", message = "Import price cannot be negative")
        BigDecimal importPrice
) {
}
