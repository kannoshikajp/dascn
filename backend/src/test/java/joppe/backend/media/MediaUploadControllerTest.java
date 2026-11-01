package joppe.backend.media;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import joppe.backend.media.controller.MediaUploadController;
import joppe.backend.media.dto.UploadResponse;
import joppe.backend.media.service.MediaStorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@ExtendWith(MockitoExtension.class)
class MediaUploadControllerTest {

    private MockMvc mockMvc;

    @Mock
    private MediaStorageService mediaStorageService;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new MediaUploadController(mediaStorageService))
                .build();
    }

    @Test
    void uploadWithFileSucceeds() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "sample-laptop.png",
                MediaType.IMAGE_PNG_VALUE,
                "sample-png-binary-data".getBytes()
        );

        when(mediaStorageService.store(any(), eq("descriptions"))).thenReturn(
                new UploadResponse(
                        UUID.randomUUID(),
                        "/uploads/descriptions/sample-laptop.png",
                        "sample-laptop.png",
                        1024L,
                        "image/png",
                        "descriptions",
                        OffsetDateTime.now()
                )
        );

        mockMvc.perform(multipart("/api/v1/media/upload")
                        .file(file)
                        .param("folder", "descriptions"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fileUrl", containsString("/uploads/descriptions/")))
                .andExpect(jsonPath("$.fileName").value("sample-laptop.png"))
                .andExpect(jsonPath("$.contentType").value("image/png"));
    }

    @Test
    void listMedia_Success() throws Exception {
        UploadResponse item = new UploadResponse(
                UUID.randomUUID(),
                "/uploads/products/sample.png",
                "sample.png",
                1024L,
                "image/png",
                "products",
                OffsetDateTime.now()
        );

        when(mediaStorageService.listMedia(eq("products"), any())).thenReturn(List.of(item));

        mockMvc.perform(get("/api/v1/media").param("folder", "products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].fileName").value("sample.png"))
                .andExpect(jsonPath("$[0].fileUrl").value("/uploads/products/sample.png"));
    }
}
