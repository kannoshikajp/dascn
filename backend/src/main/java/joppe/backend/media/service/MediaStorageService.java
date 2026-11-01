package joppe.backend.media.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import joppe.backend.media.domain.UploadedMedia;
import joppe.backend.media.domain.UploadedMediaRepository;
import joppe.backend.media.dto.UploadResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

@Service
@Slf4j
public class MediaStorageService {

    private static final Set<String> ALLOWED_FOLDERS = Set.of(
            "products",
            "descriptions",
            "categories",
            "brands",
            "avatars",
            "general"
    );

    private static final Map<String, String> MIME_TO_EXTENSION = Map.of(
            "image/jpeg", ".jpg",
            "image/jpg", ".jpg",
            "image/pjpeg", ".jpg",
            "image/png", ".png",
            "image/x-png", ".png",
            "image/webp", ".webp",
            "image/gif", ".gif",
            "image/svg+xml", ".svg"
    );

    private static final Map<String, String> EXTENSION_TO_MIME = Map.of(
            ".jpg", "image/jpeg",
            ".jpeg", "image/jpeg",
            ".png", "image/png",
            ".webp", "image/webp",
            ".gif", "image/gif",
            ".svg", "image/svg+xml"
    );

    private final Path rootUploadPath;
    private final UploadedMediaRepository uploadedMediaRepository;

    public MediaStorageService(
            @Value("${app.upload.dir:uploads}") String uploadDir,
            UploadedMediaRepository uploadedMediaRepository) {
        this.rootUploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        this.uploadedMediaRepository = uploadedMediaRepository;
        try {
            Files.createDirectories(this.rootUploadPath);
        } catch (IOException e) {
            log.error("Could not initialize root media directory: {}", this.rootUploadPath, e);
            throw new IllegalStateException("Failed to initialize upload directory", e);
        }
    }

    @Transactional
    public UploadResponse store(MultipartFile file, String folder) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Cannot upload empty file");
        }

        String targetFolder = (folder == null || folder.isBlank()) ? "general" : folder.toLowerCase().trim();
        if (!ALLOWED_FOLDERS.contains(targetFolder)) {
            targetFolder = "general";
        }

        String originalFilename = StringUtils.cleanPath(
                file.getOriginalFilename() != null ? file.getOriginalFilename() : "image"
        );

        String rawContentType = file.getContentType();
        String contentType = rawContentType != null ? rawContentType.split(";")[0].trim().toLowerCase() : null;

        String extension = null;
        if (contentType != null && MIME_TO_EXTENSION.containsKey(contentType)) {
            extension = MIME_TO_EXTENSION.get(contentType);
        } else {
            // Fallback: detect MIME and extension from original filename
            int lastDot = originalFilename.lastIndexOf('.');
            if (lastDot >= 0) {
                String fileExt = originalFilename.substring(lastDot).toLowerCase();
                if (EXTENSION_TO_MIME.containsKey(fileExt)) {
                    extension = fileExt.equals(".jpeg") ? ".jpg" : fileExt;
                    contentType = EXTENSION_TO_MIME.get(fileExt);
                }
            }
        }

        if (extension == null || contentType == null) {
            throw new IllegalArgumentException("Unsupported image format. Allowed: JPEG, PNG, WebP, GIF, SVG");
        }
        String uniqueFilename = UUID.randomUUID().toString() + extension;

        Path targetDir = this.rootUploadPath.resolve(targetFolder).normalize();
        try {
            Files.createDirectories(targetDir);
            Path destinationFile = targetDir.resolve(uniqueFilename).normalize();

            // Guard against path traversal
            if (!destinationFile.startsWith(this.rootUploadPath)) {
                throw new SecurityException("Cannot store file outside current media directory");
            }

            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, destinationFile, StandardCopyOption.REPLACE_EXISTING);
            }

            String relativeUrl = "/uploads/" + targetFolder + "/" + uniqueFilename;
            log.info("Stored uploaded image: {} as {} ({} bytes)", originalFilename, relativeUrl, file.getSize());

            UploadedMedia media = UploadedMedia.builder()
                    .fileUrl(relativeUrl)
                    .fileName(originalFilename)
                    .fileSize(file.getSize())
                    .contentType(contentType)
                    .folder(targetFolder)
                    .build();

            UploadedMedia saved = uploadedMediaRepository.save(media);

            return new UploadResponse(
                    saved.getId(),
                    saved.getFileUrl(),
                    saved.getFileName(),
                    saved.getFileSize(),
                    saved.getContentType(),
                    saved.getFolder(),
                    saved.getCreatedAt()
            );
        } catch (IOException e) {
            log.error("Failed to store uploaded media file", e);
            throw new RuntimeException("Failed to store file: " + e.getMessage(), e);
        }
    }

    @Transactional(readOnly = true)
    public List<UploadResponse> listMedia(String folder, String search) {
        String cleanFolder = (folder != null && !folder.isBlank()) ? folder.trim().toLowerCase(java.util.Locale.ROOT) : null;
        String cleanSearch = (search != null && !search.isBlank()) ? search.trim().toLowerCase(java.util.Locale.ROOT) : null;

        List<UploadedMedia> mediaList;
        if (cleanFolder != null && !cleanFolder.equals("all")) {
            mediaList = uploadedMediaRepository.findByFolderOrderByCreatedAtDesc(cleanFolder);
        } else {
            mediaList = uploadedMediaRepository.findAllByOrderByCreatedAtDesc();
        }

        if (cleanSearch != null) {
            mediaList = mediaList.stream()
                    .filter(m -> m.getFileName() != null && m.getFileName().toLowerCase(java.util.Locale.ROOT).contains(cleanSearch))
                    .toList();
        }

        return mediaList.stream()
                .map(m -> new UploadResponse(
                        m.getId(),
                        m.getFileUrl(),
                        m.getFileName(),
                        m.getFileSize(),
                        m.getContentType(),
                        m.getFolder(),
                        m.getCreatedAt()
                ))
                .toList();
    }
}
