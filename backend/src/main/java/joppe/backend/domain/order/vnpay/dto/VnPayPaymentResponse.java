package joppe.backend.domain.order.vnpay.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record VnPayPaymentResponse(
        UUID paymentId,
        String paymentUrl,
        String orderCode,
        String txnRef,
        BigDecimal amount,
        String qrCodeUrl,
        String qrCodeBase64
) {
    public VnPayPaymentResponse(
            UUID paymentId,
            String paymentUrl,
            String orderCode,
            String txnRef,
            BigDecimal amount
    ) {
        this(paymentId, paymentUrl, orderCode, txnRef, amount, null, null);
    }
}
