package lab.neeko.joppe.controller;

import lab.neeko.joppe.dto.AuthenticationRequest;
import lab.neeko.joppe.dto.AuthenticationResponse;
import lab.neeko.joppe.dto.GoogleLoginRequest;
import lab.neeko.joppe.dto.RegisterRequest;
import lab.neeko.joppe.service.AuthenticationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthenticationController {

    private final AuthenticationService service;

    @PostMapping("/register")
    public ResponseEntity<AuthenticationResponse> register(
            @RequestBody RegisterRequest request
    ) {
        return ResponseEntity.ok(service.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthenticationResponse> authenticate(
            @RequestBody AuthenticationRequest request
    ) {
        return ResponseEntity.ok(service.authenticate(request));
    }

    @PostMapping("/google")
    public ResponseEntity<AuthenticationResponse> googleLogin(
            @RequestBody GoogleLoginRequest request
    ) {
        return ResponseEntity.ok(service.googleLogin(request));
    }

    @PostMapping("/logout")
    public void logout() {
        // This endpoint is just for Swagger documentation.
        // The actual logout logic is handled by Spring Security's LogoutFilter and LogoutService.
    }
}
