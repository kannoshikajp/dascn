package joppe.backend.domain.catalog;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class VariantMediaId implements Serializable {

    private UUID variantId;
    private UUID mediaId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        VariantMediaId that = (VariantMediaId) o;
        return Objects.equals(variantId, that.variantId) && Objects.equals(mediaId, that.mediaId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(variantId, mediaId);
    }
}
