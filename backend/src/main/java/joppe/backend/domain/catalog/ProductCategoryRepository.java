package joppe.backend.domain.catalog;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductCategoryRepository extends JpaRepository<ProductCategory, ProductCategoryId> {

    List<ProductCategory> findByProductId(UUID productId);

    List<ProductCategory> findByCategoryId(Integer categoryId);

    @Modifying
    @Query("DELETE FROM ProductCategory pc WHERE pc.productId = :productId")
    void deleteByProductId(@Param("productId") UUID productId);

    @Query("SELECT pc.productId FROM ProductCategory pc WHERE pc.categoryId = :categoryId")
    List<UUID> findProductIdsByCategoryId(@Param("categoryId") Integer categoryId);

    @Query("SELECT pc.categoryId FROM ProductCategory pc WHERE pc.productId = :productId")
    List<Integer> findCategoryIdsByProductId(@Param("productId") UUID productId);

    boolean existsByCategoryId(Integer categoryId);

    long countByCategoryId(Integer categoryId);
}
