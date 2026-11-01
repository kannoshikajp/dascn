package joppe.backend.domain.catalog;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductVariantRepository extends JpaRepository<ProductVariant, UUID> {

    Optional<ProductVariant> findBySku(String sku);

    boolean existsBySku(String sku);

    List<ProductVariant> findByProductId(UUID productId);

    List<ProductVariant> findByProductIdAndIsActiveTrue(UUID productId);

    @Query("SELECT v.salePrice FROM ProductVariant v WHERE v.id = :id")
    Optional<BigDecimal> findSalePriceById(@Param("id") UUID id);

    @Query("SELECT (v.quantityOnHand - v.quantityReserved) FROM ProductVariant v WHERE v.id = :id")
    Optional<Integer> findAvailableQuantityById(@Param("id") UUID id);

    @Modifying
    @Query("UPDATE ProductVariant v SET v.quantityReserved = v.quantityReserved + :qty WHERE v.id = :id AND (v.quantityOnHand - v.quantityReserved) >= :qty")
    int reserveStock(@Param("id") UUID id, @Param("qty") int qty);

    @Modifying
    @Query("UPDATE ProductVariant v SET v.quantityReserved = v.quantityReserved - :qty WHERE v.id = :id AND v.quantityReserved >= :qty")
    int releaseStock(@Param("id") UUID id, @Param("qty") int qty);

    @Modifying
    @Query("UPDATE ProductVariant v SET v.quantityOnHand = v.quantityOnHand - :qty, v.quantityReserved = v.quantityReserved - :qty WHERE v.id = :id AND v.quantityReserved >= :qty")
    int deductStockOnFulfillment(@Param("id") UUID id, @Param("qty") int qty);

    @Modifying
    @Query("UPDATE ProductVariant v SET v.quantityOnHand = v.quantityOnHand + :qty WHERE v.id = :id")
    int addStock(@Param("id") UUID id, @Param("qty") int qty);

    @Modifying
    @Query("UPDATE ProductVariant v SET v.salePrice = :salePrice WHERE v.id = :id")
    int updateSalePrice(@Param("id") UUID id, @Param("salePrice") BigDecimal salePrice);

    @Query("SELECT COUNT(v) FROM ProductVariant v WHERE v.quantityOnHand <= 0")
    long countOutOfStockVariants();

    @Query("SELECT COUNT(v) FROM ProductVariant v WHERE v.quantityOnHand > 0 AND v.quantityOnHand <= v.reorderLevel")
    long countLowStockVariants();

    @Query("SELECT COUNT(v) FROM ProductVariant v WHERE v.quantityOnHand > v.reorderLevel")
    long countHealthyStockVariants();
}
