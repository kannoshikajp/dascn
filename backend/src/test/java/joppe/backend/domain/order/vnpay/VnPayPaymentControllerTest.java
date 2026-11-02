package joppe.backend.domain.order.vnpay;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.util.UUID;
import joppe.backend.domain.order.vnpay.dto.CreateVnPayPaymentRequest;
import joppe.backend.domain.order.vnpay.dto.VnPayIpnResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayPaymentResponse;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class VnPayPaymentControllerTest {

    private MockMvc mockMvc;

    @Mock
    private VnPayService vnPayService;

    @Mock
    private joppe.backend.domain.order.OrderRepository orderRepository;

    @Mock
    private joppe.backend.domain.order.PaymentRepository paymentRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new VnPayPaymentController(vnPayService, orderRepository, paymentRepository))
                .build();
    }

    @Test
    void createPaymentUrl_returnsCreatedWithUrl() throws Exception {
        UUID orderId = UUID.randomUUID();
        CreateVnPayPaymentRequest req = new CreateVnPayPaymentRequest(orderId, "NCB", null);
        VnPayPaymentResponse res = new VnPayPaymentResponse(
                UUID.randomUUID(),
                "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=1500000000",
                "ORD-20261030-001",
                "ORD-20261030-001_12345",
                new BigDecimal("15000000.00")
        );

        when(vnPayService.createPaymentUrl(any(), any())).thenReturn(res);

        mockMvc.perform(post("/api/v1/payment/vnpay/create")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.orderCode").value("ORD-20261030-001"))
                .andExpect(jsonPath("$.paymentUrl").value("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=1500000000"));
    }

    @Test
    void getQrCode_returnsPngImageBytes() throws Exception {
        byte[] mockBytes = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        when(vnPayService.generateQrCodeImage(any(), any(), any(int.class))).thenReturn(mockBytes);

        mockMvc.perform(get("/api/v1/payment/vnpay/qr")
                        .param("paymentUrl", "https://sandbox.vnpayment.vn/test")
                        .param("size", "300"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_PNG))
                .andExpect(content().bytes(mockBytes));
    }

    @Test
    void handleIpn_returnsIpnResponseJson() throws Exception {
        when(vnPayService.processIpn(any())).thenReturn(VnPayIpnResponse.success());

        mockMvc.perform(get("/api/v1/payment/vnpay/ipn")
                        .param("vnp_ResponseCode", "00")
                        .param("vnp_TxnRef", "ORD-20261030-001")
                        .param("vnp_SecureHash", "hash123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.RspCode").value("00"))
                .andExpect(jsonPath("$.Message").value("Confirm Success"));
    }

    @Test
    void handleReturn_returnsReturnResultJson() throws Exception {
        VnPayReturnResult result = new VnPayReturnResult(
                true,
                "ORD-20261030-001",
                "14226112",
                "NCB",
                new BigDecimal("15000000.00"),
                "00",
                "Giao dịch thành công"
        );

        when(vnPayService.processReturn(any())).thenReturn(result);

        mockMvc.perform(get("/api/v1/payment/vnpay/return")
                        .param("vnp_ResponseCode", "00")
                        .param("vnp_TxnRef", "ORD-20261030-001")
                        .param("vnp_SecureHash", "hash123"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.orderCode").value("ORD-20261030-001"))
                .andExpect(jsonPath("$.message").value("Giao dịch thành công"));
    }

    @Test
    void getPaymentStatus_paidOrder_returnsIsPaidTrue() throws Exception {
        joppe.backend.domain.order.Order order = joppe.backend.domain.order.Order.builder()
                .id(UUID.randomUUID())
                .orderCode("ORD-20261102-001")
                .paymentStatus("PAID")
                .build();

        when(orderRepository.findByOrderCode("ORD-20261102-001")).thenReturn(java.util.Optional.of(order));

        mockMvc.perform(get("/api/v1/payment/vnpay/status")
                        .param("orderCode", "ORD-20261102-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.isPaid").value(true))
                .andExpect(jsonPath("$.paymentStatus").value("PAID"));
    }

    @Test
    void handleReturn_withHtmlAcceptHeader_returnsHtmlReceipt() throws Exception {
        VnPayReturnResult result = new VnPayReturnResult(
                true,
                "ORD-20261030-001",
                "14226112",
                "NCB",
                new BigDecimal("15000000.00"),
                "00",
                "Giao dịch thành công"
        );

        when(vnPayService.processReturn(any())).thenReturn(result);

        mockMvc.perform(get("/api/v1/payment/vnpay/return")
                        .header("Accept", "text/html,application/xhtml+xml")
                        .param("vnp_ResponseCode", "00")
                        .param("vnp_TxnRef", "ORD-20261030-001")
                        .param("vnp_SecureHash", "hash123"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Thanh toán thành công")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("window.close()")));
    }
}
