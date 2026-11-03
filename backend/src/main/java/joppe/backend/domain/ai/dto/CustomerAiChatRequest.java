package joppe.backend.domain.ai.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public record CustomerAiChatRequest(
        @NotBlank(message = "Message must not be blank")
        String message,
        List<HistoryMessageDto> history
) {
    public record HistoryMessageDto(String role, String content) {}
}
