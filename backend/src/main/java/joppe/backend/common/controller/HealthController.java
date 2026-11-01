package joppe.backend.common.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.sql.Connection;
import java.sql.Statement;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.sql.DataSource;
import joppe.backend.common.dto.LivenessResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequiredArgsConstructor
@Tag(name = "System Health", description = "Liveness and system health probes")
public class HealthController {

    private final DataSource dataSource;

    @Operation(summary = "Liveness probe", description = "Checks system and database health status")
    @GetMapping({"/live", "/api/v1/live"})
    public ResponseEntity<LivenessResponse> checkLiveness() {
        Map<String, Object> details = new LinkedHashMap<>();
        boolean dbHealthy = false;
        String dbError = null;

        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.setQueryTimeout(3);
            stmt.execute("SELECT 1");
            dbHealthy = true;
            details.put("database", "CONNECTED");
        } catch (Exception ex) {
            log.error("Liveness probe database connection check failed", ex);
            dbError = ex.getMessage();
            details.put("database", "DISCONNECTED");
            details.put("error", dbError);
        }

        if (dbHealthy) {
            details.put("service", "UP");
            LivenessResponse response = new LivenessResponse(
                    "UP",
                    "Joppe backend is live and healthy.",
                    OffsetDateTime.now(),
                    "1.0.0",
                    details
            );
            return ResponseEntity.ok(response);
        } else {
            details.put("service", "DEGRADED");
            LivenessResponse response = new LivenessResponse(
                    "DOWN",
                    "Cannot access backend service dependencies: database is unreachable or degraded.",
                    OffsetDateTime.now(),
                    "1.0.0",
                    details
            );
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response);
        }
    }

    @RequestMapping(
            value = {"/live", "/api/v1/live"},
            method = {RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.PATCH}
    )
    public ResponseEntity<LivenessResponse> methodNotAllowed() {
        Map<String, Object> details = Map.of(
                "allowedMethods", "GET",
                "error", "Method not allowed for /live probe"
        );
        LivenessResponse response = new LivenessResponse(
                "ERROR",
                "Cannot access /live with this HTTP method. Only GET is permitted.",
                OffsetDateTime.now(),
                "1.0.0",
                details
        );
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED).body(response);
    }
}
