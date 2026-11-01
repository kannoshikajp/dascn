package joppe.backend.domain.order.vnpay.dto;

import java.math.BigDecimal;

public record VnPayReturnResult(
        boolean success,
        String orderCode,
        String transactionNo,
        String bankCode,
        BigDecimal amount,
        String responseCode,
        String message
) {}
