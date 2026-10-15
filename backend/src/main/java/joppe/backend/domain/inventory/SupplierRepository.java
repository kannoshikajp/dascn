package joppe.backend.domain.inventory;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SupplierRepository extends JpaRepository<Supplier, UUID> {

    List<Supplier> findByIsActiveTrue();

    boolean existsBySupplierName(String supplierName);

    @Modifying
    @Query("UPDATE Supplier s SET s.isActive = :isActive WHERE s.id = :id")
    int updateActiveStatus(@Param("id") UUID id, @Param("isActive") boolean isActive);
}
