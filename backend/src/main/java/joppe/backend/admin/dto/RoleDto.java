package joppe.backend.admin.dto;

import java.util.List;

public record RoleDto(
        Integer id,
        String roleName,
        String description,
        List<String> permissions
) {
}
