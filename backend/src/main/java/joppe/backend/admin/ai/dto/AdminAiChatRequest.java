package joppe.backend.admin.ai.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record AdminAiChatRequest(
        @NotBlank(message = "Message must not be blank")
        String message,
        List<ChatMessageDto> history
) {
    public record ChatMessageDto(
            String role,
            String content
    ) {}
}
