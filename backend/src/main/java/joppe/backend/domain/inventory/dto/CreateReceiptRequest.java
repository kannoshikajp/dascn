package joppe.backend.domain.inventory.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;

public record CreateReceiptRequest(
        @NotNull(message = "Supplier ID is required")
        UUID supplierId,

        String receiptCode,

        Boolean completeImmediately,

        @NotEmpty(message = "Receipt must contain at least one item")
        List<@Valid CreateReceiptItemInput> items
) {
}
