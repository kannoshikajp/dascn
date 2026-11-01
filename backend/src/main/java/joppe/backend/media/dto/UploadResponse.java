package joppe.backend.media.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public record UploadResponse(
        UUID id,
        String fileUrl,
        String fileName,
        long fileSize,
        String contentType,
        String folder,
        OffsetDateTime createdAt
) {
    public UploadResponse(String fileUrl, String fileName, long fileSize, String contentType) {
        this(null, fileUrl, fileName, fileSize, contentType, "general", OffsetDateTime.now());
    }
}
