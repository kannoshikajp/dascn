package joppe.backend.admin.dto;

public record PermissionDto(
        Integer id,
        String permissionName,
        String description
) {
}
