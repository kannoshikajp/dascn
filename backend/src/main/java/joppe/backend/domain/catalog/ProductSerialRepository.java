package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ProductSerialRepository extends JpaRepository<ProductSerial, UUID> {

    Optional<ProductSerial> findBySerialNumber(String serialNumber);

    List<ProductSerial> findByVariantIdAndStatus(UUID variantId, String status);

    List<ProductSerial> findByOrderItemId(UUID orderItemId);

    List<ProductSerial> findBySerialNumberIn(List<String> serialNumbers);

    boolean existsBySerialNumber(String serialNumber);
}
