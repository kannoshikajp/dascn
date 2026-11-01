package joppe.backend.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.admin.dto.UserSummaryResponse;
import joppe.backend.admin.service.UserManagementService;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RoleRepository;
import joppe.backend.domain.user.User;
import joppe.backend.domain.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

@ExtendWith(MockitoExtension.class)
class UserManagementServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private UserManagementService service;

    @BeforeEach
    void setUp() {
        service = new UserManagementService(userRepository, roleRepository, passwordEncoder);
    }

    @Test
    void listUsers_ReturnsFilteredResults() {
        Role role = Role.builder().id(1).roleName("ROLE_CUSTOMER").build();
        User user = User.builder()
                .id(UUID.randomUUID())
                .email("john@example.com")
                .fullName("John Doe")
                .roleId(1)
                .isActive(true)
                .build();

        when(roleRepository.findAll()).thenReturn(List.of(role));
        when(userRepository.findAll()).thenReturn(List.of(user));

        List<UserSummaryResponse> results = service.listUsers("john", 1, true);

        assertEquals(1, results.size());
        assertEquals("john@example.com", results.get(0).email());
        assertEquals("ROLE_CUSTOMER", results.get(0).roleName());
    }

    @Test
    void createUser_Success() {
        UUID id = UUID.randomUUID();
        Role role = Role.builder().id(2).roleName("ROLE_STAFF").build();
        User saved = User.builder()
                .id(id)
                .email("staff@joppe.vn")
                .fullName("Staff One")
                .roleId(2)
                .isActive(true)
                .build();

        when(userRepository.existsByEmail("staff@joppe.vn")).thenReturn(false);
        when(roleRepository.findById(2)).thenReturn(Optional.of(role));
        when(passwordEncoder.encode("secret")).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenReturn(saved);

        UserSummaryResponse response = service.createUser("staff@joppe.vn", "secret", "Staff One", null, 2);

        assertNotNull(response);
        assertEquals("staff@joppe.vn", response.email());
        assertEquals("ROLE_STAFF", response.roleName());
    }

    @Test
    void createUser_DuplicateEmail_Throws() {
        when(userRepository.existsByEmail("exist@joppe.vn")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () ->
                service.createUser("exist@joppe.vn", "secret", "Name", null, 1));
    }

    @Test
    void createUser_NonLoginRole_Throws() {
        Role nonLogin = Role.builder().id(4).roleName("ROLE_NON_LOGIN").build();
        when(roleRepository.findById(4)).thenReturn(Optional.of(nonLogin));

        assertThrows(IllegalArgumentException.class, () ->
                service.createUser("guest@joppe.vn", "secret", "Guest", null, 4));
    }

    @Test
    void updateUser_NonLoginRole_Throws() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).roleId(1).isActive(true).build();
        Role nonLogin = Role.builder().id(4).roleName("ROLE_NON_LOGIN").build();

        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(roleRepository.findById(4)).thenReturn(Optional.of(nonLogin));

        assertThrows(IllegalArgumentException.class, () ->
                service.updateUser(id, "Guest", null, null, 4, true));
    }

    @Test
    void updateUserStatus_Success() {
        UUID id = UUID.randomUUID();
        User user = User.builder().id(id).roleId(1).isActive(true).build();
        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(roleRepository.findRoleNameById(1)).thenReturn(Optional.of("ROLE_CUSTOMER"));

        service.updateUserStatus(id, false);

        verify(userRepository).updateActiveStatus(id, false);
    }

    @Test
    void updateUserStatus_LastActiveAdminDeactivate_Throws() {
        UUID id = UUID.randomUUID();
        User adminUser = User.builder().id(id).roleId(99).isActive(true).build();
        Role adminRole = Role.builder().id(99).roleName("ROLE_ADMIN").build();

        when(userRepository.findById(id)).thenReturn(Optional.of(adminUser));
        when(roleRepository.findRoleNameById(99)).thenReturn(Optional.of("ROLE_ADMIN"));
        when(roleRepository.findByRoleName("ROLE_ADMIN")).thenReturn(Optional.of(adminRole));
        when(userRepository.countByRoleIdAndIsActiveTrue(99)).thenReturn(1L);

        IllegalStateException ex = assertThrows(IllegalStateException.class, () ->
                service.updateUserStatus(id, false));
        assertEquals("At least one active administrator account is required.", ex.getMessage());
    }

    @Test
    void updateUserStatus_MultipleActiveAdmins_DeactivateSuccess() {
        UUID id = UUID.randomUUID();
        User adminUser = User.builder().id(id).roleId(99).isActive(true).build();
        Role adminRole = Role.builder().id(99).roleName("ROLE_ADMIN").build();

        when(userRepository.findById(id)).thenReturn(Optional.of(adminUser));
        when(roleRepository.findRoleNameById(99)).thenReturn(Optional.of("ROLE_ADMIN"));
        when(roleRepository.findByRoleName("ROLE_ADMIN")).thenReturn(Optional.of(adminRole));
        when(userRepository.countByRoleIdAndIsActiveTrue(99)).thenReturn(2L);

        service.updateUserStatus(id, false);

        verify(userRepository).updateActiveStatus(id, false);
    }

    @Test
    void updateUser_LastActiveAdminChangeRole_Throws() {
        UUID id = UUID.randomUUID();
        User adminUser = User.builder().id(id).roleId(99).isActive(true).build();
        Role staffRole = Role.builder().id(2).roleName("ROLE_STAFF").build();
        Role adminRole = Role.builder().id(99).roleName("ROLE_ADMIN").build();

        when(userRepository.findById(id)).thenReturn(Optional.of(adminUser));
        when(roleRepository.findById(2)).thenReturn(Optional.of(staffRole));
        when(roleRepository.findRoleNameById(99)).thenReturn(Optional.of("ROLE_ADMIN"));
        when(roleRepository.findByRoleName("ROLE_ADMIN")).thenReturn(Optional.of(adminRole));
        when(userRepository.countByRoleIdAndIsActiveTrue(99)).thenReturn(1L);

        IllegalStateException ex = assertThrows(IllegalStateException.class, () ->
                service.updateUser(id, "Admin", null, null, 2, true));
        assertEquals("At least one active administrator account is required.", ex.getMessage());
    }

    @Test
    void deleteUser_LastActiveAdmin_Throws() {
        UUID id = UUID.randomUUID();
        User adminUser = User.builder().id(id).roleId(99).isActive(true).build();
        Role adminRole = Role.builder().id(99).roleName("ROLE_ADMIN").build();

        when(userRepository.findById(id)).thenReturn(Optional.of(adminUser));
        when(roleRepository.findRoleNameById(99)).thenReturn(Optional.of("ROLE_ADMIN"));
        when(roleRepository.findByRoleName("ROLE_ADMIN")).thenReturn(Optional.of(adminRole));
        when(userRepository.countByRoleIdAndIsActiveTrue(99)).thenReturn(1L);

        IllegalStateException ex = assertThrows(IllegalStateException.class, () ->
                service.deleteUser(id));
        assertEquals("At least one active administrator account is required.", ex.getMessage());
    }
}
