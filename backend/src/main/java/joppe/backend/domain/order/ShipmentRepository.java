package joppe.backend.domain.order;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ShipmentRepository extends JpaRepository<Shipment, UUID> {

    Optional<Shipment> findByOrderId(UUID orderId);

    Optional<Shipment> findByTrackingCode(String trackingCode);

    @Modifying
    @Query("UPDATE Shipment s SET s.shippingStatus = :status WHERE s.id = :id")
    int updateShippingStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Query("UPDATE Shipment s SET s.shippingStatus = 'SHIPPED', s.shippedAt = :shippedAt WHERE s.orderId = :orderId")
    int markAsShipped(@Param("orderId") UUID orderId, @Param("shippedAt") OffsetDateTime shippedAt);

    @Modifying
    @Query("UPDATE Shipment s SET s.shippingStatus = 'DELIVERED', s.deliveredAt = :deliveredAt WHERE s.orderId = :orderId")
    int markAsDelivered(@Param("orderId") UUID orderId, @Param("deliveredAt") OffsetDateTime deliveredAt);
}
