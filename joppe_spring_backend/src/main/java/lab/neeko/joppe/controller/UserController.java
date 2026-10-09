package lab.neeko.joppe.controller;

import lab.neeko.joppe.entity.User;
import lab.neeko.joppe.security.CustomUserDetails;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

import org.springframework.security.access.prepost.PreAuthorize;

import lab.neeko.joppe.service.UserService;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    @PreAuthorize("hasAuthority('profile:read')")
    public ResponseEntity<Map<String, Object>> getCurrentUser(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        User user = userDetails.getUser();
        
        Map<String, Object> response = new HashMap<>();
        response.put("id", user.getId());
        response.put("email", user.getEmail());
        response.put("fullName", user.getFullName());
        response.put("role", user.getPermissionGroup().getGroupName());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping
    @PreAuthorize("hasAuthority('user:read')")
    public ResponseEntity<java.util.List<User>> getAllUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @org.springframework.web.bind.annotation.DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('user:write')")
    public ResponseEntity<Void> deleteUser(@org.springframework.web.bind.annotation.PathVariable java.util.UUID id) {
        userService.deleteUser(id);
        return ResponseEntity.ok().build();
    }

    @org.springframework.web.bind.annotation.PutMapping("/{id}/role")
    @PreAuthorize("hasAuthority('admin:manage')")
    public ResponseEntity<User> assignRole(@org.springframework.web.bind.annotation.PathVariable java.util.UUID id, @org.springframework.web.bind.annotation.RequestBody java.util.Map<String, Integer> request) {
        Integer roleId = request.get("roleId");
        return ResponseEntity.ok(userService.assignRole(id, roleId));
    }
}
