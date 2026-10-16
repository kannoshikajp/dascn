package joppe.backend.media.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import joppe.backend.media.dto.UploadResponse;
import joppe.backend.media.service.MediaStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
@Tag(name = "Media & Uploads", description = "Endpoints for uploading images and static assets for catalog, markdown descriptions, and profiles")
public class MediaUploadController {

    private final MediaStorageService mediaStorageService;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    @Operation(
            summary = "Upload image file (JPEG, PNG, WebP, GIF, SVG)",
            description = "Accepts a multipart image file and stores it in the designated folder. Returns the public relative URL.",
            responses = {
                    @ApiResponse(
                            responseCode = "201",
                            description = "Image uploaded successfully",
                            content = @Content(schema = @Schema(implementation = UploadResponse.class))
                    ),
                    @ApiResponse(responseCode = "400", description = "Invalid file or unsupported format"),
                    @ApiResponse(responseCode = "401", description = "Unauthorized")
            }
    )
    public ResponseEntity<UploadResponse> upload(
            @Parameter(description = "Image file to upload", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(description = "Target asset folder (e.g. products, descriptions, categories, avatars)")
            @RequestParam(value = "folder", required = false, defaultValue = "general") String folder
    ) {
        UploadResponse response = mediaStorageService.store(file, folder);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
