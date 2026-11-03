package joppe.backend.domain.ai.dto;

import java.util.List;

public record CustomerAiChatResponse(
        String answer,
        List<ReferencedProductDto> referencedProducts,
        List<String> quickReplies,
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
