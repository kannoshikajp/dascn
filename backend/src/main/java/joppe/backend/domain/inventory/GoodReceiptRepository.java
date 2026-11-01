package joppe.backend.domain.inventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface GoodReceiptRepository extends JpaRepository<GoodReceipt, UUID> {

    Optional<GoodReceipt> findByReceiptCode(String receiptCode);

    boolean existsByReceiptCode(String receiptCode);

    Optional<GoodReceipt> findByOrderId(UUID orderId);

    boolean existsByOrderId(UUID orderId);

    List<GoodReceipt> findBySupplierId(UUID supplierId);

    List<GoodReceipt> findByStaffId(UUID staffId);

    @Query("SELECT r FROM GoodReceipt r WHERE " +
           "(:receiptType IS NULL OR r.receiptType = :receiptType) AND " +
           "(:status IS NULL OR r.status = :status) AND " +
           "(:supplierId IS NULL OR r.supplierId = :supplierId) AND " +
           "(:search IS NULL OR LOWER(r.receiptCode) LIKE :search OR (r.note IS NOT NULL AND LOWER(r.note) LIKE :search)) " +
           "ORDER BY r.createdAt DESC")
    List<GoodReceipt> findFiltered(
            @Param("receiptType") String receiptType,
            @Param("status") String status,
            @Param("supplierId") UUID supplierId,
            @Param("search") String search
    );

    @Modifying
    @Query("UPDATE GoodReceipt r SET r.status = :status WHERE r.id = :id")
    int updateStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Query("UPDATE GoodReceipt r SET r.totalAmount = :total WHERE r.id = :id")
    int updateTotalAmount(@Param("id") UUID id, @Param("total") BigDecimal total);
}
