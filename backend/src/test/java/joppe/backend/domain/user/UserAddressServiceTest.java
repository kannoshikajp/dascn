package joppe.backend.domain.user;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.domain.user.dto.AddressRequest;
import joppe.backend.domain.user.dto.AddressResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class UserAddressServiceTest {

    @Mock
    private UserAddressRepository userAddressRepository;

    @Mock
    private UserRepository userRepository;

    private UserAddressService service;

    @BeforeEach
    void setUp() {
        service = new UserAddressService(userAddressRepository, userRepository);
    }

    @Test
    void createAddress_firstAddress_becomesDefaultAutomatically() {
        UUID userId = UUID.randomUUID();
        AddressRequest request = new AddressRequest(
                "Jane Doe",
                "0901234567",
                "123 Tech Street",
                "Ward 1",
                "District 3",
                "Ho Chi Minh City",
                false
        );

        when(userRepository.existsById(userId)).thenReturn(true);
        when(userAddressRepository.findByUserId(userId)).thenReturn(List.of());

        UserAddress saved = UserAddress.builder()
                .id(UUID.randomUUID())
                .userId(userId)
                .recipientName(request.recipientName())
                .recipientPhone(request.recipientPhone())
                .streetAddress(request.streetAddress())
                .ward(request.ward())
                .district(request.district())
                .province(request.province())
                .isDefault(true)
                .build();

        when(userAddressRepository.save(any(UserAddress.class))).thenReturn(saved);

        AddressResponse res = service.createAddress(userId, request);

        assertNotNull(res);
        assertTrue(res.isDefault());
        assertEquals("Jane Doe", res.recipientName());
        verify(userAddressRepository).clearDefaultAddresses(userId);
    }

    @Test
    void deleteAddress_unauthorized_throwsException() {
        UUID userId = UUID.randomUUID();
        UUID otherAddressId = UUID.randomUUID();

        when(userAddressRepository.findByIdAndUserId(otherAddressId, userId)).thenReturn(Optional.empty());

        assertThrows(IllegalArgumentException.class, () -> service.deleteAddress(userId, otherAddressId));
    }
}
