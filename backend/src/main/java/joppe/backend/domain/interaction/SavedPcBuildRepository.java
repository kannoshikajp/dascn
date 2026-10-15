package joppe.backend.domain.interaction;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface SavedPcBuildRepository extends JpaRepository<SavedPcBuild, UUID> {

    List<SavedPcBuild> findByUserId(UUID userId);

    List<SavedPcBuild> findByIsPublicTrue();

    Optional<SavedPcBuild> findByIdAndIsPublicTrue(UUID id);

    @Modifying
    @Query("UPDATE SavedPcBuild b SET b.isPublic = :isPublic WHERE b.id = :id AND b.userId = :userId")
    int updatePublicStatus(
            @Param("id") UUID id,
            @Param("userId") UUID userId,
            @Param("isPublic") boolean isPublic);
}
