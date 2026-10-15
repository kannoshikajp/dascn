package joppe.backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;
import joppe.backend.auth.config.AdminAccountInitializer;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class AdminAccountInitializerTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AdminAccountInitializer initializer;

    @BeforeEach
    void setUp() {
        initializer = new AdminAccountInitializer(userRepository, roleRepository, passwordEncoder);
        ReflectionTestUtils.setField(initializer, "adminEmail", "admin@joppe.vn");
        ReflectionTestUtils.setField(initializer, "adminPassword", "Admin@123456");
        ReflectionTestUtils.setField(initializer, "adminFullName", "System Administrator");
    }

    @Test
    void run_WhenAdminDoesNotExist_CreatesAdminUser() {
        Role adminRole = Role.builder().id(3).roleName("ROLE_ADMIN").build();

        when(userRepository.existsByEmail("admin@joppe.vn")).thenReturn(false);
        when(roleRepository.findByRoleName("ROLE_ADMIN")).thenReturn(Optional.of(adminRole));
        when(passwordEncoder.encode("Admin@123456")).thenReturn("hashedAdminPassword");

        initializer.run();

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());

        User saved = captor.getValue();
        assertEquals("admin@joppe.vn", saved.getEmail());
        assertEquals("System Administrator", saved.getFullName());
        assertEquals("hashedAdminPassword", saved.getPasswordHash());
        assertEquals(3, saved.getRoleId());
        assertEquals(true, saved.getIsActive());
    }

    @Test
    void run_WhenAdminAlreadyExists_SkipsCreation() {
        when(userRepository.existsByEmail("admin@joppe.vn")).thenReturn(true);

        initializer.run();

        verify(userRepository, never()).save(any(User.class));
        verify(passwordEncoder, never()).encode(any());
    }
}
