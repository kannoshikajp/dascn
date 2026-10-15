package joppe.backend.domain.order;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReturnRepository extends JpaRepository<Return, UUID> {

    Optional<Return> findByReturnCode(String returnCode);

    boolean existsByReturnCode(String returnCode);

    List<Return> findByOrderId(UUID orderId);

    @Modifying
    @Query("UPDATE Return r SET r.status = :status, r.completedAt = :completedAt WHERE r.id = :id")
    int updateReturnStatus(
            @Param("id") UUID id,
            @Param("status") String status,
            @Param("completedAt") OffsetDateTime completedAt);
}
