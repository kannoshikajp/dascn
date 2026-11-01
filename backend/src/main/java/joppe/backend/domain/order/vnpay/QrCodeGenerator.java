package joppe.backend.domain.order.vnpay;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

public final class QrCodeGenerator {

    private QrCodeGenerator() {}

    /**
     * Generates a raw PNG byte array of the QR code representing the given text.
     */
    public static byte[] generateQrCodePng(String text, int width, int height) {
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("QR code text payload cannot be empty");
        }
        int w = width > 0 ? width : 300;
        int h = height > 0 ? height : 300;

        try {
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            Map<EncodeHintType, Object> hints = new HashMap<>();
            hints.put(EncodeHintType.CHARACTER_SET, StandardCharsets.UTF_8.name());
            hints.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M);
            hints.put(EncodeHintType.MARGIN, 1);

            BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, w, h, hints);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(bitMatrix, "PNG", outputStream);
            return outputStream.toByteArray();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to generate QR code image", e);
        }
    }

    /**
     * Generates an RFC 2397 Data URI (e.g. data:image/png;base64,...) for immediate inline rendering.
     */
    public static String generateQrCodeDataUri(String text, int width, int height) {
        byte[] pngBytes = generateQrCodePng(text, width, height);
        return "data:image/png;base64," + Base64.getEncoder().encodeToString(pngBytes);
    }
}
