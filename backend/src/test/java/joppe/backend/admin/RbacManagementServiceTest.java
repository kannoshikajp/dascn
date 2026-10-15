package joppe.backend.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import joppe.backend.admin.dto.RoleDto;
import joppe.backend.admin.service.RbacManagementService;
import joppe.backend.domain.user.Permission;
import joppe.backend.domain.user.PermissionRepository;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RolePermissionRepository;
import joppe.backend.domain.user.RoleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class RbacManagementServiceTest {

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PermissionRepository permissionRepository;

    @Mock
    private RolePermissionRepository rolePermissionRepository;

    private RbacManagementService service;

    @BeforeEach
    void setUp() {
        service = new RbacManagementService(roleRepository, permissionRepository, rolePermissionRepository);
    }

    @Test
    void listRoles_ReturnsAllWithPermissions() {
        Role role = Role.builder().id(1).roleName("ROLE_CUSTOMER").description("Customer").build();
        when(roleRepository.findAll()).thenReturn(List.of(role));
        when(permissionRepository.findPermissionNamesByRoleId(1)).thenReturn(List.of("AUTH_ME"));

        List<RoleDto> roles = service.listRoles();

        assertEquals(1, roles.size());
        assertEquals("ROLE_CUSTOMER", roles.get(0).roleName());
        assertEquals(List.of("AUTH_ME"), roles.get(0).permissions());
    }

    @Test
    void createRole_Success() {
        Role saved = Role.builder().id(10).roleName("ROLE_INVENTORY_SPECIALIST").description("Desc").build();
        Permission perm = Permission.builder().id(5).permissionName("INVENTORY_READ").build();

        when(roleRepository.existsByRoleName("ROLE_INVENTORY_SPECIALIST")).thenReturn(false);
        when(roleRepository.save(any(Role.class))).thenReturn(saved);
        when(permissionRepository.findByPermissionNameIn(List.of("INVENTORY_READ"))).thenReturn(List.of(perm));
        when(permissionRepository.findPermissionNamesByRoleId(10)).thenReturn(List.of("INVENTORY_READ"));

        RoleDto result = service.createRole("INVENTORY_SPECIALIST", "Desc", List.of("INVENTORY_READ"));

        assertNotNull(result);
        assertEquals("ROLE_INVENTORY_SPECIALIST", result.roleName());
        assertEquals(List.of("INVENTORY_READ"), result.permissions());
    }

    @Test
    void deleteRole_ImmutableSystemRole_ThrowsException() {
        Role adminRole = Role.builder().id(3).roleName("ROLE_ADMIN").build();
        when(roleRepository.findById(3)).thenReturn(Optional.of(adminRole));
        assertThrows(IllegalStateException.class, () -> service.deleteRole(3));

        Role nonLoginRole = Role.builder().id(4).roleName("ROLE_NON_LOGIN").build();
        when(roleRepository.findById(4)).thenReturn(Optional.of(nonLoginRole));
        assertThrows(IllegalStateException.class, () -> service.deleteRole(4));
    }
}
