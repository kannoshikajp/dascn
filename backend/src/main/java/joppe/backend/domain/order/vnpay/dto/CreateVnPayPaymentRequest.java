package joppe.backend.domain.order.vnpay.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record CreateVnPayPaymentRequest(
        @NotNull(message = "Order ID is required")
        UUID orderId,

        /**
         * Optional bank code (e.g. NCB, VCB, MBAPP). Leave null to choose on VNPay portal.
         */
        String bankCode,

        /**
         * Optional override for return URL
         */
        String returnUrl
) {}
