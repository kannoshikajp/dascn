package joppe.backend.admin.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import joppe.backend.domain.order.dto.CheckoutItemInput;

public record CreateAdminOrderRequest(
        UUID userId,

        String customerEmail,

        @NotBlank(message = "Recipient name is required")
        @Size(max = 150, message = "Recipient name must be at most 150 characters")
        String recipientName,

        @NotBlank(message = "Recipient phone is required")
        @Size(max = 20, message = "Recipient phone must be at most 20 characters")
        String recipientPhone,

        @NotBlank(message = "Shipping address is required")
        String shippingAddress,

        String customerNote,

        BigDecimal shippingFee,

        String orderStatus,

        String paymentStatus,

        @NotEmpty(message = "Order must contain at least one item")
        List<@Valid CheckoutItemInput> items
) {
}
