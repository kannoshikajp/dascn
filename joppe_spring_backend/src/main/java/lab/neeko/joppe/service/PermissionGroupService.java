package lab.neeko.joppe.service;

import lab.neeko.joppe.dto.PermissionGroupRequest;
import lab.neeko.joppe.entity.Permission;
import lab.neeko.joppe.entity.PermissionGroup;
import lab.neeko.joppe.repository.PermissionGroupRepository;
import lab.neeko.joppe.repository.PermissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PermissionGroupService {

    private final PermissionGroupRepository repository;
    private final PermissionRepository permissionRepository;

    public List<PermissionGroup> getAll() {
        return repository.findAll();
    }

    public PermissionGroup create(PermissionGroupRequest request) {
        if (repository.findByGroupName(request.getGroupName()).isPresent()) {
            throw new RuntimeException("Permission Group with this name already exists");
        }
        var group = PermissionGroup.builder()
                .groupName(request.getGroupName())
                .description(request.getDescription())
                .isBuiltIn(false)
                .build();
        return repository.save(group);
    }

    public PermissionGroup update(Integer id, PermissionGroupRequest request) {
        var group = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Permission Group not found"));

        if (Boolean.TRUE.equals(group.getIsBuiltIn()) && !group.getGroupName().equals(request.getGroupName())) {
            throw new RuntimeException("Cannot rename a built-in system group");
        }

        group.setGroupName(request.getGroupName());
        group.setDescription(request.getDescription());
        return repository.save(group);
    }

    public void delete(Integer id) {
        var group = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Permission Group not found"));

        if (Boolean.TRUE.equals(group.getIsBuiltIn())) {
            throw new RuntimeException("Cannot delete a built-in system group");
        }

        repository.delete(group);
    }

    public void updatePermissionsForGroup(Integer id, List<Integer> permissionIds) {
        var group = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Permission Group not found"));

        List<Permission> permissions = permissionRepository.findAllById(permissionIds);
        group.setPermissions(new java.util.HashSet<>(permissions));
        repository.save(group);
    }
}
