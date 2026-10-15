package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record UpdateRolePermissionsRequest(
        @NotEmpty(message = "Permissions list cannot be empty")
        List<String> permissions
) {
}
