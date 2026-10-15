package joppe.backend.domain.catalog;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductImageRepository extends JpaRepository<ProductImage, UUID> {

    List<ProductImage> findByProductIdOrderByDisplayOrderAsc(UUID productId);

    List<ProductImage> findByVariantIdOrderByDisplayOrderAsc(UUID variantId);
}
