package joppe.backend.domain.cart.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record MergeCartRequest(
        @NotEmpty(message = "Items list cannot be empty")
        List<@Valid MergeCartItemInput> items
) {
}
