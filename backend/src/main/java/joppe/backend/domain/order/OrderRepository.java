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

    Optional<Order> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByOrderCode(String orderCode);

    List<Order> findByUserIdOrderByCreatedAtDesc(UUID userId);

    List<Order> findByOrderStatusAndPaymentStatus(String orderStatus, String paymentStatus);

    @Query("SELECT o FROM Order o WHERE " +
           "(:orderStatus IS NULL OR o.orderStatus = :orderStatus) AND " +
           "(:paymentStatus IS NULL OR o.paymentStatus = :paymentStatus) AND " +
           "(:search IS NULL OR " +
           " LOWER(o.orderCode) LIKE :search OR " +
           " LOWER(o.recipientName) LIKE :search OR " +
           " LOWER(o.recipientPhone) LIKE :search) " +
           "ORDER BY o.createdAt DESC")
    List<Order> findFilteredOrders(
            @Param("orderStatus") String orderStatus,
            @Param("paymentStatus") String paymentStatus,
            @Param("search") String search
    );

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

    @Query("SELECT COALESCE(SUM(o.finalAmount), 0) FROM Order o WHERE o.orderStatus NOT IN ('REFUND', 'CANCELLED')")
    BigDecimal calculateTotalRevenue();

    @Query("SELECT COALESCE(SUM(o.finalAmount), 0) FROM Order o WHERE o.orderStatus IN ('ACCEPTED', 'PACKAGING', 'DELIVERY', 'PENDING')")
    BigDecimal calculatePendingRevenue();

    @Query("SELECT COUNT(o) FROM Order o WHERE o.orderStatus IN ('ACCEPTED', 'PACKAGING', 'DELIVERY', 'PENDING')")
    long countPendingOrders();

    @Query("SELECT o FROM Order o WHERE o.createdAt >= :since ORDER BY o.createdAt ASC")
    List<Order> findOrdersSince(@Param("since") java.time.OffsetDateTime since);

    List<Order> findTop5ByOrderByCreatedAtDesc();
}
