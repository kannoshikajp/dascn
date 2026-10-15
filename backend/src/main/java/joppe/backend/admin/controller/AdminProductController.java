package joppe.backend.admin.controller;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.dto.CreateProductRequest;
import joppe.backend.admin.dto.CreateVariantRequest;
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.dto.ProductVariantSummary;
import joppe.backend.admin.dto.UpdateProductRequest;
import joppe.backend.admin.dto.UpdateProductStatusRequest;
import joppe.backend.admin.dto.UpdateVariantRequest;
import joppe.backend.admin.service.AdminProductService;
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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/products")
@RequiredArgsConstructor
public class AdminProductController {

    private final AdminProductService adminProductService;

    @GetMapping
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    public List<ProductResponse> listProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer brandId,
            @RequestParam(required = false) Boolean isActive) {
        return adminProductService.listProducts(search, categoryId, brandId, isActive);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    public ProductResponse getProductById(@PathVariable UUID id) {
        return adminProductService.getProductById(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody CreateProductRequest request) {
        ProductResponse created = adminProductService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    public ProductResponse updateProduct(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateProductRequest request) {
        return adminProductService.updateProduct(id, request);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void updateStatus(
            @PathVariable UUID id,
            @RequestBody UpdateProductStatusRequest request) {
        adminProductService.updateStatus(id, request.isActive());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteProduct(@PathVariable UUID id) {
        adminProductService.deleteProduct(id);
    }

    // =========================================================================
    // Product Variant Management
    // =========================================================================

    @GetMapping("/{productId}/variants")
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    public List<ProductVariantSummary> listVariants(@PathVariable UUID productId) {
        return adminProductService.listVariants(productId);
    }

    @PostMapping("/{productId}/variants")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    public ResponseEntity<ProductVariantSummary> createVariant(
            @PathVariable UUID productId,
            @Valid @RequestBody CreateVariantRequest request) {
        ProductVariantSummary created = adminProductService.createVariant(productId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{productId}/variants/{variantId}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    public ProductVariantSummary updateVariant(
            @PathVariable UUID productId,
            @PathVariable UUID variantId,
            @Valid @RequestBody UpdateVariantRequest request) {
        return adminProductService.updateVariant(productId, variantId, request);
    }

    @DeleteMapping("/{productId}/variants/{variantId}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteVariant(
            @PathVariable UUID productId,
            @PathVariable UUID variantId) {
        adminProductService.deleteVariant(productId, variantId);
    }
}
