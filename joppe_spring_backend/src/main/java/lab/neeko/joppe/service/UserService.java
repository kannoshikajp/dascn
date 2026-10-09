package lab.neeko.joppe.service;

import lab.neeko.joppe.entity.User;
import lab.neeko.joppe.repository.PermissionGroupRepository;
import lab.neeko.joppe.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;
    private final PermissionGroupRepository permissionGroupRepository;

    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    public void deleteUser(java.util.UUID id) {
        userRepository.deleteById(id);
    }

    public User assignRole(java.util.UUID userId, Integer roleId) {
        var user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found"));
        var group = permissionGroupRepository.findById(roleId).orElseThrow(() -> new RuntimeException("Role not found"));
        user.setPermissionGroup(group);
        return userRepository.save(user);
    }
}
