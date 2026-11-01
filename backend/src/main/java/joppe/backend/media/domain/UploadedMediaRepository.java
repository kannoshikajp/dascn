package joppe.backend.media.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UploadedMediaRepository extends JpaRepository<UploadedMedia, UUID> {

    List<UploadedMedia> findAllByOrderByCreatedAtDesc();

    List<UploadedMedia> findByFolderOrderByCreatedAtDesc(String folder);

    Optional<UploadedMedia> findByFileUrl(String fileUrl);
}
