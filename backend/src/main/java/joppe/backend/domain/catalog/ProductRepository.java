package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository extends JpaRepository<Product, UUID> {

    Optional<Product> findBySlug(String slug);

    boolean existsBySlug(String slug);

    @Query("SELECT COUNT(DISTINCT p.id) FROM Product p LEFT JOIN ProductCategory pc ON p.id = pc.productId WHERE p.categoryId = :categoryId OR pc.categoryId = :categoryId")
    long countByCategoryId(@Param("categoryId") Integer categoryId);

    @Query("SELECT DISTINCT p FROM Product p LEFT JOIN ProductCategory pc ON p.id = pc.productId " +
           "WHERE (:categoryId IS NULL OR p.categoryId = :categoryId OR pc.categoryId = :categoryId) " +
           "AND (:brandId IS NULL OR p.brandId = :brandId) " +
           "AND (:isActive IS NULL OR p.isActive = :isActive) " +
           "ORDER BY p.createdAt DESC")
    List<Product> findFiltered(
            @Param("categoryId") Integer categoryId,
            @Param("brandId") Integer brandId,
            @Param("isActive") Boolean isActive
    );

    List<Product> findByCategoryIdAndIsActiveTrue(Integer categoryId);

    List<Product> findByBrandIdAndIsActiveTrue(Integer brandId);

    @Query("SELECT p.productName FROM Product p WHERE p.id = :id")
    Optional<String> findProductNameById(@Param("id") UUID id);

    @Query("SELECT p.warrantyMonths FROM Product p WHERE p.id = :id")
    Optional<Integer> findWarrantyMonthsById(@Param("id") UUID id);

    @Modifying
    @Query("UPDATE Product p SET p.isActive = :isActive WHERE p.id = :id")
    int updateActiveStatus(@Param("id") UUID id, @Param("isActive") boolean isActive);
}
