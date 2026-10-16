package joppe.backend.media.dto;

public record UploadResponse(
        String fileUrl,
        String fileName,
        long fileSize,
        String contentType
) {}
