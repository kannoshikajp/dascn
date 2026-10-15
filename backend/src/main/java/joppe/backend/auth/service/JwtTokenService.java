package joppe.backend.auth.service;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class JwtTokenService {

    private final JwtEncoder jwtEncoder;

    @Value("${jwt.expiration-seconds:86400}")
    private long expirationSeconds;

    public String generateToken(UUID userId, String email, String role) {
        return generateToken(userId, email, role, Collections.emptyList());
    }

    public String generateToken(UUID userId, String email, String role, List<String> permissions) {
        Instant now = Instant.now();
        Instant expiresAt = now.plusSeconds(expirationSeconds);

        JwtClaimsSet.Builder builder = JwtClaimsSet.builder()
                .issuer("joppe-backend")
                .issuedAt(now)
                .expiresAt(expiresAt)
                .subject(userId.toString())
                .claim("email", email)
                .claim("role", role);

        if (permissions != null && !permissions.isEmpty()) {
            builder.claim("permissions", permissions);
        }

        JwtClaimsSet claims = builder.build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    public long getExpirationSeconds() {
        return expirationSeconds;
    }
}
