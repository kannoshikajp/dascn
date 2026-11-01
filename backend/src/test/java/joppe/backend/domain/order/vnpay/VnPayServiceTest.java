package joppe.backend.domain.order.vnpay;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.order.Order;
import joppe.backend.domain.order.OrderRepository;
import joppe.backend.domain.order.Payment;
import joppe.backend.domain.order.PaymentRepository;
import joppe.backend.domain.order.vnpay.dto.CreateVnPayPaymentRequest;
import joppe.backend.domain.order.vnpay.dto.VnPayIpnResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayPaymentResponse;
import joppe.backend.domain.order.vnpay.dto.VnPayReturnResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VnPayServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private PaymentRepository paymentRepository;

    private VnPayProperties properties;
    private VnPayService vnPayService;

    private final UUID orderId = UUID.randomUUID();
    private Order sampleOrder;

    @BeforeEach
    void setUp() {
        properties = new VnPayProperties();
        properties.setTmnCode("H04KMMWQ");
        properties.setHashSecret("QSRCXQVXSJPTZJDSAPEKSGMMUEPBOGSA");
        properties.setPayUrl("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
        properties.setReturnUrl("https://joppe.penguinlab.org/api/v1/payment/vnpay/return");

        vnPayService = new VnPayService(properties, orderRepository, paymentRepository);

        sampleOrder = Order.builder()
                .id(orderId)
                .orderCode("ORD-20261030-001")
                .recipientName("Nguyen Van A")
                .finalAmount(new BigDecimal("15000000.00"))
                .orderStatus("PENDING")
                .paymentStatus("UNPAID")
                .build();
    }

    @Test
    void createPaymentUrl_generatesSignedPaymentUrl() {
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(sampleOrder));
        when(paymentRepository.save(any(Payment.class))).thenAnswer(inv -> {
            Payment p = inv.getArgument(0);
            p.setId(UUID.randomUUID());
            return p;
        });

        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRemoteAddr("127.0.0.1");

        CreateVnPayPaymentRequest createReq = new CreateVnPayPaymentRequest(orderId, "NCB", null);
        VnPayPaymentResponse response = vnPayService.createPaymentUrl(createReq, request);

        assertThat(response).isNotNull();
        assertThat(response.orderCode()).isEqualTo("ORD-20261030-001");
        assertThat(response.amount()).isEqualByComparingTo("15000000.00");
        assertThat(response.paymentUrl()).contains("vnp_TmnCode=H04KMMWQ");
        assertThat(response.paymentUrl()).contains("vnp_BankCode=NCB");
        assertThat(response.paymentUrl()).contains("vnp_Amount=1500000000"); // multiplied by 100
        assertThat(response.paymentUrl()).contains("vnp_SecureHash=");
        assertThat(response.qrCodeUrl()).contains("/api/v1/payment/vnpay/qr?paymentUrl=");
        assertThat(response.qrCodeBase64()).startsWith("data:image/png;base64,");

        verify(paymentRepository).save(any(Payment.class));
    }

    @Test
    void generateQrCodeImage_returnsRawPngBytes() {
        byte[] bytes = vnPayService.generateQrCodeImage("https://sandbox.vnpayment.vn/test", null, 300);
        assertThat(bytes).isNotNull();
        assertThat(bytes[0]).isEqualTo((byte) 0x89);
        assertThat(bytes[1]).isEqualTo((byte) 0x50); // 'P'
        assertThat(bytes[2]).isEqualTo((byte) 0x4E); // 'N'
        assertThat(bytes[3]).isEqualTo((byte) 0x47); // 'G'
    }

    @Test
    void createPaymentUrl_throwsExceptionIfOrderPaid() {
        sampleOrder.setPaymentStatus("PAID");
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(sampleOrder));

        MockHttpServletRequest request = new MockHttpServletRequest();
        CreateVnPayPaymentRequest createReq = new CreateVnPayPaymentRequest(orderId, null, null);

        assertThatThrownBy(() -> vnPayService.createPaymentUrl(createReq, request))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("already paid");
    }

    @Test
    void processIpn_validSignatureAndSuccess_updatesOrder() {
        Map<String, String> params = new HashMap<>();
        params.put("vnp_TmnCode", "H04KMMWQ");
        params.put("vnp_Amount", "1500000000");
        params.put("vnp_BankCode", "NCB");
        params.put("vnp_OrderInfo", "Thanh_toan_don_hang_ORD-20261030-001");
        params.put("vnp_ResponseCode", "00");
        params.put("vnp_TransactionNo", "14226112");
        params.put("vnp_TransactionStatus", "00");
        params.put("vnp_TxnRef", "ORD-20261030-001");

        String hash = VnPayUtil.hashAllFields(params, properties.getHashSecret());
        params.put("vnp_SecureHash", hash);

        when(paymentRepository.findByTransactionCode("ORD-20261030-001")).thenReturn(Optional.empty());
        when(orderRepository.findByOrderCode("ORD-20261030-001")).thenReturn(Optional.of(sampleOrder));

        VnPayIpnResponse ipnResponse = vnPayService.processIpn(params);

        assertThat(ipnResponse.rspCode()).isEqualTo("00");
        assertThat(ipnResponse.message()).isEqualTo("Confirm Success");

        verify(orderRepository).updatePaymentStatus(sampleOrder.getId(), "PAID");
        verify(orderRepository).updateOrderStatus(sampleOrder.getId(), "ACCEPTED");
    }

    @Test
    void processIpn_invalidChecksum_returns97() {
        Map<String, String> params = new HashMap<>();
        params.put("vnp_Amount", "1500000000");
        params.put("vnp_TxnRef", "ORD-20261030-001");
        params.put("vnp_SecureHash", "INVALID_HASH_VALUE_HERE");

        VnPayIpnResponse ipnResponse = vnPayService.processIpn(params);

        assertThat(ipnResponse.rspCode()).isEqualTo("97");
        assertThat(ipnResponse.message()).isEqualTo("Invalid Checksum");
    }

    @Test
    void processReturn_validSignatureSuccess_returnsSuccessResult() {
        Map<String, String> params = new HashMap<>();
        params.put("vnp_Amount", "1500000000");
        params.put("vnp_BankCode", "NCB");
        params.put("vnp_ResponseCode", "00");
        params.put("vnp_TransactionNo", "14226112");
        params.put("vnp_TxnRef", "ORD-20261030-001");

        String hash = VnPayUtil.hashAllFields(params, properties.getHashSecret());
        params.put("vnp_SecureHash", hash);

        when(orderRepository.findByOrderCode("ORD-20261030-001")).thenReturn(Optional.of(sampleOrder));

        VnPayReturnResult result = vnPayService.processReturn(params);

        assertThat(result.success()).isTrue();
        assertThat(result.orderCode()).isEqualTo("ORD-20261030-001");
        assertThat(result.transactionNo()).isEqualTo("14226112");
        assertThat(result.bankCode()).isEqualTo("NCB");
        assertThat(result.amount()).isEqualByComparingTo("15000000.00");
        assertThat(result.message()).isEqualTo("Giao dịch thành công");
    }
}
