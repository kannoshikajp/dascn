package joppe.backend.auth.controller;

import jakarta.validation.Valid;
import java.util.UUID;
import joppe.backend.auth.dto.ApiResponse;
import joppe.backend.auth.dto.AuthResponse;
import joppe.backend.auth.dto.ChangePasswordRequest;
import joppe.backend.auth.dto.LoginRequest;
import joppe.backend.auth.dto.RegisterRequest;
import joppe.backend.auth.dto.UserProfileResponse;
import joppe.backend.auth.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Endpoints for user registration, login, profile, and password management")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register new customer account")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(
                request.email(),
                request.password(),
                request.fullName(),
                request.phoneNumber()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    @Operation(summary = "Authenticate user with email and password")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(
                request.email(),
                request.password()
        );
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    @PreAuthorize("hasAuthority('AUTH_ME')")
    @Operation(summary = "Get current authenticated user profile and permissions")
    public ResponseEntity<UserProfileResponse> getCurrentUser(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        UserProfileResponse response = authService.getProfile(userId);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/change-password")
    @PreAuthorize("hasAuthority('AUTH_CHANGE_PASSWORD')")
    @Operation(summary = "Change current user password")
    public ResponseEntity<ApiResponse> changePassword(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ChangePasswordRequest request) {

        UUID userId = UUID.fromString(jwt.getSubject());
        authService.changePassword(
                userId,
                request.currentPassword(),
                request.newPassword()
        );
        return ResponseEntity.ok(new ApiResponse(true, "Password changed successfully"));
    }
}
