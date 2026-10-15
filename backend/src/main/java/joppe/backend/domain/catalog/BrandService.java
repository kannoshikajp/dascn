package joppe.backend.domain.catalog;

import java.util.List;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BrandService {

    private final BrandRepository brandRepository;

    @Transactional
    public Integer createBrand(String brandName, String slug, String logoUrl) {
        if (brandRepository.existsByBrandName(brandName)) {
            throw new IllegalArgumentException("Brand name already exists: " + brandName);
        }
        if (brandRepository.existsBySlug(slug)) {
            throw new IllegalArgumentException("Brand slug already exists: " + slug);
        }

        Brand brand = Brand.builder()
                .brandName(brandName)
                .slug(slug)
                .logoUrl(logoUrl)
                .isActive(true)
                .build();

        return brandRepository.save(brand).getId();
    }

    @Transactional(readOnly = true)
    public Optional<Brand> findById(Integer brandId) {
        return brandRepository.findById(brandId);
    }

    @Transactional(readOnly = true)
    public Optional<Brand> findBySlug(String slug) {
        return brandRepository.findBySlug(slug);
    }

    @Transactional(readOnly = true)
    public List<Brand> getActiveBrands() {
        return brandRepository.findByIsActiveTrue();
    }

    @Transactional
    public void updateActiveStatus(Integer brandId, boolean isActive) {
        brandRepository.updateActiveStatus(brandId, isActive);
    }
}
