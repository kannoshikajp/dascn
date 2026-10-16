package joppe.backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.auth.dto.AuthResponse;
import joppe.backend.auth.dto.UserProfileResponse;
import joppe.backend.auth.service.AuthService;
import joppe.backend.auth.service.JwtTokenService;
import joppe.backend.domain.user.PermissionRepository;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PermissionRepository permissionRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenService jwtTokenService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, roleRepository, permissionRepository, passwordEncoder, jwtTokenService);
    }

    @Test
    void register_Success() {
        UUID userId = UUID.randomUUID();
        Role role = Role.builder().id(1).roleName("ROLE_CUSTOMER").build();
        User savedUser = User.builder()
                .id(userId)
                .email("test@example.com")
                .fullName("Test User")
                .roleId(1)
                .build();
        List<String> permissions = List.of("AUTH_ME", "AUTH_CHANGE_PASSWORD");

        when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
        when(roleRepository.findByRoleName("ROLE_CUSTOMER")).thenReturn(Optional.of(role));
        when(passwordEncoder.encode("password123")).thenReturn("hashedPassword");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(permissionRepository.findPermissionNamesByRoleId(1)).thenReturn(permissions);
        when(jwtTokenService.generateToken(userId, "test@example.com", "ROLE_CUSTOMER", permissions)).thenReturn("jwt.token.here");
        when(jwtTokenService.getExpirationSeconds()).thenReturn(86400L);

        AuthResponse response = authService.register("test@example.com", "password123", "Test User", null);

        assertNotNull(response);
        assertEquals("test@example.com", response.email());
        assertEquals("jwt.token.here", response.accessToken());
        assertEquals("ROLE_CUSTOMER", response.role());
        assertEquals(permissions, response.permissions());
    }

    @Test
    void register_DuplicateEmail_ThrowsException() {
        when(userRepository.existsByEmail("test@example.com")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () ->
                authService.register("test@example.com", "password123", "Test User", null));
    }

    @Test
    void login_Success() {
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .email("test@example.com")
                .fullName("Test User")
                .passwordHash("hashedPassword")
                .roleId(1)
                .isActive(true)
                .build();
        List<String> permissions = List.of("AUTH_ME", "AUTH_CHANGE_PASSWORD");

        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "hashedPassword")).thenReturn(true);
        when(roleRepository.findRoleNameById(1)).thenReturn(Optional.of("ROLE_CUSTOMER"));
        when(permissionRepository.findPermissionNamesByRoleId(1)).thenReturn(permissions);
        when(jwtTokenService.generateToken(userId, "test@example.com", "ROLE_CUSTOMER", permissions)).thenReturn("jwt.token.here");
        when(jwtTokenService.getExpirationSeconds()).thenReturn(86400L);

        AuthResponse response = authService.login("test@example.com", "password123");

        assertNotNull(response);
        assertEquals(userId, response.userId());
        assertEquals("jwt.token.here", response.accessToken());
        assertEquals(permissions, response.permissions());
    }

    @Test
    void login_InvalidPassword_ThrowsBadCredentials() {
        User user = User.builder()
                .email("test@example.com")
                .passwordHash("hashedPassword")
                .isActive(true)
                .build();

        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrongPassword", "hashedPassword")).thenReturn(false);

        assertThrows(BadCredentialsException.class, () ->
                authService.login("test@example.com", "wrongPassword"));
    }

    @Test
    void getProfile_Success() {
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .email("test@example.com")
                .fullName("Test User")
                .phoneNumber("0123456789")
                .roleId(1)
                .isActive(true)
                .build();
        List<String> permissions = List.of("AUTH_ME", "AUTH_CHANGE_PASSWORD");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(roleRepository.findRoleNameById(1)).thenReturn(Optional.of("ROLE_CUSTOMER"));
        when(permissionRepository.findPermissionNamesByRoleId(1)).thenReturn(permissions);

        UserProfileResponse profile = authService.getProfile(userId);

        assertNotNull(profile);
        assertEquals(userId, profile.id());
        assertEquals("test@example.com", profile.email());
        assertEquals("ROLE_CUSTOMER", profile.role());
        assertEquals(permissions, profile.permissions());
    }

    @Test
    void updateProfile_Success() {
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .email("user@example.com")
                .fullName("Old Name")
                .phoneNumber("0900000001")
                .avatarUrl("https://example.com/old.png")
                .roleId(1)
                .isActive(true)
                .build();
        List<String> permissions = List.of("AUTH_ME");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(roleRepository.findRoleNameById(1)).thenReturn(Optional.of("ROLE_CUSTOMER"));
        when(permissionRepository.findPermissionNamesByRoleId(1)).thenReturn(permissions);

        UserProfileResponse updated = authService.updateProfile(
                userId,
                "New Name",
                "0900000002",
                "https://example.com/new.png"
        );

        assertNotNull(updated);
        assertEquals("New Name", updated.fullName());
        assertEquals("0900000002", updated.phoneNumber());
        assertEquals("https://example.com/new.png", updated.avatarUrl());
        assertEquals("user@example.com", updated.email());
    }

    @Test
    void updateProfile_DuplicatePhone_ThrowsException() {
        UUID userId = UUID.randomUUID();
        User user = User.builder()
                .id(userId)
                .email("user@example.com")
                .fullName("User Name")
                .phoneNumber("0900000001")
                .roleId(1)
                .isActive(true)
                .build();

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userRepository.existsByPhoneNumber("0999999999")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () ->
                authService.updateProfile(userId, "User Name", "0999999999", null));
    }
}
