package joppe.backend.admin.controller;

import jakarta.validation.Valid;
import java.util.List;
import joppe.backend.admin.dto.CategoryNodeResponse;
import joppe.backend.admin.dto.CategoryResponse;
import joppe.backend.admin.dto.CreateCategoryRequest;
import joppe.backend.admin.dto.UpdateCategoryRequest;
import joppe.backend.admin.service.CategoryManagementService;
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
@RequestMapping("/api/v1/admin/categories")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('CATALOG_WRITE')")
public class AdminCategoryController {

    private final CategoryManagementService categoryService;

    @GetMapping
    public ResponseEntity<List<CategoryResponse>> listCategories(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive
    ) {
        List<CategoryResponse> categories = categoryService.listCategoriesFlat(search, isActive);
        return ResponseEntity.ok(categories);
    }

    @GetMapping("/tree")
    public ResponseEntity<List<CategoryNodeResponse>> getCategoryTree(
            @RequestParam(required = false) Boolean isActive
    ) {
        List<CategoryNodeResponse> tree = categoryService.listCategoryTree(isActive);
        return ResponseEntity.ok(tree);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponse> getCategory(@PathVariable Integer id) {
        CategoryResponse category = categoryService.getCategory(id);
        return ResponseEntity.ok(category);
    }

    @PostMapping
    public ResponseEntity<CategoryResponse> createCategory(@Valid @RequestBody CreateCategoryRequest request) {
        CategoryResponse category = categoryService.createCategory(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(category);
    }

    @PutMapping("/{id}")
    public ResponseEntity<CategoryResponse> updateCategory(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateCategoryRequest request
    ) {
        CategoryResponse category = categoryService.updateCategory(id, request);
        return ResponseEntity.ok(category);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Void> updateStatus(
            @PathVariable Integer id,
            @RequestParam boolean isActive
    ) {
        categoryService.updateStatus(id, isActive);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable Integer id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}
