package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ManualPaymentConfirmRequest(
        @NotBlank(message = "Reference code (bank transaction code or receipt slip) is required")
        @Size(min = 4, max = 100, message = "Reference code must be between 4 and 100 characters")
        String referenceCode,

        String note,

        String managerPin
) {
}
