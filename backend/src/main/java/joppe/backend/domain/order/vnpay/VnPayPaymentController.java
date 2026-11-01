package joppe.backend.domain.order.vnpay;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.Map;
import joppe.backend.domain.order.vnpay.dto.CreateVnPayPaymentRequest;
import joppe.backend.domain.order.vnpay.dto.VnPayIpnResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayPaymentResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayReturnResult;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/payment/vnpay")
@RequiredArgsConstructor
@Tag(name = "Payment - VNPAY Gateway", description = "Endpoints for generating VNPay checkout URL, handling IPN webhooks and return callbacks")
public class VnPayPaymentController {

    private final VnPayService vnPayService;

    @Value("${app.frontend-url:https://joppe-dash.vercel.app}")
    private String frontendUrl = "https://joppe-dash.vercel.app";

    @PostMapping("/create")
    @PreAuthorize("hasAnyAuthority('PAYMENT_PROCESS', 'ORDER_CREATE', 'ROLE_CUSTOMER', 'ROLE_ADMIN', 'ROLE_STAFF')")
    @Operation(summary = "Generate signed VNPay payment URL for an existing pending order")
    public ResponseEntity<VnPayPaymentResponse> createPaymentUrl(
            @Valid @RequestBody CreateVnPayPaymentRequest request,
            HttpServletRequest httpRequest) {
        VnPayPaymentResponse response = vnPayService.createPaymentUrl(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping(value = "/qr", produces = MediaType.IMAGE_PNG_VALUE)
    @Operation(summary = "Generate and stream QR code PNG image for a payment URL or payment record")
    public ResponseEntity<byte[]> getQrCode(
            @RequestParam(required = false) String paymentUrl,
            @RequestParam(required = false) java.util.UUID paymentId,
            @RequestParam(defaultValue = "300") int size) {
        byte[] qrBytes = vnPayService.generateQrCodeImage(paymentUrl, paymentId, size);
        return ResponseEntity.ok()
                .contentType(MediaType.IMAGE_PNG)
                .body(qrBytes);
    }

    @GetMapping("/ipn")
    @Operation(summary = "VNPay Instant Payment Notification (IPN) webhook called by VNPay servers")
    public ResponseEntity<VnPayIpnResponse> handleIpn(@RequestParam Map<String, String> queryParams) {
        VnPayIpnResponse response = vnPayService.processIpn(queryParams);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/return")
    @Operation(summary = "VNPay return URL redirect handling after customer completes or cancels payment")
    public ResponseEntity<?> handleReturn(
            @RequestParam Map<String, String> queryParams,
            HttpServletRequest request) {
        VnPayReturnResult result = vnPayService.processReturn(queryParams);

        String acceptHeader = request.getHeader("Accept");
        if (acceptHeader != null && acceptHeader.contains("text/html")) {
            String title = result.success() ? "Thanh toán thành công" : "Thanh toán chưa thành công";
            String iconColor = result.success() ? "#22c55e" : "#ef4444";
            String iconBg = result.success() ? "rgba(34, 197, 94, 0.15)" : "rgba(239, 68, 68, 0.15)";
            String iconSymbol = result.success() ? "✓" : "✕";

            String html = """
                    <!DOCTYPE html>
                    <html lang="vi">
                    <head>
                        <meta charset="UTF-8">
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <title>%s - Joppe Payment</title>
                        <style>
                            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #0b1120; color: #f8fafc; }
                            .card { background: #1e293b; border-radius: 16px; padding: 32px 28px; max-width: 420px; width: 90%%; text-align: center; border: 1px solid #334155; box-shadow: 0 20px 40px rgba(0,0,0,0.5); }
                            .icon { width: 64px; height: 64px; border-radius: 50%%; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px; font-size: 32px; font-weight: bold; background: %s; color: %s; }
                            h2 { margin: 0 0 10px; font-size: 20px; }
                            p { margin: 6px 0; color: #94a3b8; font-size: 13px; }
                            .code { font-family: monospace; font-weight: bold; color: #38bdf8; font-size: 14px; }
                            .btn { margin-top: 24px; padding: 12px 28px; border-radius: 8px; background: #0284c7; color: white; border: none; font-weight: bold; font-size: 14px; cursor: pointer; transition: background 0.2s; }
                            .btn:hover { background: #0369a1; }
                        </style>
                    </head>
                    <body>
                        <div class="card">
                            <div class="icon">%s</div>
                            <h2>%s</h2>
                            <p>Mã đơn hàng: <span class="code">%s</span></p>
                            <p>%s</p>
                            <button class="btn" onclick="handleClose()">Đóng cửa sổ</button>
                        </div>
                        <script>
                            function handleClose() {
                                if (window.opener) {
                                    window.close();
                                } else {
                                    window.location.href = '%s';
                                }
                            }
                            if (window.opener) {
                                window.opener.postMessage({
                                    type: 'VNPAY_PAYMENT_RESULT',
                                    success: %s,
                                    orderCode: '%s'
                                }, '*');
                                setTimeout(function() { window.close(); }, 2500);
                            }
                        </script>
                    </body>
                    </html>
                    """.formatted(
                            title,
                            iconBg,
                            iconColor,
                            iconSymbol,
                            title,
                            result.orderCode() != null ? result.orderCode() : "",
                            result.message(),
                            frontendUrl,
                            result.success() ? "true" : "false",
                            result.orderCode() != null ? result.orderCode() : ""
                    );
            return ResponseEntity.ok().contentType(MediaType.TEXT_HTML).body(html);
        }

        return ResponseEntity.ok(result);
    }
}
