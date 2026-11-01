package joppe.backend.domain.order.vnpay;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "joppe.vnpay")
@Getter
@Setter
public class VnPayProperties {

    /**
     * Merchant Terminal ID registered with VNPay (vnp_TmnCode)
     */
    private String tmnCode = "H04KMMWQ";

    /**
     * Secret key for HMAC-SHA512 checksum calculation (vnp_HashSecret)
     */
    private String hashSecret = "QSRCXQVXSJPTZJDSAPEKSGMMUEPBOGSA";

    /**
     * VNPay sandbox payment gateway URL
     */
    private String payUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";

    /**
     * Return URL after customer finishes payment on VNPay portal
     */
    private String returnUrl = "https://joppe.penguinlab.org/api/v1/payment/vnpay/return";

    /**
     * VNPay Transaction Query API URL (refund/queryDR)
     */
    private String apiUrl = "https://sandbox.vnpayment.vn/merchant_webapi/api/transaction";

    private String version = "2.1.0";
    private String command = "pay";
    private String currCode = "VND";
}
