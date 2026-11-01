package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateOrderStatusRequest(
        @NotBlank(message = "Order status is required")
        String status
) {
}
