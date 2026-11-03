package joppe.backend.domain.order.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public record OrderResponse(
        UUID id,
        String orderCode,
        UUID userId,
        String orderStatus,
        String paymentStatus,
        String recipientName,
        String recipientPhone,
        String shippingAddress,
        BigDecimal subtotalAmount,
        BigDecimal discountAmount,
        BigDecimal shippingFee,
        BigDecimal finalAmount,
        String customerNote,
        OffsetDateTime createdAt,
        OffsetDateTime updatedAt,
        List<OrderItemResponse> items,
        String orderChannel,
        OffsetDateTime paidAt,
        OffsetDateTime deliveredAt,
        OffsetDateTime paymentExpiresAt,
        String manualPaymentRef,
        UUID paymentConfirmedBy,
        String paymentConfirmNote
) {
    public OrderResponse(
            UUID id,
            String orderCode,
            UUID userId,
            String orderStatus,
            String paymentStatus,
            String recipientName,
            String recipientPhone,
            String shippingAddress,
            BigDecimal subtotalAmount,
            BigDecimal discountAmount,
            BigDecimal shippingFee,
            BigDecimal finalAmount,
            String customerNote,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt,
            List<OrderItemResponse> items,
            String orderChannel,
            OffsetDateTime paidAt,
            OffsetDateTime deliveredAt
    ) {
        this(id, orderCode, userId, orderStatus, paymentStatus, recipientName, recipientPhone, shippingAddress,
                subtotalAmount, discountAmount, shippingFee, finalAmount, customerNote, createdAt, updatedAt, items,
                orderChannel, paidAt, deliveredAt, null, null, null, null);
    }

    public OrderResponse(
            UUID id,
            String orderCode,
            UUID userId,
            String orderStatus,
            String paymentStatus,
            String recipientName,
            String recipientPhone,
            String shippingAddress,
            BigDecimal subtotalAmount,
            BigDecimal discountAmount,
            BigDecimal shippingFee,
            BigDecimal finalAmount,
            String customerNote,
            OffsetDateTime createdAt,
            OffsetDateTime updatedAt,
            List<OrderItemResponse> items
    ) {
        this(id, orderCode, userId, orderStatus, paymentStatus, recipientName, recipientPhone, shippingAddress,
                subtotalAmount, discountAmount, shippingFee, finalAmount, customerNote, createdAt, updatedAt, items,
                "ONLINE", null, null, null, null, null, null);
    }
}
