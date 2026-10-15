package joppe.backend.auth.service;

import java.util.UUID;
import joppe.backend.auth.dto.AuthResponse;
import joppe.backend.auth.dto.UserProfileResponse;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;

    @Transactional
    public AuthResponse register(String email, String rawPassword, String fullName, String phoneNumber) {
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("Email already registered: " + email);
        }
        if (phoneNumber != null && !phoneNumber.isBlank() && userRepository.existsByPhoneNumber(phoneNumber)) {
            throw new IllegalArgumentException("Phone number already registered: " + phoneNumber);
        }

        Role defaultRole = roleRepository.findByRoleName("ROLE_CUSTOMER")
                .orElseGet(() -> roleRepository.save(Role.builder()
                        .roleName("ROLE_CUSTOMER")
                        .description("Standard customer account")
                        .build()));

        String encodedPassword = passwordEncoder.encode(rawPassword);

        User user = User.builder()
                .roleId(defaultRole.getId())
                .email(email)
                .passwordHash(encodedPassword)
                .fullName(fullName)
                .phoneNumber(phoneNumber)
                .isActive(true)
                .build();

        User saved = userRepository.save(user);

        String token = jwtTokenService.generateToken(saved.getId(), saved.getEmail(), defaultRole.getRoleName());

        return new AuthResponse(
                "Bearer",
                token,
                jwtTokenService.getExpirationSeconds(),
                saved.getId(),
                saved.getEmail(),
                saved.getFullName(),
                defaultRole.getRoleName()
        );
    }

    @Transactional(readOnly = true)
    public AuthResponse login(String email, String rawPassword) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new IllegalStateException("Account is inactive or suspended");
        }

        String roleName = roleRepository.findRoleNameById(user.getRoleId())
                .orElse("ROLE_CUSTOMER");

        String token = jwtTokenService.generateToken(user.getId(), user.getEmail(), roleName);

        return new AuthResponse(
                "Bearer",
                token,
                jwtTokenService.getExpirationSeconds(),
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                roleName
        );
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        String roleName = roleRepository.findRoleNameById(user.getRoleId())
                .orElse("ROLE_CUSTOMER");

        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getPhoneNumber(),
                user.getAvatarUrl(),
                roleName,
                user.getIsActive(),
                user.getCreatedAt()
        );
    }

    @Transactional
    public void changePassword(UUID userId, String currentPassword, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new BadCredentialsException("Current password does not match");
        }

        String newHash = passwordEncoder.encode(newPassword);
        userRepository.updatePasswordHash(userId, newHash);
    }
}
