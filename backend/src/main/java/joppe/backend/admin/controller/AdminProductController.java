package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "Admin - Products & Variants", description = "Administrative endpoints for multi-category products and hardware spec variants")
public class AdminProductController {

    private final AdminProductService adminProductService;

    @GetMapping
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    @Operation(summary = "List products with search, category, brand, and active filters")
    public List<ProductResponse> listProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer brandId,
            @RequestParam(required = false) Boolean isActive) {
        return adminProductService.listProducts(search, categoryId, brandId, isActive);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    @Operation(summary = "Get product details by ID")
    public ProductResponse getProductById(@PathVariable UUID id) {
        return adminProductService.getProductById(id);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Create product with multi-category mapping and initial default variant")
    public ResponseEntity<ProductResponse> createProduct(@Valid @RequestBody CreateProductRequest request) {
        ProductResponse created = adminProductService.createProduct(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Update product details and multi-category mappings")
    public ProductResponse updateProduct(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateProductRequest request) {
        return adminProductService.updateProduct(id, request);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Toggle product active status")
    public void updateStatus(
            @PathVariable UUID id,
            @RequestBody UpdateProductStatusRequest request) {
        adminProductService.updateStatus(id, request.isActive());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete product by ID (cascades variants and category mappings)")
    public void deleteProduct(@PathVariable UUID id) {
        adminProductService.deleteProduct(id);
    }

    // =========================================================================
    // Product Variant Management
    // =========================================================================

    @GetMapping("/{productId}/variants")
    @PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
    @Operation(summary = "List all hardware spec variants for a product")
    public List<ProductVariantSummary> listVariants(@PathVariable UUID productId) {
        return adminProductService.listVariants(productId);
    }

    @PostMapping("/{productId}/variants")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Create a spec variant (with JSONB hardware specs like RAM, GPU, CPU)")
    public ResponseEntity<ProductVariantSummary> createVariant(
            @PathVariable UUID productId,
            @Valid @RequestBody CreateVariantRequest request) {
        ProductVariantSummary created = adminProductService.createVariant(productId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{productId}/variants/{variantId}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Update a spec variant (SKU, price, stock, JSONB hardware specs)")
    public ProductVariantSummary updateVariant(
            @PathVariable UUID productId,
            @PathVariable UUID variantId,
            @Valid @RequestBody UpdateVariantRequest request) {
        return adminProductService.updateVariant(productId, variantId, request);
    }

    @DeleteMapping("/{productId}/variants/{variantId}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a spec variant")
    public void deleteVariant(
            @PathVariable UUID productId,
            @PathVariable UUID variantId) {
        adminProductService.deleteVariant(productId, variantId);
    }
}
