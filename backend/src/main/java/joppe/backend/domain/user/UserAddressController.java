package joppe.backend.domain.user;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.domain.user.dto.AddressRequest;
import joppe.backend.domain.user.dto.AddressResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/addresses")
@RequiredArgsConstructor
@Tag(name = "Customer Addresses", description = "Endpoints for managing customer shipping address book")
@PreAuthorize("hasAuthority('ADDRESS_MANAGE')")
public class UserAddressController {

    private final UserAddressService userAddressService;

    private UUID getUserId(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }

    @GetMapping
    @Operation(summary = "Get all shipping addresses for authenticated user")
    public List<AddressResponse> getAddresses(@AuthenticationPrincipal Jwt jwt) {
        return userAddressService.getAddresses(getUserId(jwt));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get specific address details by ID")
    public AddressResponse getAddressById(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        return userAddressService.getAddress(getUserId(jwt), id);
    }

    @PostMapping
    @Operation(summary = "Add a new shipping address")
    public ResponseEntity<AddressResponse> createAddress(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AddressRequest request) {
        AddressResponse created = userAddressService.createAddress(getUserId(jwt), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing shipping address")
    public AddressResponse updateAddress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id,
            @Valid @RequestBody AddressRequest request) {
        return userAddressService.updateAddress(getUserId(jwt), id, request);
    }

    @PatchMapping("/{id}/default")
    @Operation(summary = "Set address as default shipping address")
    public ResponseEntity<Void> setDefaultAddress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        userAddressService.setDefaultAddress(getUserId(jwt), id);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a shipping address")
    public ResponseEntity<Void> deleteAddress(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID id) {
        userAddressService.deleteAddress(getUserId(jwt), id);
        return ResponseEntity.noContent().build();
    }
}
