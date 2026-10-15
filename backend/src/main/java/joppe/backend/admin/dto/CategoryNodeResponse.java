package joppe.backend.admin.dto;

import java.util.List;

public record CategoryNodeResponse(
        Integer id,
        Integer parentId,
        String categoryName,
        String slug,
        String iconUrl,
        Boolean isActive,
        long productCount,
        List<CategoryNodeResponse> children
) {}
