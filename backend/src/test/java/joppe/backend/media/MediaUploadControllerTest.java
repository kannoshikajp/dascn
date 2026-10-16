package joppe.backend.media;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import javax.sql.DataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest(properties = {
    "spring.flyway.enabled=false",
    "spring.jpa.hibernate.ddl-auto=none",
    "app.admin.auto-create=false",
    "app.upload.dir=target/test-uploads"
})
class MediaUploadControllerTest {

    @MockitoBean
    private DataSource dataSource;

    @Autowired
    private WebApplicationContext context;

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    void uploadWithoutAuthFails() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "test.png",
                MediaType.IMAGE_PNG_VALUE,
                "fake image content".getBytes()
        );

        mockMvc.perform(multipart("/api/v1/media/upload").file(file))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "admin@joppe.vn", roles = {"ADMIN"})
    void uploadWithAuthSucceeds() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "sample-laptop.png",
                MediaType.IMAGE_PNG_VALUE,
                "sample-png-binary-data".getBytes()
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
    @WithMockUser(username = "admin@joppe.vn", roles = {"ADMIN"})
    void uploadJpgImageSucceeds() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "laptop-photo.jpg",
                "image/jpeg",
                "sample-jpg-binary-data".getBytes()
        );

        mockMvc.perform(multipart("/api/v1/media/upload")
                        .file(file)
                        .param("folder", "products"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fileUrl", containsString("/uploads/products/")))
                .andExpect(jsonPath("$.fileName").value("laptop-photo.jpg"))
                .andExpect(jsonPath("$.contentType").value("image/jpeg"));
    }

    @Test
    @WithMockUser(username = "admin@joppe.vn", roles = {"ADMIN"})
    void uploadJpgWithOctetStreamFallbackSucceeds() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "photo.jpeg",
                MediaType.APPLICATION_OCTET_STREAM_VALUE,
                "sample-jpeg-binary-data".getBytes()
        );

        mockMvc.perform(multipart("/api/v1/media/upload")
                        .file(file))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fileUrl", containsString("/uploads/general/")))
                .andExpect(jsonPath("$.fileName").value("photo.jpeg"))
                .andExpect(jsonPath("$.contentType").value("image/jpeg"));
    }
}
