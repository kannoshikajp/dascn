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
public class ReturnService {

    private final ReturnRepository returnRepository;
    private final ReturnItemRepository returnItemRepository;
    private final OrderRepository orderRepository;

    @Transactional
    public UUID createReturn(UUID orderId, String returnCode, String reason, BigDecimal refundAmount) {
        if (!orderRepository.existsById(orderId)) {
            throw new IllegalArgumentException("Order not found with ID: " + orderId);
        }
        if (returnRepository.existsByReturnCode(returnCode)) {
            throw new IllegalArgumentException("Return code already exists: " + returnCode);
        }

        Return ret = Return.builder()
                .orderId(orderId)
                .returnCode(returnCode)
                .reason(reason)
                .refundAmount(refundAmount)
                .status("REQUESTED")
                .build();

        return returnRepository.save(ret).getId();
    }

    @Transactional
    public UUID addReturnItem(
            UUID returnId,
            UUID orderItemId,
            int quantity,
            String conditionStatus,
            String note) {

        ReturnItem item = ReturnItem.builder()
                .returnId(returnId)
                .orderItemId(orderItemId)
                .quantity(quantity)
                .conditionStatus(conditionStatus)
                .note(note)
                .build();

        return returnItemRepository.save(item).getId();
    }

    @Transactional
    public void completeReturn(UUID returnId) {
        Return ret = returnRepository.findById(returnId)
                .orElseThrow(() -> new IllegalArgumentException("Return not found: " + returnId));

        OffsetDateTime now = OffsetDateTime.now();
        returnRepository.updateReturnStatus(returnId, "COMPLETED", now);
        orderRepository.updateOrderStatus(ret.getOrderId(), "RETURNED");
    }

    @Transactional
    public void rejectReturn(UUID returnId) {
        OffsetDateTime now = OffsetDateTime.now();
        returnRepository.updateReturnStatus(returnId, "REJECTED", now);
    }

    @Transactional(readOnly = true)
    public List<Return> getReturnsByOrder(UUID orderId) {
        return returnRepository.findByOrderId(orderId);
    }

    @Transactional(readOnly = true)
    public Optional<Return> findByReturnCode(String returnCode) {
        return returnRepository.findByReturnCode(returnCode);
    }
}
