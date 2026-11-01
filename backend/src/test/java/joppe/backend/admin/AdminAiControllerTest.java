package joppe.backend.admin;

import java.util.List;
import joppe.backend.admin.ai.controller.AdminAiController;
import joppe.backend.admin.ai.dto.AdminAiChatRequest;
import joppe.backend.admin.ai.dto.AdminAiChatResponse;
import joppe.backend.admin.ai.dto.AdminAiChatResponse.ReferencedProductDto;
import joppe.backend.admin.ai.service.AdminAiAdvisorService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AdminAiControllerTest {

    private MockMvc mockMvc;

    @Mock
    private AdminAiAdvisorService adminAiAdvisorService;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new AdminAiController(adminAiAdvisorService))
                .build();
    }

    @Test
    void chat_returnsHttp200AndAiResponse() throws Exception {
        AdminAiChatResponse mockResponse = new AdminAiChatResponse(
                "Sản phẩm RTX 4070 đang có 15 cái trong kho.",
                List.of(new ReferencedProductDto("p-1", "GPU-RTX4070", "RTX 4070 OC", 16000000L, 17500000L, 15)),
                List.of("search_products")
        );

        when(adminAiAdvisorService.chat(any(AdminAiChatRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/admin/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "message": "Kiểm tra tồn kho RTX 4070"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.answer").value("Sản phẩm RTX 4070 đang có 15 cái trong kho."))
                .andExpect(jsonPath("$.referencedProducts[0].sku").value("GPU-RTX4070"))
                .andExpect(jsonPath("$.executedTools[0]").value("search_products"));
    }
}
