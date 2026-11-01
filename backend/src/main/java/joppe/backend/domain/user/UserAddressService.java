package joppe.backend.domain.user;

import java.util.List;
import java.util.UUID;
import joppe.backend.domain.user.dto.AddressRequest;
import joppe.backend.domain.user.dto.AddressResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserAddressService {

    private final UserAddressRepository userAddressRepository;
    private final UserRepository userRepository;

    @Transactional
    public AddressResponse createAddress(UUID userId, AddressRequest request) {
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found with ID: " + userId);
        }

        List<UserAddress> existing = userAddressRepository.findByUserId(userId);
        boolean makeDefault = Boolean.TRUE.equals(request.isDefault()) || existing.isEmpty();

        if (makeDefault) {
            userAddressRepository.clearDefaultAddresses(userId);
        }

        UserAddress address = UserAddress.builder()
                .userId(userId)
                .recipientName(request.recipientName().trim())
                .recipientPhone(request.recipientPhone().trim())
                .streetAddress(request.streetAddress().trim())
                .ward(request.ward() != null ? request.ward().trim() : null)
                .district(request.district() != null ? request.district().trim() : null)
                .province(request.province().trim())
                .isDefault(makeDefault)
                .build();

        return AddressResponse.fromEntity(userAddressRepository.save(address));
    }

    @Transactional
    public AddressResponse updateAddress(UUID userId, UUID addressId, AddressRequest request) {
        UserAddress address = userAddressRepository.findByIdAndUserId(addressId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Address not found or unauthorized"));

        boolean makeDefault = Boolean.TRUE.equals(request.isDefault());
        if (makeDefault && !Boolean.TRUE.equals(address.getIsDefault())) {
            userAddressRepository.clearDefaultAddresses(userId);
            address.setIsDefault(true);
        } else if (Boolean.FALSE.equals(request.isDefault()) && Boolean.TRUE.equals(address.getIsDefault())) {
            // keep default if it is the only one
            List<UserAddress> all = userAddressRepository.findByUserId(userId);
            if (all.size() > 1) {
                address.setIsDefault(false);
            }
        }

        address.setRecipientName(request.recipientName().trim());
        address.setRecipientPhone(request.recipientPhone().trim());
        address.setStreetAddress(request.streetAddress().trim());
        address.setWard(request.ward() != null ? request.ward().trim() : null);
        address.setDistrict(request.district() != null ? request.district().trim() : null);
        address.setProvince(request.province().trim());

        return AddressResponse.fromEntity(userAddressRepository.save(address));
    }

    @Transactional(readOnly = true)
    public List<AddressResponse> getAddresses(UUID userId) {
        return userAddressRepository.findByUserId(userId).stream()
                .map(AddressResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public AddressResponse getAddress(UUID userId, UUID addressId) {
        return userAddressRepository.findByIdAndUserId(addressId, userId)
                .map(AddressResponse::fromEntity)
                .orElseThrow(() -> new IllegalArgumentException("Address not found or unauthorized"));
    }

    @Transactional
    public void setDefaultAddress(UUID userId, UUID addressId) {
        userAddressRepository.findByIdAndUserId(addressId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Address not found or unauthorized"));
        userAddressRepository.clearDefaultAddresses(userId);
        userAddressRepository.setDefaultAddress(addressId, userId);
    }

    @Transactional
    public void deleteAddress(UUID userId, UUID addressId) {
        UserAddress address = userAddressRepository.findByIdAndUserId(addressId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Address not found or unauthorized"));

        boolean wasDefault = Boolean.TRUE.equals(address.getIsDefault());
        userAddressRepository.delete(address);

        if (wasDefault) {
            List<UserAddress> remaining = userAddressRepository.findByUserId(userId);
            if (!remaining.isEmpty()) {
                userAddressRepository.setDefaultAddress(remaining.get(0).getId(), userId);
            }
        }
    }

    @Transactional
    public UUID addAddress(
            UUID userId,
            String recipientName,
            String recipientPhone,
            String streetAddress,
            String ward,
            String district,
            String province,
            boolean isDefault) {

        AddressRequest request = new AddressRequest(
                recipientName,
                recipientPhone,
                streetAddress,
                ward,
                district,
                province,
                isDefault
        );
        return createAddress(userId, request).id();
    }

    @Transactional(readOnly = true)
    public List<UserAddress> getAddressesByUserId(UUID userId) {
        return userAddressRepository.findByUserId(userId);
    }

    @Transactional
    public void deleteAddress(UUID addressId) {
        userAddressRepository.deleteById(addressId);
    }
}
