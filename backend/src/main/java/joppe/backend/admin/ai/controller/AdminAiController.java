package joppe.backend.admin.ai.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import joppe.backend.admin.ai.dto.AdminAiChatRequest;
import joppe.backend.admin.ai.dto.AdminAiChatResponse;
import joppe.backend.admin.ai.service.AdminAiAdvisorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/ai")
@RequiredArgsConstructor
@Tag(name = "Admin - AI Operations Advisor", description = "Endpoints for AI-driven inventory audits, catalog queries, and analytics via 9Router")
@PreAuthorize("isAuthenticated()")
public class AdminAiController {

    private final AdminAiAdvisorService adminAiAdvisorService;

    @PostMapping("/chat")
    @Operation(summary = "Ask Joppe AI Operations Advisor via 9Router tool calling")
    public ResponseEntity<AdminAiChatResponse> chat(@Valid @RequestBody AdminAiChatRequest request) {
        AdminAiChatResponse response = adminAiAdvisorService.chat(request);
        return ResponseEntity.ok(response);
    }
}
