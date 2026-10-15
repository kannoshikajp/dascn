package joppe.backend.domain.promotion;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, UUID> {

    Optional<Promotion> findByCode(String code);

    boolean existsByCode(String code);

    @Modifying
    @Query("UPDATE Promotion p SET p.usageLimit = p.usageLimit - 1 WHERE p.id = :id AND p.usageLimit > 0")
    int decrementUsageLimit(@Param("id") UUID id);

    @Modifying
    @Query("UPDATE Promotion p SET p.isActive = :isActive WHERE p.id = :id")
    int updateActiveStatus(@Param("id") UUID id, @Param("isActive") boolean isActive);
}
