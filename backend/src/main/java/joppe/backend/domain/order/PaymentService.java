package joppe.backend.domain.order;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;

    @Transactional
    public UUID createPayment(
            UUID orderId,
            String paymentMethod,
            String paymentGateway,
            String transactionCode,
            BigDecimal amount) {

        if (!orderRepository.existsById(orderId)) {
            throw new IllegalArgumentException("Order not found with ID: " + orderId);
        }

        Payment payment = Payment.builder()
                .orderId(orderId)
                .paymentMethod(paymentMethod)
                .paymentGateway(paymentGateway)
                .transactionCode(transactionCode)
                .amount(amount)
                .status("PENDING")
                .build();

        return paymentRepository.save(payment).getId();
    }

    @Transactional
    public void recordSuccess(UUID paymentId, String gatewayResponse) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment not found: " + paymentId));

        OffsetDateTime now = OffsetDateTime.now();
        paymentRepository.updatePaymentResult(paymentId, "COMPLETED", gatewayResponse, now);
        orderRepository.updatePaymentStatus(payment.getOrderId(), "PAID");
    }

    @Transactional
    public void recordFailure(UUID paymentId, String gatewayResponse) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new IllegalArgumentException("Payment not found: " + paymentId));

        paymentRepository.updatePaymentResult(paymentId, "FAILED", gatewayResponse, null);
        orderRepository.updatePaymentStatus(payment.getOrderId(), "FAILED");
    }

    @Transactional(readOnly = true)
    public List<Payment> getPaymentsByOrder(UUID orderId) {
        return paymentRepository.findByOrderId(orderId);
    }

    @Transactional(readOnly = true)
    public Optional<Payment> findByTransactionCode(String transactionCode) {
        return paymentRepository.findByTransactionCode(transactionCode);
    }
}
