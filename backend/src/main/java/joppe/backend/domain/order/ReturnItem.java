package joppe.backend.domain.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "return_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReturnItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "return_id", nullable = false)
    private UUID returnId;

    @Column(name = "order_item_id", nullable = false)
    private UUID orderItemId;

    @Column(name = "quantity", nullable = false)
    private Integer quantity;

    @Column(name = "condition_status", length = 100)
    private String conditionStatus;

    @Column(name = "note", columnDefinition = "TEXT")
    private String note;
}
