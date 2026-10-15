package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @NotBlank(message = "Full name is required")
        @Size(max = 150, message = "Full name cannot exceed 150 characters")
        String fullName,

        @Size(max = 20, message = "Phone number cannot exceed 20 characters")
        String phoneNumber,

        String avatarUrl,

        @NotNull(message = "Role ID is required")
        Integer roleId,

        @NotNull(message = "Active status is required")
        Boolean isActive
) {
}
