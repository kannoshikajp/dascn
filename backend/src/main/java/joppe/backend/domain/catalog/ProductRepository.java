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
