package lab.neeko.joppe.config;

import lab.neeko.joppe.entity.Permission;
import lab.neeko.joppe.entity.PermissionGroup;
import lab.neeko.joppe.repository.PermissionGroupRepository;
import lab.neeko.joppe.repository.PermissionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final PermissionGroupRepository permissionGroupRepository;
    private final PermissionRepository permissionRepository;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // 1. Define standalone permissions
        Permission profileRead = getOrCreatePermission("profile:read", "Read own profile", "User Management");
        Permission profileUpdate = getOrCreatePermission("profile:update", "Update own profile", "User Management");
        Permission userRead = getOrCreatePermission("user:read", "Read all users", "User Management");
        Permission userWrite = getOrCreatePermission("user:write", "Create, update, delete users", "User Management");
        Permission adminManage = getOrCreatePermission("admin:manage", "Manage roles, permissions, system settings", "User Management");
        
        Permission productRead = getOrCreatePermission("product:read", "Read products", "Product Management");
        Permission productWrite = getOrCreatePermission("product:write", "Write products", "Product Management");
        
        // 2. Define Groups (which act as Roles)
        PermissionGroup adminGroup = getOrCreateGroup("ADMIN", "Administrator with all access");
        adminGroup.setPermissions(new HashSet<>(Set.of(profileRead, profileUpdate, userRead, userWrite, adminManage, productRead, productWrite)));
        permissionGroupRepository.save(adminGroup);

        PermissionGroup registeredUserGroup = getOrCreateGroup("REGISTERED_USER", "Standard registered user");
        registeredUserGroup.setPermissions(new HashSet<>(Set.of(profileRead, profileUpdate, productRead)));
        permissionGroupRepository.save(registeredUserGroup);

        PermissionGroup userGroup = getOrCreateGroup("USER", "Guest or basic user");
        userGroup.setPermissions(new HashSet<>(Set.of(profileRead)));
        permissionGroupRepository.save(userGroup);
    }

    private PermissionGroup getOrCreateGroup(String name, String description) {
        PermissionGroup pg = permissionGroupRepository.findByGroupName(name).orElse(new PermissionGroup());
        pg.setGroupName(name);
        pg.setDescription(description);
        pg.setIsBuiltIn(true);
        if (pg.getPermissions() == null) {
            pg.setPermissions(new HashSet<>());
        }
        return permissionGroupRepository.save(pg);
    }

    private Permission getOrCreatePermission(String name, String description, String category) {
        return permissionRepository.findByPermissionName(name).orElseGet(() -> {
            Permission p = new Permission();
            p.setPermissionName(name);
            p.setDescription(description);
            p.setCategory(category);
            return permissionRepository.save(p);
        });
    }
}
