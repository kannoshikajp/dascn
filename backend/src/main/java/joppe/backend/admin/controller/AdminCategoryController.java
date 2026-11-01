package joppe.backend.admin.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import joppe.backend.admin.dto.CategoryNodeResponse;
import joppe.backend.admin.dto.CategoryResponse;
import joppe.backend.admin.dto.CreateCategoryRequest;
import joppe.backend.admin.dto.UpdateCategoryRequest;
import joppe.backend.admin.service.CategoryManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
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
@RequestMapping("/api/v1/admin/categories")
@RequiredArgsConstructor
@PreAuthorize("hasAnyAuthority('CATALOG_READ', 'CATALOG_WRITE')")
@Tag(name = "Admin - Categories", description = "Administrative endpoints for nested category hierarchy management")
public class AdminCategoryController {

    private final CategoryManagementService categoryService;

    @GetMapping
    @Operation(summary = "List categories as flat list with search and status filter")
    public ResponseEntity<List<CategoryResponse>> listCategories(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive
    ) {
        List<CategoryResponse> categories = categoryService.listCategoriesFlat(search, isActive);
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/tree")
    @Operation(summary = "List categories as hierarchical nested tree")
    public ResponseEntity<List<CategoryNodeResponse>> getCategoryTree(
            @RequestParam(required = false) Boolean isActive
    ) {
        List<CategoryNodeResponse> tree = categoryService.listCategoryTree(isActive);
        return ResponseEntity.ok(tree);
    }

    @GetMapping(value = "/export", produces = "text/csv; charset=UTF-8")
    @Operation(summary = "Export categories to CSV file")
    public ResponseEntity<byte[]> exportCategories(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive
    ) {
        byte[] csv = categoryService.exportCategoriesCsv(search, isActive);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"categories.csv\"")
                .header(HttpHeaders.CONTENT_TYPE, "text/csv; charset=UTF-8")
                .body(csv);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get category by ID")
    public ResponseEntity<CategoryResponse> getCategory(@PathVariable Integer id) {
        CategoryResponse category = categoryService.getCategory(id);
        return ResponseEntity.ok(category);
    }

    @PostMapping
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Create a new category")
    public ResponseEntity<CategoryResponse> createCategory(@Valid @RequestBody CreateCategoryRequest request) {
        CategoryResponse category = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(category);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Update an existing category")
    public ResponseEntity<CategoryResponse> updateCategory(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateCategoryRequest request
    ) {
        CategoryResponse category = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(category);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Toggle category active status")
    public ResponseEntity<Void> updateStatus(
            @PathVariable Integer id,
            @RequestParam boolean isActive
    ) {
        categoryService.updateStatus(id, isActive);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('CATALOG_WRITE')")
    @Operation(summary = "Delete category by ID (cascade check)")
    public ResponseEntity<Void> deleteCategory(@PathVariable Integer id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}
