package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final BrandRepository brandRepository;

    @Transactional
    public UUID createProduct(
            Integer categoryId,
            Integer brandId,
            String productName,
            String slug,
            String shortDescription,
            String description,
            String specifications,
            int warrantyMonths,
            String thumbnailUrl) {

        if (categoryId != null && !categoryRepository.existsById(categoryId)) {
            throw new IllegalArgumentException("Category not found with ID: " + categoryId);
        }
        if (brandId != null && !brandRepository.existsById(brandId)) {
            throw new IllegalArgumentException("Brand not found with ID: " + brandId);
        }
        if (productRepository.existsBySlug(slug)) {
            throw new IllegalArgumentException("Product slug already exists: " + slug);
        }

        Product product = Product.builder()
                .categoryId(categoryId)
                .brandId(brandId)
                .productName(productName)
                .slug(slug)
                .shortDescription(shortDescription)
                .description(description)
                .specifications(specifications)
                .warrantyMonths(warrantyMonths)
                .thumbnailUrl(thumbnailUrl)
                .isActive(true)
                .build();

        return productRepository.save(product).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Product> findById(UUID productId) {
        return productRepository.findById(productId);
    }

    @Transactional(readOnly = true)
    public Optional<Product> findBySlug(String slug) {
        return productRepository.findBySlug(slug);
    }

    @Transactional(readOnly = true)
    public List<Product> getProductsByCategory(Integer categoryId) {
        return productRepository.findByCategoryIdAndIsActiveTrue(categoryId);
    }

    @Transactional(readOnly = true)
    public List<Product> getProductsByBrand(Integer brandId) {
        return productRepository.findByBrandIdAndIsActiveTrue(brandId);
    }

    @Transactional
    public void updateActiveStatus(UUID productId, boolean isActive) {
        productRepository.updateActiveStatus(productId, isActive);
    }
}
