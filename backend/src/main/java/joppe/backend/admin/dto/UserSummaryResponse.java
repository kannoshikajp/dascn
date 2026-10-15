package joppe.backend.admin.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UserSummaryResponse(
        UUID id,
        String email,
        String fullName,
        String phoneNumber,
        String avatarUrl,
        Integer roleId,
        String roleName,
        Boolean isActive,
        OffsetDateTime createdAt
) {
}
