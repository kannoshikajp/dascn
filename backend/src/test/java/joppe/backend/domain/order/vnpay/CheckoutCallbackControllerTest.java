package joppe.backend.domain.order.vnpay;

import java.math.BigDecimal;
import java.util.Map;
import joppe.backend.domain.order.vnpay.dto.VnPayReturnResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class CheckoutCallbackControllerTest {

    private MockMvc mockMvc;

    @Mock
    private VnPayService vnPayService;

    @BeforeEach
    void setUp() {
        VnPayPaymentController paymentController = new VnPayPaymentController(vnPayService);
        CheckoutCallbackController callbackController = new CheckoutCallbackController(paymentController);
        mockMvc = MockMvcBuilders.standaloneSetup(callbackController).build();
    }

    @Test
    void handleCallback_returnsHtmlWhenAcceptHeaderContainsHtml() throws Exception {
        VnPayReturnResult result = new VnPayReturnResult(
                true,
                "ORD-20261102-001",
                "123456",
                "NCB",
                new BigDecimal("1500000.00"),
                "00",
                "Thanh toán thành công"
        );
        when(vnPayService.processReturn(any())).thenReturn(result);

        mockMvc.perform(get("/checkout/callback")
                        .header("Accept", "text/html,application/xhtml+xml")
                        .param("vnp_ResponseCode", "00")
                        .param("vnp_TxnRef", "ORD-20261102-001_123456"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Thanh toán thành công")));
    }

    @Test
    void handleCallback_returnsJsonWhenNoHtmlHeader() throws Exception {
        VnPayReturnResult result = new VnPayReturnResult(
                true,
                "ORD-20261102-001",
                "123456",
                "NCB",
                new BigDecimal("1500000.00"),
                "00",
                "Thanh toán thành công"
        );
        when(vnPayService.processReturn(any())).thenReturn(result);

        mockMvc.perform(get("/checkout/callback")
                        .param("vnp_ResponseCode", "00")
                        .param("vnp_TxnRef", "ORD-20261102-001_123456"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.orderCode").value("ORD-20261102-001"));
    }
}
