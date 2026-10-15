package joppe.backend.domain.user;

import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserAddressService {

    private final UserAddressRepository userAddressRepository;
    private final UserRepository userRepository;

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

        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found with ID: " + userId);
        }

        if (isDefault) {
            userAddressRepository.clearDefaultAddresses(userId);
        }

        UserAddress address = UserAddress.builder()
                .userId(userId)
                .recipientName(recipientName)
                .recipientPhone(recipientPhone)
                .streetAddress(streetAddress)
                .ward(ward)
                .district(district)
                .province(province)
                .isDefault(isDefault)
                .build();

        return userAddressRepository.save(address).getId();
    }

    @Transactional(readOnly = true)
    public List<UserAddress> getAddressesByUserId(UUID userId) {
        return userAddressRepository.findByUserId(userId);
    }

    @Transactional
    public void setDefaultAddress(UUID userId, UUID addressId) {
        userAddressRepository.clearDefaultAddresses(userId);
        userAddressRepository.setDefaultAddress(addressId, userId);
    }

    @Transactional
    public void deleteAddress(UUID addressId) {
        userAddressRepository.deleteById(addressId);
    }
}
