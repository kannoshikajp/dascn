package joppe.backend.domain.inventory;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface GoodItemRepository extends JpaRepository<GoodItem, UUID> {

    List<GoodItem> findByReceiptId(UUID receiptId);

    @Query("SELECT COALESCE(SUM(i.quantity * i.importPrice), 0) FROM GoodItem i WHERE i.receiptId = :receiptId")
    BigDecimal calculateReceiptTotal(@Param("receiptId") UUID receiptId);
}
