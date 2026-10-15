package joppe.backend.domain.inventory;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "good_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GoodItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "receipt_id", nullable = false)
    private UUID receiptId;

    @Column(name = "variant_id", nullable = false)
    private UUID variantId;

    @Column(name = "quantity", nullable = false)
    @Builder.Default
    private Integer quantity = 1;

    @Column(name = "import_price", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal importPrice = BigDecimal.ZERO;

    @PrePersist
    public void onPrePersist() {
        if (quantity == null) {
            quantity = 1;
        }
        if (importPrice == null) {
            importPrice = BigDecimal.ZERO;
        }
    }
}
