package joppe.backend.domain.order.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

public record CheckoutItemInput(
        @NotNull(message = "Variant ID is required")
        UUID variantId,

        @NotNull(message = "Quantity is required")
        @Min(value = 1, message = "Quantity must be at least 1")
        Integer quantity,

        List<String> serialNumbers
) {
    public CheckoutItemInput(UUID variantId, Integer quantity) {
        this(variantId, quantity, null);
    }
}
