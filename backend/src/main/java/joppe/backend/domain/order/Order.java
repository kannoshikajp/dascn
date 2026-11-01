package joppe.backend.domain.order;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
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
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "order_code", nullable = false, unique = true, length = 50)
    private String orderCode;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "promotion_id")
    private UUID promotionId;

    @Column(name = "order_channel", nullable = false, length = 30)
    @Builder.Default
    private String orderChannel = "ONLINE";

    @Column(name = "order_status", nullable = false, length = 50)
    @Builder.Default
    private String orderStatus = "ACCEPTED";

    @Column(name = "payment_status", nullable = false, length = 50)
    @Builder.Default
    private String paymentStatus = "PAID";

    @Column(name = "paid_at")
    private OffsetDateTime paidAt;

    @Column(name = "delivered_at")
    private OffsetDateTime deliveredAt;

    @Column(name = "recipient_name", nullable = false, length = 150)
    private String recipientName;

    @Column(name = "recipient_phone", nullable = false, length = 20)
    private String recipientPhone;

    @Column(name = "shipping_address", nullable = false, columnDefinition = "TEXT")
    private String shippingAddress;

    @Column(name = "subtotal_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal subtotalAmount = BigDecimal.ZERO;

    @Column(name = "discount_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "shipping_fee", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal shippingFee = BigDecimal.ZERO;

    @Column(name = "final_amount", nullable = false, precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal finalAmount = BigDecimal.ZERO;

    @Column(name = "customer_note", columnDefinition = "TEXT")
    private String customerNote;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    public void onPrePersist() {
        OffsetDateTime now = OffsetDateTime.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
        if (orderChannel == null) {
            orderChannel = "ONLINE";
        }
        if (orderStatus == null) {
            orderStatus = "ACCEPTED";
        }
        if (paymentStatus == null) {
            paymentStatus = "PAID";
        }
        if ("PAID".equalsIgnoreCase(paymentStatus) && paidAt == null) {
            paidAt = now;
        }
        if (("SHIPPED".equalsIgnoreCase(orderStatus) || "SHOWROOM_BUY".equalsIgnoreCase(orderStatus)) && deliveredAt == null) {
            deliveredAt = now;
        }
        if (subtotalAmount == null) {
            subtotalAmount = BigDecimal.ZERO;
        }
        if (discountAmount == null) {
            discountAmount = BigDecimal.ZERO;
        }
        if (shippingFee == null) {
            shippingFee = BigDecimal.ZERO;
        }
        if (finalAmount == null) {
            finalAmount = BigDecimal.ZERO;
        }
    }

    @PreUpdate
    public void onPreUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
