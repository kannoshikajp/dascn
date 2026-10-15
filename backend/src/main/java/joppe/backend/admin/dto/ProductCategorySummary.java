package joppe.backend.admin.dto;

public record ProductCategorySummary(
        Integer id,
        String categoryName,
        String slug,
        boolean isPrimary
) {}
