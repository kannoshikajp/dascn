package joppe.backend.domain.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AddressRequest(
        @NotBlank(message = "Recipient name is required")
        @Size(max = 150, message = "Recipient name must be at most 150 characters")
        String recipientName,

        @NotBlank(message = "Recipient phone is required")
        @Size(max = 20, message = "Recipient phone must be at most 20 characters")
        String recipientPhone,

        @NotBlank(message = "Street address is required")
        String streetAddress,

        @Size(max = 100, message = "Ward must be at most 100 characters")
        String ward,

        @Size(max = 100, message = "District must be at most 100 characters")
        String district,

        @NotBlank(message = "Province / City is required")
        @Size(max = 100, message = "Province must be at most 100 characters")
        String province,

        Boolean isDefault
) {
}
