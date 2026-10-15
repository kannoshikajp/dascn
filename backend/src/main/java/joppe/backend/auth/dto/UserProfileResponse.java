package joppe.backend.auth.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String email,
        String fullName,
        String phoneNumber,
        String avatarUrl,
        String role,
        Boolean isActive,
        OffsetDateTime createdAt
) {
}
