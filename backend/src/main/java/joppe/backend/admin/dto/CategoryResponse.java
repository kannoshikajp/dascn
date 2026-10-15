package joppe.backend.admin.dto;

import java.time.OffsetDateTime;

public record CategoryResponse(
        Integer id,
        Integer parentId,
        String parentName,
        String categoryName,
        String slug,
        String iconUrl,
        Boolean isActive,
        OffsetDateTime createdAt,
        long productCount,
        long childCount
) {}
