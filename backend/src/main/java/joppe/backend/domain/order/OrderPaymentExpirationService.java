package joppe.backend.domain.order;

import java.time.OffsetDateTime;
import java.util.List;
import joppe.backend.domain.catalog.ProductVariantService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderPaymentExpirationService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final ProductVariantService productVariantService;

    @Scheduled(fixedDelay = 30000)
    @Transactional
    public void releaseExpiredOrderReservations() {
        OffsetDateTime now = OffsetDateTime.now();
        List<Order> expiredOrders = orderRepository.findByPaymentStatusAndPaymentExpiresAtBefore("UNPAID", now);
        if (expiredOrders == null || expiredOrders.isEmpty()) {
            return;
        }

        for (Order order : expiredOrders) {
            String status = order.getOrderStatus() != null ? order.getOrderStatus().toUpperCase() : "";
            if ("ACCEPTED".equals(status) || "PENDING".equals(status)) {
                log.info("Auto-expiring unpaid order {} with payment TTL expired at {}", order.getOrderCode(), order.getPaymentExpiresAt());
                order.setOrderStatus("CANCELLED");
                order.setPaymentStatus("EXPIRED");
                order.setPaymentExpiresAt(null);
                orderRepository.save(order);

                List<OrderItem> items = orderItemRepository.findByOrderId(order.getId());
                for (OrderItem item : items) {
                    if (item.getVariantId() != null && item.getQuantity() != null && item.getQuantity() > 0) {
                        try {
                            productVariantService.releaseStock(item.getVariantId(), item.getQuantity());
                        } catch (Exception e) {
                            log.warn("Failed to release stock for variant {}: {}", item.getVariantId(), e.getMessage());
                        }
                    }
                }
            }
        }
    }
}
