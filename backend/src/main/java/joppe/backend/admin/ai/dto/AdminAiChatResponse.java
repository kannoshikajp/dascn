package joppe.backend.admin.ai.dto;

import java.util.List;

public record AdminAiChatResponse(
        String answer,
        List<ReferencedProductDto> referencedProducts,
        List<String> executedTools
) {
    public record ReferencedProductDto(
            String id,
            String sku,
            String name,
            Long minPrice,
            Long maxPrice,
            Integer totalStock
    ) {}
}
