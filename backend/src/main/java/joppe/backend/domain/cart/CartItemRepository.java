package joppe.backend.domain.cart;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CartItemRepository extends JpaRepository<CartItem, UUID> {

    List<CartItem> findByUserId(UUID userId);

    Optional<CartItem> findByUserIdAndVariantId(UUID userId, UUID variantId);

    boolean existsByUserIdAndVariantId(UUID userId, UUID variantId);

    @Modifying
    @Query("UPDATE CartItem c SET c.quantity = :quantity, c.updatedAt = CURRENT_TIMESTAMP WHERE c.id = :id")
    int updateQuantity(@Param("id") UUID id, @Param("quantity") int quantity);

    @Modifying
    @Query("UPDATE CartItem c SET c.quantity = c.quantity + :delta, c.updatedAt = CURRENT_TIMESTAMP WHERE c.userId = :userId AND c.variantId = :variantId")
    int addQuantity(@Param("userId") UUID userId, @Param("variantId") UUID variantId, @Param("delta") int delta);

    @Modifying
    @Query("DELETE FROM CartItem c WHERE c.userId = :userId")
    int deleteByUserId(@Param("userId") UUID userId);

    @Modifying
    @Query("DELETE FROM CartItem c WHERE c.userId = :userId AND c.variantId = :variantId")
    int deleteByUserIdAndVariantId(@Param("userId") UUID userId, @Param("variantId") UUID variantId);
}
