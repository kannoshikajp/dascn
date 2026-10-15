package joppe.backend.domain.user;

import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;

    @Transactional
    public UUID registerUser(
            Integer roleId,
            String email,
            String passwordHash,
            String fullName,
            String phoneNumber,
            String avatarUrl) {

        if (!roleRepository.existsById(roleId)) {
            throw new IllegalArgumentException("Role not found with ID: " + roleId);
        }
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already exists: " + email);
        }
        if (phoneNumber != null && userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already exists: " + phoneNumber);
        }

        User user = User.builder()
                .roleId(roleId)
                .email(email)
                .passwordHash(passwordHash)
                .fullName(fullName)
                .phoneNumber(phoneNumber)
                .avatarUrl(avatarUrl)
                .isActive(true)
                .build();

        return userRepository.save(user).getId();
    }

    @Transactional(readOnly = true)
    public Optional<User> findById(UUID userId) {
        return userRepository.findById(userId);
    }

    @Transactional(readOnly = true)
    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    @Transactional(readOnly = true)
    public boolean isUserActive(UUID userId) {
        return userRepository.findIsActiveByUserId(userId).orElse(false);
    }

    @Transactional
    public void updateUserStatus(UUID userId, boolean isActive) {
        userRepository.updateActiveStatus(userId, isActive);
    }

    @Transactional
    public void changePassword(UUID userId, String newPasswordHash) {
        userRepository.updatePasswordHash(userId, newPasswordHash);
    }
}
