package joppe.backend.domain.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import joppe.backend.domain.ai.controller.CustomerAiController;
import joppe.backend.domain.ai.dto.CustomerAiChatRequest;
import joppe.backend.domain.ai.dto.CustomerAiChatResponse;
import joppe.backend.domain.ai.dto.CustomerAiChatResponse.ReferencedProductDto;
import joppe.backend.domain.ai.service.CustomerAiAdvisorService;
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
class CustomerAiControllerTest {

    private MockMvc mockMvc;

    @Mock
    private CustomerAiAdvisorService customerAiAdvisorService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new CustomerAiController(customerAiAdvisorService))
                .build();
    }

    @Test
    void chat_returnsHttp200AndCustomerAiResponse() throws Exception {
        CustomerAiChatResponse mockResponse = new CustomerAiChatResponse(
                "Cấu hình i5 13400F + RTX 4060 rất cân bằng, chiến mượt 1080p và 2K.",
                List.of(new ReferencedProductDto("p-1", "CPU-I5-13400F", "Intel Core i5-13400F", 5200000L, 5500000L, 10)),
                List.of("Tối ưu chi phí", "Nâng lên 32GB RAM"),
                List.of("search_products")
        );

        when(customerAiAdvisorService.chat(any(CustomerAiChatRequest.class))).thenReturn(mockResponse);

        CustomerAiChatRequest request = new CustomerAiChatRequest("Tư vấn PC 20 triệu", List.of());

        mockMvc.perform(post("/api/v1/ai/chat")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.answer").value("Cấu hình i5 13400F + RTX 4060 rất cân bằng, chiến mượt 1080p và 2K."))
                .andExpect(jsonPath("$.referencedProducts[0].sku").value("CPU-I5-13400F"))
                .andExpect(jsonPath("$.quickReplies[0]").value("Tối ưu chi phí"))
                .andExpect(jsonPath("$.executedTools[0]").value("search_products"));
    }
}
