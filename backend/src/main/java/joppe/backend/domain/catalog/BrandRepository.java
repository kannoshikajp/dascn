package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface BrandRepository extends JpaRepository<Brand, Integer> {

    Optional<Brand> findBySlug(String slug);

    boolean existsByBrandName(String brandName);

    boolean existsBySlug(String slug);

    List<Brand> findByIsActiveTrue();

    @Modifying
    @Query("UPDATE Brand b SET b.isActive = :isActive WHERE b.id = :id")
    int updateActiveStatus(@Param("id") Integer id, @Param("isActive") boolean isActive);
}
