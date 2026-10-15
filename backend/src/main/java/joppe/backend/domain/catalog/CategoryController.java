package joppe.backend.domain.catalog;

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
public class CategoryController {

    private final CategoryManagementService categoryService;
    private final CategoryRepository categoryRepository;

    @GetMapping("/tree")
    public ResponseEntity<List<CategoryNodeResponse>> getActiveCategoryTree() {
        List<CategoryNodeResponse> tree = categoryService.listCategoryTree(true);
        return ResponseEntity.ok(tree);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CategoryResponse> getCategoryById(@PathVariable Integer id) {
        CategoryResponse category = categoryService.getCategory(id);
        return ResponseEntity.ok(category);
    }

    @GetMapping("/slug/{slug}")
    public ResponseEntity<CategoryResponse> getCategoryBySlug(@PathVariable String slug) {
        return categoryRepository.findBySlug(slug)
                .map(c -> ResponseEntity.ok(categoryService.getCategory(c.getId())))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
