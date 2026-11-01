package joppe.backend.common.dto;

import java.time.OffsetDateTime;
import java.util.Map;

public record LivenessResponse(
        String status,
        String message,
        OffsetDateTime timestamp,
        String version,
        Map<String, Object> details
) {
}
