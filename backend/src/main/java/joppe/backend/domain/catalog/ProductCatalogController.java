package joppe.backend.domain.catalog;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import java.util.UUID;
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.service.AdminProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/products")
@RequiredArgsConstructor
@Tag(name = "Products (Public)", description = "Public catalog endpoints for browsing products and filters")
public class ProductCatalogController {

    private final AdminProductService adminProductService;

    @GetMapping
    @Operation(summary = "List active products with optional filters (search, category, brand)")
    public List<ProductResponse> listActiveProducts(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer brandId) {
        return adminProductService.listProducts(search, categoryId, brandId, true);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get product details by ID")
    public ProductResponse getProductById(@PathVariable UUID id) {
        return adminProductService.getProductById(id);
    }

    @GetMapping("/slug/{slug}")
    @Operation(summary = "Get product details by URL slug")
    public ProductResponse getProductBySlug(@PathVariable String slug) {
        return adminProductService.getProductBySlug(slug);
    }
}
