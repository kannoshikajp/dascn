package joppe.backend.admin.service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import joppe.backend.admin.dto.UserSummaryResponse;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserManagementService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UserSummaryResponse> listUsers(String search, Integer roleId, Boolean isActive) {
        Map<Integer, String> roleMap = roleRepository.findAll().stream()
                .collect(Collectors.toMap(Role::getId, Role::getRoleName));

        List<User> users = userRepository.findAll();

        return users.stream()
                .filter(u -> roleId == null || roleId.equals(u.getRoleId()))
                .filter(u -> isActive == null || isActive.equals(u.getIsActive()))
                .filter(u -> search == null || search.isBlank() ||
                        u.getEmail().toLowerCase().contains(search.toLowerCase()) ||
                        u.getFullName().toLowerCase().contains(search.toLowerCase()) ||
                        (u.getPhoneNumber() != null && u.getPhoneNumber().contains(search)))
                .map(u -> new UserSummaryResponse(
                        u.getId(),
                        u.getEmail(),
                        u.getFullName(),
                        u.getPhoneNumber(),
                        u.getAvatarUrl(),
                        u.getRoleId(),
                        roleMap.getOrDefault(u.getRoleId(), "UNKNOWN"),
                        u.getIsActive(),
                        u.getCreatedAt()
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public UserSummaryResponse getUser(UUID userId) {
        User u = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        String roleName = roleRepository.findRoleNameById(u.getRoleId()).orElse("UNKNOWN");

        return new UserSummaryResponse(
                u.getId(),
                u.getEmail(),
                u.getFullName(),
                u.getPhoneNumber(),
                u.getAvatarUrl(),
                u.getRoleId(),
                roleName,
                u.getIsActive(),
                u.getCreatedAt()
        );
    }

    @Transactional
    public UserSummaryResponse createUser(String email, String rawPassword, String fullName, String phoneNumber, Integer roleId) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already registered: " + email);
        }
        if (phoneNumber != null && !phoneNumber.isBlank() && userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already registered: " + phoneNumber);
        }
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found with id: " + roleId));

        User user = User.builder()
                .email(email)
                .passwordHash(passwordEncoder.encode(rawPassword))
                .fullName(fullName)
                .phoneNumber(phoneNumber)
                .roleId(role.getId())
                .isActive(true)
                .build();

        User saved = userRepository.save(user);

        return new UserSummaryResponse(
                saved.getId(),
                saved.getEmail(),
                saved.getFullName(),
                saved.getPhoneNumber(),
                saved.getAvatarUrl(),
                saved.getRoleId(),
                role.getRoleName(),
                saved.getIsActive(),
                saved.getCreatedAt()
        );
    }

    @Transactional
    public UserSummaryResponse updateUser(UUID userId, String fullName, String phoneNumber, String avatarUrl, Integer roleId, Boolean isActive) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found with id: " + roleId));

        if (phoneNumber != null && !phoneNumber.isBlank() && !phoneNumber.equals(user.getPhoneNumber())) {
            if (userRepository.existsByPhoneNumber(phoneNumber)) {
                throw new IllegalArgumentException("Phone number already in use: " + phoneNumber);
            }
        }

        user.setFullName(fullName);
        user.setPhoneNumber(phoneNumber);
        user.setAvatarUrl(avatarUrl);
        user.setRoleId(role.getId());
        user.setIsActive(isActive);

        User updated = userRepository.save(user);

        return new UserSummaryResponse(
                updated.getId(),
                updated.getEmail(),
                updated.getFullName(),
                updated.getPhoneNumber(),
                updated.getAvatarUrl(),
                updated.getRoleId(),
                role.getRoleName(),
                updated.getIsActive(),
                updated.getCreatedAt()
        );
    }

    @Transactional
    public void updateUserStatus(UUID userId, boolean isActive) {
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found: " + userId);
        }
        userRepository.updateActiveStatus(userId, isActive);
    }

    @Transactional
    public void deleteUser(UUID userId) {
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found: " + userId);
        }
        userRepository.deleteById(userId);
    }
}
