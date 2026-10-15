package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface CategoryRepository extends JpaRepository<Category, Integer> {

    Optional<Category> findBySlug(String slug);

    boolean existsBySlug(String slug);

    List<Category> findByParentId(Integer parentId);

    List<Category> findByIsActiveTrue();

    @Modifying
    @Query("UPDATE Category c SET c.isActive = :isActive WHERE c.id = :id")
    int updateActiveStatus(@Param("id") Integer id, @Param("isActive") boolean isActive);
}
