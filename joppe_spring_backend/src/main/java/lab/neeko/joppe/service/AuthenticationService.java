package lab.neeko.joppe.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lab.neeko.joppe.dto.AuthenticationRequest;
import lab.neeko.joppe.dto.AuthenticationResponse;
import lab.neeko.joppe.dto.GoogleLoginRequest;
import lab.neeko.joppe.dto.RegisterRequest;
import lab.neeko.joppe.entity.PermissionGroup;
import lab.neeko.joppe.entity.User;
import lab.neeko.joppe.repository.PermissionGroupRepository;
import lab.neeko.joppe.repository.UserRepository;
import lab.neeko.joppe.security.CustomUserDetails;
import lab.neeko.joppe.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthenticationService {
    private final UserRepository repository;
    private final PermissionGroupRepository permissionGroupRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final lab.neeko.joppe.repository.TokenRepository tokenRepository;

    @Value("${application.security.google.client-id:YOUR_DEFAULT_GOOGLE_CLIENT_ID}")
    private String googleClientId;

    public AuthenticationResponse register(RegisterRequest request) {
        long userCount = repository.count();
        String groupNameToAssign = (userCount == 0) ? "ADMIN" : "REGISTERED_USER";
        
        PermissionGroup assignedGroup = permissionGroupRepository.findByGroupName(groupNameToAssign)
                .orElseThrow(() -> new RuntimeException(groupNameToAssign + " Group not found in database."));
                
        var user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .permissionGroup(assignedGroup)
                .isActive(true)
                .build();
                
        var savedUser = repository.save(user);
        var jwtToken = jwtService.generateToken(new CustomUserDetails(user));
        saveUserToken(savedUser, jwtToken);
        
        return AuthenticationResponse.builder()
                .token(jwtToken)
                .build();
    }

    public AuthenticationResponse authenticate(AuthenticationRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );
        var user = repository.findByEmail(request.getEmail())
                .orElseThrow();
        var jwtToken = jwtService.generateToken(new CustomUserDetails(user));
        
        revokeAllUserTokens(user);
        saveUserToken(user, jwtToken);
        
        return AuthenticationResponse.builder()
                .token(jwtToken)
                .build();
    }

    public AuthenticationResponse googleLogin(GoogleLoginRequest request) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(request.getIdToken());
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                String email = payload.getEmail();
                String name = (String) payload.get("name");
                String pictureUrl = (String) payload.get("picture");

                Optional<User> userOptional = repository.findByEmail(email);
                User user;

                if (userOptional.isPresent()) {
                    user = userOptional.get();
                } else {
                    long userCount = repository.count();
                    String groupNameToAssign = (userCount == 0) ? "ADMIN" : "REGISTERED_USER";
                    
                    PermissionGroup assignedGroup = permissionGroupRepository.findByGroupName(groupNameToAssign)
                            .orElseThrow(() -> new RuntimeException(groupNameToAssign + " Group not found in database."));

                    user = User.builder()
                            .fullName(name != null ? name : "Google User")
                            .email(email)
                            .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                            .avatarUrl(pictureUrl)
                            .permissionGroup(assignedGroup)
                            .isActive(true)
                            .build();

                    user = repository.save(user);
                }

                var jwtToken = jwtService.generateToken(new CustomUserDetails(user));
                
                revokeAllUserTokens(user);
                saveUserToken(user, jwtToken);
                
                return AuthenticationResponse.builder()
                        .token(jwtToken)
                        .build();

            } else {
                throw new RuntimeException("Invalid ID token.");
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to authenticate with Google: " + e.getMessage());
        }
    }

    private void saveUserToken(User user, String jwtToken) {
        var token = lab.neeko.joppe.entity.Token.builder()
                .user(user)
                .token(jwtToken)
                .expired(false)
                .revoked(false)
                .build();
        tokenRepository.save(token);
    }

    private void revokeAllUserTokens(User user) {
        var validUserTokens = tokenRepository.findAllValidTokenByUser(user.getId());
        if (validUserTokens.isEmpty()) return;
        
        validUserTokens.forEach(token -> {
            token.setExpired(true);
            token.setRevoked(true);
        });
        tokenRepository.saveAll(validUserTokens);
    }
}
