package joppe.backend.domain.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "returns")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Return {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "return_code", nullable = false, unique = true, length = 50)
    private String returnCode;

    @Column(name = "reason", nullable = false, length = 255)
    private String reason;

    @Column(name = "status", nullable = false, length = 50)
    @Builder.Default
    private String status = "REQUESTED";

    @Column(name = "refund_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal refundAmount = BigDecimal.ZERO;

    @Column(name = "requested_at", nullable = false, updatable = false)
    private OffsetDateTime requestedAt;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @PrePersist
    public void onPrePersist() {
        if (requestedAt == null) {
            requestedAt = OffsetDateTime.now();
        }
        if (status == null) {
            status = "REQUESTED";
        }
        if (refundAmount == null) {
            refundAmount = BigDecimal.ZERO;
        }
    }
}
