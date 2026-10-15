package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record CreateRoleRequest(
        @NotBlank(message = "Role name is required")
        @Size(max = 50, message = "Role name cannot exceed 50 characters")
        String roleName,

        @Size(max = 255, message = "Description cannot exceed 255 characters")
        String description,

        @NotEmpty(message = "Role must have at least one permission assigned")
        List<String> permissions
) {
}
