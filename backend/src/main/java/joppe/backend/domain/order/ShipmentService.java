package joppe.backend.domain.order;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ShipmentService {

    private final ShipmentRepository shipmentRepository;
    private final OrderRepository orderRepository;

    @Transactional
    public UUID createShipment(UUID orderId, String shippingProvider, String trackingCode) {
        if (!orderRepository.existsById(orderId)) {
            throw new IllegalArgumentException("Order not found with ID: " + orderId);
        }

        Shipment shipment = Shipment.builder()
                .orderId(orderId)
                .shippingProvider(shippingProvider)
                .trackingCode(trackingCode)
                .shippingStatus("READY")
                .build();

        return shipmentRepository.save(shipment).getId();
    }

    @Transactional
    public void markShipped(UUID orderId) {
        OffsetDateTime now = OffsetDateTime.now();
        shipmentRepository.markAsShipped(orderId, now);
        orderRepository.updateOrderStatus(orderId, "SHIPPED");
    }

    @Transactional
    public void markDelivered(UUID orderId) {
        OffsetDateTime now = OffsetDateTime.now();
        shipmentRepository.markAsDelivered(orderId, now);
        orderRepository.updateOrderStatus(orderId, "DELIVERED");
    }

    @Transactional(readOnly = true)
    public Optional<Shipment> getShipmentByOrder(UUID orderId) {
        return shipmentRepository.findByOrderId(orderId);
    }
}
