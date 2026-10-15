package joppe.backend.domain.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "shipments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Shipment {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "order_id", nullable = false, unique = true)
    private UUID orderId;

    @Column(name = "shipping_provider", nullable = false, length = 100)
    private String shippingProvider;

    @Column(name = "tracking_code", unique = true, length = 100)
    private String trackingCode;

    @Column(name = "shipping_status", nullable = false, length = 50)
    @Builder.Default
    private String shippingStatus = "READY";

    @Column(name = "shipped_at")
    private OffsetDateTime shippedAt;

    @Column(name = "delivered_at")
    private OffsetDateTime deliveredAt;

    @PrePersist
    public void onPrePersist() {
        if (shippingStatus == null) {
            shippingStatus = "READY";
        }
    }
}
