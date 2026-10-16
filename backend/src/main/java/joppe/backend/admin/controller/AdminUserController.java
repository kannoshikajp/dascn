package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.dto.CreateUserRequest;
import joppe.backend.admin.dto.UpdateUserRequest;
import joppe.backend.admin.dto.UpdateUserStatusRequest;
import joppe.backend.admin.dto.UserSummaryResponse;
import joppe.backend.admin.service.UserManagementService;
import joppe.backend.auth.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('USER_MANAGE')")
@Tag(name = "Admin - Users", description = "Administrative endpoints for managing user accounts and roles")
public class AdminUserController {

    private final UserManagementService userManagementService;

    @GetMapping
    @Operation(summary = "List users with optional search, role, and active status filters")
    public ResponseEntity<List<UserSummaryResponse>> listUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer roleId,
            @RequestParam(required = false) Boolean isActive
    ) {
        List<UserSummaryResponse> users = userManagementService.listUsers(search, roleId, isActive);
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get user account details by ID")
    public ResponseEntity<UserSummaryResponse> getUser(@PathVariable UUID id) {
        UserSummaryResponse response = userManagementService.getUser(id);
        return ResponseEntity.ok(response);
    }

    @PostMapping
    @Operation(summary = "Create a new user account with role")
    public ResponseEntity<UserSummaryResponse> createUser(@Valid @RequestBody CreateUserRequest request) {
        UserSummaryResponse response = userManagementService.createUser(
                request.email(),
                request.password(),
                request.fullName(),
                request.phoneNumber(),
                request.roleId()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update user profile and role")
    public ResponseEntity<UserSummaryResponse> updateUser(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request
    ) {
        UserSummaryResponse response = userManagementService.updateUser(
                id,
                request.fullName(),
                request.phoneNumber(),
                request.avatarUrl(),
                request.roleId(),
                request.isActive()
        );
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Activate or suspend user account")
    public ResponseEntity<ApiResponse> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserStatusRequest request
    ) {
        userManagementService.updateUserStatus(id, request.isActive());
        String msg = request.isActive() ? "User account activated" : "User account suspended";
        return ResponseEntity.ok(new ApiResponse(true, msg));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete user account")
    public ResponseEntity<ApiResponse> deleteUser(@PathVariable UUID id) {
        userManagementService.deleteUser(id);
        return ResponseEntity.ok(new ApiResponse(true, "User deleted successfully"));
    }
}
