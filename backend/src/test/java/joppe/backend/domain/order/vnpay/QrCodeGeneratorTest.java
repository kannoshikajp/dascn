package joppe.backend.domain.order.vnpay;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class QrCodeGeneratorTest {

    @Test
    void generateQrCodePng_returnsValidPngBytes() {
        String testPayload = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?order=123";
        byte[] pngBytes = QrCodeGenerator.generateQrCodePng(testPayload, 250, 250);

        assertThat(pngBytes).isNotNull();
        assertThat(pngBytes.length).isGreaterThan(100);

        // Verify PNG magic bytes: 0x89 0x50 0x4E 0x47 (PNG header)
        assertThat(pngBytes[0]).isEqualTo((byte) 0x89);
        assertThat(pngBytes[1]).isEqualTo((byte) 0x50);
        assertThat(pngBytes[2]).isEqualTo((byte) 0x4E);
        assertThat(pngBytes[3]).isEqualTo((byte) 0x47);
    }

    @Test
    void generateQrCodeDataUri_returnsRfc2397DataUri() {
        String testPayload = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?order=123";
        String dataUri = QrCodeGenerator.generateQrCodeDataUri(testPayload, 200, 200);

        assertThat(dataUri).startsWith("data:image/png;base64,");
        assertThat(dataUri.length()).isGreaterThan(50);
    }

    @Test
    void generateQrCodePng_throwsOnEmptyPayload() {
        assertThatThrownBy(() -> QrCodeGenerator.generateQrCodePng("", 200, 200))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> QrCodeGenerator.generateQrCodePng(null, 200, 200))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
