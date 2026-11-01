package joppe.backend.domain.inventory.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SupplierRequest(
        @NotBlank(message = "Supplier name is required")
        @Size(max = 200, message = "Supplier name must be at most 200 characters")
        String supplierName,

        @Size(max = 150, message = "Contact person must be at most 150 characters")
        String contactPerson,

        @Size(max = 20, message = "Phone number must be at most 20 characters")
        String phoneNumber,

        @Size(max = 255, message = "Email must be at most 255 characters")
        String email,

        String address,

        Boolean isActive
) {
}
