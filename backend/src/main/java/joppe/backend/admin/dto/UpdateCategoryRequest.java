package joppe.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCategoryRequest(
        Integer parentId,
        @NotBlank(message = "Category name is required")
        @Size(max = 150, message = "Category name must not exceed 150 characters")
        String categoryName,
        @Size(max = 200, message = "Slug must not exceed 200 characters")
        String slug,
        String iconUrl,
        Boolean isActive
) {}
