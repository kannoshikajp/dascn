package joppe.backend.domain.order;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<Order, UUID> {

    Optional<Order> findByOrderCode(String orderCode);

    boolean existsByOrderCode(String orderCode);

    List<Order> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Order> findByOrderStatusAndPaymentStatus(String orderStatus, String paymentStatus);

    @Query("SELECT o.finalAmount FROM Order o WHERE o.id = :id")
    Optional<BigDecimal> findFinalAmountById(@Param("id") UUID id);

    @Query("SELECT o.orderStatus FROM Order o WHERE o.id = :id")
    Optional<String> findOrderStatusById(@Param("id") UUID id);

    @Modifying
    @Query("UPDATE Order o SET o.orderStatus = :status, o.updatedAt = CURRENT_TIMESTAMP WHERE o.id = :id")
    int updateOrderStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Query("UPDATE Order o SET o.paymentStatus = :status, o.updatedAt = CURRENT_TIMESTAMP WHERE o.id = :id")
    int updatePaymentStatus(@Param("id") UUID id, @Param("status") String status);
}
