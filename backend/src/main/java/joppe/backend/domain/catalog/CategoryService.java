package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    @Transactional
    public Integer createCategory(Integer parentId, String categoryName, String slug, String iconUrl) {
        if (categoryRepository.existsBySlug(slug)) {
            throw new IllegalArgumentException("Category slug already exists: " + slug);
        }
        if (parentId != null && !categoryRepository.existsById(parentId)) {
            throw new IllegalArgumentException("Parent category not found with ID: " + parentId);
        }

        Category category = Category.builder()
                .parentId(parentId)
                .categoryName(categoryName)
                .slug(slug)
                .iconUrl(iconUrl)
                .isActive(true)
                .build();

        return categoryRepository.save(category).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Category> findById(Integer categoryId) {
        return categoryRepository.findById(categoryId);
    }

    @Transactional(readOnly = true)
    public Optional<Category> findBySlug(String slug) {
        return categoryRepository.findBySlug(slug);
    }

    @Transactional(readOnly = true)
    public List<Category> getActiveCategories() {
        return categoryRepository.findByIsActiveTrue();
    }

    @Transactional
    public void updateActiveStatus(Integer categoryId, boolean isActive) {
        categoryRepository.updateActiveStatus(categoryId, isActive);
    }
}
