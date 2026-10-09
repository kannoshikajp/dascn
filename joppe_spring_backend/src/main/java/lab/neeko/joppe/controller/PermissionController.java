package lab.neeko.joppe.controller;

import lab.neeko.joppe.dto.PermissionRequest;
import lab.neeko.joppe.entity.Permission;
import lab.neeko.joppe.service.PermissionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/permissions")
@RequiredArgsConstructor
public class PermissionController {

    private final PermissionService service;

    @GetMapping
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<List<Permission>> getAllPermissions() {
        return ResponseEntity.ok(service.getAll());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<Permission> createPermission(@RequestBody PermissionRequest request) {
        return ResponseEntity.ok(service.create(request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<Void> deletePermission(@PathVariable Integer id) {
        service.delete(id);
        return ResponseEntity.ok().build();
    }
}
