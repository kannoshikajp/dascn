package joppe.backend.domain.catalog;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface VariantMediaRepository extends JpaRepository<VariantMedia, VariantMediaId> {

    List<VariantMedia> findByVariantIdOrderByDisplayOrderAsc(UUID variantId);

    List<VariantMedia> findByVariantIdInOrderByDisplayOrderAsc(List<UUID> variantIds);

    @Modifying
    @Query("DELETE FROM VariantMedia vm WHERE vm.variantId = :variantId")
    void deleteByVariantId(@Param("variantId") UUID variantId);

    @Modifying
    @Query("DELETE FROM VariantMedia vm WHERE vm.variantId IN :variantIds")
    void deleteByVariantIdIn(@Param("variantIds") List<UUID> variantIds);
}
