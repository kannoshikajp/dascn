package joppe.backend.domain.inventory.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record UpdateStockRequest(
        @NotNull(message = "Quantity on hand is required")
        @Min(value = 0, message = "Quantity cannot be negative")
        Integer quantityOnHand,

        @NotNull(message = "Reorder level is required")
        @Min(value = 0, message = "Reorder level cannot be negative")
        Integer reorderLevel
) {
}
