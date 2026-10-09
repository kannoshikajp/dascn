package lab.neeko.joppe.controller;

import lab.neeko.joppe.dto.PermissionGroupRequest;
import lab.neeko.joppe.entity.PermissionGroup;
import lab.neeko.joppe.service.PermissionGroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/permission-groups")
@RequiredArgsConstructor
public class PermissionGroupController {

    private final PermissionGroupService service;

    @GetMapping
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<List<PermissionGroup>> getAllPermissionGroups() {
        return ResponseEntity.ok(service.getAll());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<PermissionGroup> createGroup(@RequestBody PermissionGroupRequest request) {
        return ResponseEntity.ok(service.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<PermissionGroup> updateGroup(@PathVariable Integer id, @RequestBody PermissionGroupRequest request) {
        return ResponseEntity.ok(service.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<Void> deleteGroup(@PathVariable Integer id) {
        service.delete(id);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/permissions")
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<Void> updatePermissions(
            @PathVariable Integer id, 
            @RequestBody java.util.List<Integer> permissionIds) {
        service.updatePermissionsForGroup(id, permissionIds);
        return ResponseEntity.ok().build();
    }
}
