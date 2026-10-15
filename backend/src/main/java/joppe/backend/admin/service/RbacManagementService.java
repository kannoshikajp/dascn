package joppe.backend.admin.service;

import java.util.List;
import java.util.Set;
import joppe.backend.admin.dto.PermissionDto;
import joppe.backend.admin.dto.RoleDto;
import joppe.backend.domain.user.Permission;
import joppe.backend.domain.user.PermissionRepository;
import joppe.backend.domain.user.Role;
import joppe.backend.domain.user.RolePermission;
import joppe.backend.domain.user.RolePermissionId;
import joppe.backend.domain.user.RolePermissionRepository;
import joppe.backend.domain.user.RoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RbacManagementService {

    private static final Set<String> IMMUTABLE_ROLES = Set.of("ROLE_ADMIN", "ROLE_CUSTOMER", "ROLE_STAFF");

    private final RoleRepository roleRepository;
    private final PermissionRepository permissionRepository;
    private final RolePermissionRepository rolePermissionRepository;

    @Transactional(readOnly = true)
    public List<RoleDto> listRoles() {
        return roleRepository.findAll().stream()
                .map(r -> new RoleDto(
                        r.getId(),
                        r.getRoleName(),
                        r.getDescription(),
                        permissionRepository.findPermissionNamesByRoleId(r.getId())
                ))
                .toList();
    }

    @Transactional(readOnly = true)
    public RoleDto getRole(Integer roleId) {
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found with id: " + roleId));

        List<String> perms = permissionRepository.findPermissionNamesByRoleId(role.getId());
        return new RoleDto(role.getId(), role.getRoleName(), role.getDescription(), perms);
    }

    @Transactional(readOnly = true)
    public List<PermissionDto> listAllPermissions() {
        return permissionRepository.findAll().stream()
                .map(p -> new PermissionDto(p.getId(), p.getPermissionName(), p.getDescription()))
                .toList();
    }

    @Transactional
    public RoleDto createRole(String roleName, String description, List<String> permissionNames) {
        String formattedRole = roleName.startsWith("ROLE_") ? roleName.toUpperCase() : "ROLE_" + roleName.toUpperCase();

        if (roleRepository.existsByRoleName(formattedRole)) {
            throw new IllegalArgumentException("Role already exists: " + formattedRole);
        }

        Role role = roleRepository.save(Role.builder()
                .roleName(formattedRole)
                .description(description)
                .build());

        assignPermissions(role.getId(), permissionNames);

        List<String> assigned = permissionRepository.findPermissionNamesByRoleId(role.getId());
        return new RoleDto(role.getId(), role.getRoleName(), role.getDescription(), assigned);
    }

    @Transactional
    public RoleDto updateRolePermissions(Integer roleId, List<String> permissionNames) {
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found with id: " + roleId));

        rolePermissionRepository.deleteByRoleId(roleId);
        assignPermissions(roleId, permissionNames);

        List<String> assigned = permissionRepository.findPermissionNamesByRoleId(role.getId());
        return new RoleDto(role.getId(), role.getRoleName(), role.getDescription(), assigned);
    }

    @Transactional
    public void deleteRole(Integer roleId) {
        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new IllegalArgumentException("Role not found with id: " + roleId));

        if (IMMUTABLE_ROLES.contains(role.getRoleName())) {
            throw new IllegalStateException("System role cannot be deleted: " + role.getRoleName());
        }

        rolePermissionRepository.deleteByRoleId(roleId);
        roleRepository.delete(role);
    }

    private void assignPermissions(Integer roleId, List<String> permissionNames) {
        if (permissionNames == null || permissionNames.isEmpty()) {
            return;
        }

        List<Permission> validPerms = permissionRepository.findByPermissionNameIn(permissionNames);
        List<RolePermission> mappings = validPerms.stream()
                .map(p -> new RolePermission(new RolePermissionId(roleId, p.getId())))
                .toList();

        rolePermissionRepository.saveAll(mappings);
    }
}
