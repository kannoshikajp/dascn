package joppe.backend.domain.inventory.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import joppe.backend.domain.inventory.Supplier;

public record SupplierResponse(
        UUID id,
        String supplierName,
        String contactPerson,
        String phoneNumber,
        String email,
        String address,
        Boolean isActive,
        OffsetDateTime createdAt
) {
    public static SupplierResponse fromEntity(Supplier s) {
        return new SupplierResponse(
                s.getId(),
                s.getSupplierName(),
                s.getContactPerson(),
                s.getPhoneNumber(),
                s.getEmail(),
                s.getAddress(),
                s.getIsActive(),
                s.getCreatedAt()
        );
    }
}
