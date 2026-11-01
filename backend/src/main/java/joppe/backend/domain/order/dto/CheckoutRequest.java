package joppe.backend.domain.order.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;

public record CheckoutRequest(
        @NotBlank(message = "Recipient name is required")
        @Size(max = 150, message = "Recipient name must be at most 150 characters")
        String recipientName,

        @NotBlank(message = "Recipient phone number is required")
        @Size(max = 20, message = "Recipient phone must be at most 20 characters")
        String recipientPhone,

        @NotBlank(message = "Shipping address is required")
        String shippingAddress,

        String customerNote,

        BigDecimal shippingFee,

        List<@Valid CheckoutItemInput> items
) {
}
