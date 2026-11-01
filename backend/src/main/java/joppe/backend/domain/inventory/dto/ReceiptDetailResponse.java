package joppe.backend.domain.inventory.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record ReceiptDetailResponse(
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
        String status,
        OffsetDateTime createdAt,
        String note,
        List<ReceiptItemResponse> items
) {
}
