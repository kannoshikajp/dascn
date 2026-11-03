package joppe.backend.domain.ai.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import joppe.backend.domain.ai.dto.CustomerAiChatRequest;
import joppe.backend.domain.ai.dto.CustomerAiChatResponse;
import joppe.backend.domain.ai.service.CustomerAiAdvisorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
@Tag(name = "Customer - AI Advisor", description = "Public AI assistant for PC building, hardware compatibility check, and product recommendations")
public class CustomerAiController {

    private final CustomerAiAdvisorService customerAiAdvisorService;

    @PostMapping("/chat")
    @Operation(summary = "Chat with Joppe AI hardware advisor")
    public ResponseEntity<CustomerAiChatResponse> chat(@Valid @RequestBody CustomerAiChatRequest request) {
        CustomerAiChatResponse response = customerAiAdvisorService.chat(request);
        return ResponseEntity.ok(response);
    }
}
