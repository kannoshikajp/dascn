package joppe.backend.domain.catalog;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import joppe.backend.admin.dto.CategoryNodeResponse;
import joppe.backend.admin.dto.CategoryResponse;
import joppe.backend.admin.service.CategoryManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/categories")
@RequiredArgsConstructor
@Tag(name = "Categories (Public)", description = "Public endpoints for browsing category trees and details")
public class CategoryController {

    private final CategoryManagementService categoryService;
    private final CategoryRepository categoryRepository;

    @GetMapping("/tree")
    @Operation(summary = "Get active categories in hierarchical tree structure")
    public ResponseEntity<List<CategoryNodeResponse>> getActiveCategoryTree() {
        List<CategoryNodeResponse> tree = categoryService.listCategoryTree(true);
        return ResponseEntity.ok(tree);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get category details by ID")
    public ResponseEntity<CategoryResponse> getCategoryById(@PathVariable Integer id) {
        CategoryResponse category = categoryService.getCategory(id);
        return ResponseEntity.ok(category);
    }

    @GetMapping("/slug/{slug}")
    @Operation(summary = "Get category details by slug")
    public ResponseEntity<CategoryResponse> getCategoryBySlug(@PathVariable String slug) {
        return categoryRepository.findBySlug(slug)
                .map(c -> ResponseEntity.ok(categoryService.getCategory(c.getId())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
