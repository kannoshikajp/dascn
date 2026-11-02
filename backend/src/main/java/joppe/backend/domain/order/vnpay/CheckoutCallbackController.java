package joppe.backend.domain.order.vnpay;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@Tag(name = "Payment - Checkout Callback", description = "Public callback endpoints for customer payment redirects")
public class CheckoutCallbackController {

    private final VnPayPaymentController vnPayPaymentController;

    @GetMapping({"/checkout/callback", "/api/v1/checkout/callback"})
    @Operation(summary = "Handle VNPay return redirect without authentication")
    public ResponseEntity<?> handleCallback(
            @RequestParam Map<String, String> queryParams,
            HttpServletRequest request) {
        return vnPayPaymentController.handleReturn(queryParams, request);
    }
}
