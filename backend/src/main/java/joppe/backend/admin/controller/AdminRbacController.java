package joppe.backend.admin.controller;

import jakarta.validation.Valid;
import java.util.List;
import joppe.backend.admin.dto.CreateRoleRequest;
import joppe.backend.admin.dto.PermissionDto;
import joppe.backend.admin.dto.RoleDto;
import joppe.backend.admin.dto.UpdateRolePermissionsRequest;
import joppe.backend.admin.service.RbacManagementService;
import joppe.backend.auth.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ROLE_MANAGE')")
public class AdminRbacController {

    private final RbacManagementService rbacManagementService;

    @GetMapping("/roles")
    public ResponseEntity<List<RoleDto>> listRoles() {
        return ResponseEntity.ok(rbacManagementService.listRoles());
    }

    @GetMapping("/roles/{id}")
    public ResponseEntity<RoleDto> getRole(@PathVariable Integer id) {
        return ResponseEntity.ok(rbacManagementService.getRole(id));
    }

    @PostMapping("/roles")
    public ResponseEntity<RoleDto> createRole(@Valid @RequestBody CreateRoleRequest request) {
        RoleDto created = rbacManagementService.createRole(
                request.roleName(),
                request.description(),
                request.permissions()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/roles/{id}/permissions")
    public ResponseEntity<RoleDto> updatePermissions(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateRolePermissionsRequest request
    ) {
        RoleDto updated = rbacManagementService.updateRolePermissions(id, request.permissions());
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/roles/{id}")
    public ResponseEntity<ApiResponse> deleteRole(@PathVariable Integer id) {
        rbacManagementService.deleteRole(id);
        return ResponseEntity.ok(new ApiResponse(true, "Role deleted successfully"));
    }

    @GetMapping("/permissions")
    public ResponseEntity<List<PermissionDto>> listPermissions() {
        return ResponseEntity.ok(rbacManagementService.listAllPermissions());
    }
}
