package joppe.backend.domain.order.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public record OrderSummaryResponse(
        UUID id,
        String orderCode,
        UUID userId,
        String orderStatus,
        String paymentStatus,
        String recipientName,
        String recipientPhone,
        BigDecimal finalAmount,
        int totalItems,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        String orderChannel,
        OffsetDateTime paidAt,
        OffsetDateTime deliveredAt
) {
    public OrderSummaryResponse(
            UUID id,
            String orderCode,
            UUID userId,
            String orderStatus,
            String paymentStatus,
            String recipientName,
            String recipientPhone,
            BigDecimal finalAmount,
            int totalItems,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt
    ) {
        this(id, orderCode, userId, orderStatus, paymentStatus, recipientName, recipientPhone, finalAmount, totalItems, createdAt, updatedAt, "ONLINE", null, null);
    }
}
