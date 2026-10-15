package joppe.backend.auth.dto;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String email,
        String fullName,
        String phoneNumber,
        String avatarUrl,
        String role,
        List<String> permissions,
        Boolean isActive,
        OffsetDateTime createdAt
) {
}
