package joppe.backend.domain.user.dto;

import java.time.OffsetDateTime;
import java.util.UUID;
import joppe.backend.domain.user.UserAddress;

public record AddressResponse(
        UUID id,
        UUID userId,
        String recipientName,
        String recipientPhone,
        String streetAddress,
        String ward,
        String district,
        String province,
        Boolean isDefault,
        OffsetDateTime createdAt
) {
    public static AddressResponse fromEntity(UserAddress address) {
        return new AddressResponse(
                address.getId(),
                address.getUserId(),
                address.getRecipientName(),
                address.getRecipientPhone(),
                address.getStreetAddress(),
                address.getWard(),
                address.getDistrict(),
                address.getProvince(),
                address.getIsDefault(),
                address.getCreatedAt()
        );
    }
}
