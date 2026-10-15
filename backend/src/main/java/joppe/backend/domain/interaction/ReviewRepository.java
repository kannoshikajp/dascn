package joppe.backend.domain.interaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ReviewRepository extends JpaRepository<Review, UUID> {

    List<Review> findByProductIdAndIsVisibleTrue(UUID productId);

    List<Review> findByUserId(UUID userId);

    @Query("SELECT AVG(r.ratingStar) FROM Review r WHERE r.productId = :productId AND r.isVisible = true")
    Optional<Double> findAverageRatingByProductId(@Param("productId") UUID productId);

    @Query("SELECT COUNT(r) FROM Review r WHERE r.productId = :productId AND r.isVisible = true")
    long countReviewsByProductId(@Param("productId") UUID productId);

    @Modifying
    @Query("UPDATE Review r SET r.isVisible = :isVisible WHERE r.id = :id")
    int updateVisibility(@Param("id") UUID id, @Param("isVisible") boolean isVisible);
}
