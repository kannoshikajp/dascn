package joppe.backend.domain.inventory.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record ReceiptSummaryResponse(
        UUID id,
        String receiptCode,
        String receiptType,
        UUID supplierId,
        String supplierName,
        UUID orderId,
        String orderCode,
        UUID staffId,
        String staffName,
        BigDecimal totalAmount,
        int totalItems,
        String status,
        OffsetDateTime createdAt,
        String note
) {
}
