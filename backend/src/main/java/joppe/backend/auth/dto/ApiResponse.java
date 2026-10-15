package joppe.backend.auth.dto;

public record ApiResponse(
        boolean success,
        String message
) {
}
