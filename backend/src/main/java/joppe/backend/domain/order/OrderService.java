package joppe.backend.domain.order;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.catalog.ProductVariantService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final ProductVariantService productVariantService;

    @Transactional
    public UUID createOrder(
            String orderCode,
            UUID userId,
            UUID promotionId,
            String recipientName,
            String recipientPhone,
            String shippingAddress,
            BigDecimal subtotalAmount,
            BigDecimal discountAmount,
            BigDecimal shippingFee,
            BigDecimal finalAmount,
            String customerNote) {

        if (orderRepository.existsByOrderCode(orderCode)) {
            throw new IllegalArgumentException("Order code already exists: " + orderCode);
        }

        Order order = Order.builder()
                .orderCode(orderCode)
                .userId(userId)
                .promotionId(promotionId)
                .orderStatus("PENDING")
                .paymentStatus("UNPAID")
                .recipientName(recipientName)
                .recipientPhone(recipientPhone)
                .shippingAddress(shippingAddress)
                .subtotalAmount(subtotalAmount)
                .discountAmount(discountAmount)
                .shippingFee(shippingFee)
                .finalAmount(finalAmount)
                .customerNote(customerNote)
                .build();

        return orderRepository.save(order).getId();
    }

    @Transactional
    public UUID addOrderItem(
            UUID orderId,
            UUID variantId,
            String skuSnapshot,
            String productNameSnapshot,
            String variantNameSnapshot,
            int quantity,
            BigDecimal unitPrice,
            BigDecimal subtotal,
            int warrantyMonths) {

        if (variantId != null) {
            boolean reserved = productVariantService.reserveStock(variantId, quantity);
            if (!reserved) {
                throw new IllegalStateException("Insufficient stock for variant: " + variantId);
            }
        }

        OrderItem item = OrderItem.builder()
                .orderId(orderId)
                .variantId(variantId)
                .skuSnapshot(skuSnapshot)
                .productNameSnapshot(productNameSnapshot)
                .variantNameSnapshot(variantNameSnapshot)
                .quantity(quantity)
                .unitPrice(unitPrice)
                .subtotal(subtotal)
                .warrantyMonthsSnapshot(warrantyMonths)
                .build();

        return orderItemRepository.save(item).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Order> findById(UUID orderId) {
        return orderRepository.findById(orderId);
    }

    @Transactional(readOnly = true)
    public List<Order> getOrdersByUser(UUID userId) {
        return orderRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    @Transactional(readOnly = true)
    public List<OrderItem> getOrderItems(UUID orderId) {
        return orderItemRepository.findByOrderId(orderId);
    }

    @Transactional
    public void updateOrderStatus(UUID orderId, String newStatus) {
        orderRepository.updateOrderStatus(orderId, newStatus);

        if ("SHIPPED".equalsIgnoreCase(newStatus)) {
            List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
            for (OrderItem item : items) {
                if (item.getVariantId() != null) {
                    productVariantService.deductStockOnFulfillment(item.getVariantId(), item.getQuantity());
                }
            }
        } else if ("CANCELLED".equalsIgnoreCase(newStatus)) {
            List<OrderItem> items = orderItemRepository.findByOrderId(orderId);
            for (OrderItem item : items) {
                if (item.getVariantId() != null) {
                    productVariantService.releaseStock(item.getVariantId(), item.getQuantity());
                }
            }
        }
    }

    @Transactional
    public void updatePaymentStatus(UUID orderId, String paymentStatus) {
        orderRepository.updatePaymentStatus(orderId, paymentStatus);
    }
}
