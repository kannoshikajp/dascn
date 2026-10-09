package lab.neeko.joppe.service;

import lab.neeko.joppe.dto.PermissionRequest;
import lab.neeko.joppe.entity.Permission;
import lab.neeko.joppe.repository.PermissionGroupRepository;
import lab.neeko.joppe.repository.PermissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PermissionService {

    private final PermissionRepository permissionRepository;
    private final PermissionGroupRepository permissionGroupRepository;

    public List<Permission> getAll() {
        return permissionRepository.findAll();
    }

    public Permission create(PermissionRequest request) {
        if (permissionRepository.findByPermissionName(request.getPermissionName()).isPresent()) {
            throw new RuntimeException("Permission with this name already exists");
        }

        var permission = Permission.builder()
                .permissionName(request.getPermissionName())
                .description(request.getDescription())
                .category(request.getCategory())
                .build();

        return permissionRepository.save(permission);
    }

    public void delete(Integer id) {
        var permission = permissionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Permission not found"));
        permissionRepository.delete(permission);
    }
}
