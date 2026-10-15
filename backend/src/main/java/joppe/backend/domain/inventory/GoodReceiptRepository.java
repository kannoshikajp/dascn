package joppe.backend.domain.inventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface GoodReceiptRepository extends JpaRepository<GoodReceipt, UUID> {

    Optional<GoodReceipt> findByReceiptCode(String receiptCode);

    boolean existsByReceiptCode(String receiptCode);

    List<GoodReceipt> findBySupplierId(UUID supplierId);

    List<GoodReceipt> findByStaffId(UUID staffId);

    @Modifying
    @Query("UPDATE GoodReceipt r SET r.status = :status WHERE r.id = :id")
    int updateStatus(@Param("id") UUID id, @Param("status") String status);

    @Modifying
    @Query("UPDATE GoodReceipt r SET r.totalAmount = :total WHERE r.id = :id")
    int updateTotalAmount(@Param("id") UUID id, @Param("total") BigDecimal total);
}
