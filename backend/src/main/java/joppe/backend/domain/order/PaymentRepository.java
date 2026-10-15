package joppe.backend.domain.order;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PaymentRepository extends JpaRepository<Payment, UUID> {

    List<Payment> findByOrderId(UUID orderId);

    Optional<Payment> findByTransactionCode(String transactionCode);

    @Modifying
    @Query("UPDATE Payment p SET p.status = :status, p.gatewayResponse = :response, p.paidAt = :paidAt WHERE p.id = :id")
    int updatePaymentResult(
            @Param("id") UUID id,
            @Param("status") String status,
            @Param("response") String response,
            @Param("paidAt") OffsetDateTime paidAt);
}
