package joppe.backend.admin.service;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import joppe.backend.admin.dto.CreateProductRequest;
import joppe.backend.admin.dto.CreateVariantRequest;
import joppe.backend.admin.dto.ProductCategorySummary;
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.dto.ProductVariantSummary;
import joppe.backend.admin.dto.UpdateProductRequest;
import joppe.backend.admin.dto.UpdateVariantRequest;
import joppe.backend.domain.catalog.Brand;
import joppe.backend.domain.catalog.BrandRepository;
import joppe.backend.domain.catalog.Category;
import joppe.backend.domain.catalog.CategoryRepository;
import joppe.backend.domain.catalog.Product;
import joppe.backend.domain.catalog.ProductCategory;
import joppe.backend.domain.catalog.ProductCategoryRepository;
import joppe.backend.domain.catalog.ProductRepository;
import joppe.backend.domain.catalog.ProductVariant;
import joppe.backend.domain.catalog.ProductVariantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AdminProductService {

    private static final Pattern NON_LATIN = Pattern.compile("[^\\w-]");
    private static final Pattern WHITESPACE = Pattern.compile("[\\s]");

    private final ProductRepository productRepository;
    private final ProductCategoryRepository productCategoryRepository;
    private final CategoryRepository categoryRepository;
    private final BrandRepository brandRepository;
    private final ProductVariantRepository productVariantRepository;

    @Transactional(readOnly = true)
    public List<ProductResponse> listProducts(String search, Integer categoryId, Integer brandId, Boolean isActive) {
        List<Product> products = productRepository.findFiltered(categoryId, brandId, isActive);

        Map<Integer, Category> categoryMap = categoryRepository.findAll().stream()
                .collect(Collectors.toMap(Category::getId, c -> c));
        Map<Integer, Brand> brandMap = brandRepository.findAll().stream()
                .collect(Collectors.toMap(Brand::getId, b -> b));

        String searchLower = (search != null && !search.trim().isEmpty())
                ? search.trim().toLowerCase(Locale.ROOT)
                : null;

        List<ProductResponse> responses = new ArrayList<>();
        for (Product p : products) {
            List<ProductVariant> variants = productVariantRepository.findByProductId(p.getId());

            if (searchLower != null) {
                boolean matchesName = p.getProductName().toLowerCase(Locale.ROOT).contains(searchLower);
                boolean matchesSlug = p.getSlug().toLowerCase(Locale.ROOT).contains(searchLower);
                boolean matchesSku = variants.stream().anyMatch(v -> v.getSku().toLowerCase(Locale.ROOT).contains(searchLower));
                if (!matchesName && !matchesSlug && !matchesSku) {
                    continue;
                }
            }

            responses.add(buildProductResponse(p, variants, categoryMap, brandMap));
        }

        return responses;
    }

    @Transactional(readOnly = true)
    public ProductResponse getProductById(UUID id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + id));
        List<ProductVariant> variants = productVariantRepository.findByProductId(id);
        Map<Integer, Category> categoryMap = categoryRepository.findAll().stream()
                .collect(Collectors.toMap(Category::getId, c -> c));
        Map<Integer, Brand> brandMap = brandRepository.findAll().stream()
                .collect(Collectors.toMap(Brand::getId, b -> b));
        return buildProductResponse(product, variants, categoryMap, brandMap);
    }

    @Transactional(readOnly = true)
    public ProductResponse getProductBySlug(String slug) {
        Product product = productRepository.findBySlug(slug)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with slug: " + slug));
        List<ProductVariant> variants = productVariantRepository.findByProductId(product.getId());
        Map<Integer, Category> categoryMap = categoryRepository.findAll().stream()
                .collect(Collectors.toMap(Category::getId, c -> c));
        Map<Integer, Brand> brandMap = brandRepository.findAll().stream()
                .collect(Collectors.toMap(Brand::getId, b -> b));
        return buildProductResponse(product, variants, categoryMap, brandMap);
    }

    @Transactional
    public ProductResponse createProduct(CreateProductRequest req) {
        if (req.brandId() != null && !brandRepository.existsById(req.brandId())) {
            throw new IllegalArgumentException("Brand not found with ID: " + req.brandId());
        }

        String rawSlug = (req.slug() != null && !req.slug().trim().isEmpty())
                ? req.slug().trim()
                : slugify(req.productName());
        String finalSlug = ensureUniqueSlug(rawSlug, null);

        Integer primaryCategoryId = req.primaryCategoryId();
        if (primaryCategoryId == null && req.categoryIds() != null && !req.categoryIds().isEmpty()) {
            primaryCategoryId = req.categoryIds().getFirst();
        }

        Product product = Product.builder()
                .categoryId(primaryCategoryId)
                .brandId(req.brandId())
                .productName(req.productName().trim())
                .slug(finalSlug)
                .shortDescription(req.shortDescription())
                .description(req.description())
                .specifications(req.specifications())
                .warrantyMonths(req.warrantyMonths() != null ? req.warrantyMonths() : 0)
                .thumbnailUrl(req.thumbnailUrl())
                .isActive(req.isActive() != null ? req.isActive() : true)
                .build();

        Product saved = productRepository.save(product);

        // Associate multiple categories
        syncProductCategories(saved.getId(), req.categoryIds(), primaryCategoryId);

        // Create default variant if listPrice or SKU is specified or as default placeholder
        createInitialVariant(saved, req);

        return getProductById(saved.getId());
    }

    @Transactional
    public ProductResponse updateProduct(UUID id, UpdateProductRequest req) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + id));

        if (req.brandId() != null && !brandRepository.existsById(req.brandId())) {
            throw new IllegalArgumentException("Brand not found with ID: " + req.brandId());
        }

        String rawSlug = (req.slug() != null && !req.slug().trim().isEmpty())
                ? req.slug().trim()
                : slugify(req.productName());
        String finalSlug = ensureUniqueSlug(rawSlug, id);

        Integer primaryCategoryId = req.primaryCategoryId();
        if (primaryCategoryId == null && req.categoryIds() != null && !req.categoryIds().isEmpty()) {
            primaryCategoryId = req.categoryIds().getFirst();
        }

        product.setProductName(req.productName().trim());
        product.setSlug(finalSlug);
        product.setBrandId(req.brandId());
        product.setCategoryId(primaryCategoryId);
        product.setShortDescription(req.shortDescription());
        product.setDescription(req.description());
        product.setSpecifications(req.specifications());
        if (req.warrantyMonths() != null) {
            product.setWarrantyMonths(req.warrantyMonths());
        }
        product.setThumbnailUrl(req.thumbnailUrl());
        if (req.isActive() != null) {
            product.setIsActive(req.isActive());
        }

        Product saved = productRepository.save(product);

        // Sync multiple categories
        syncProductCategories(saved.getId(), req.categoryIds(), primaryCategoryId);

        return getProductById(saved.getId());
    }

    @Transactional
    public void updateStatus(UUID id, boolean isActive) {
        if (!productRepository.existsById(id)) {
            throw new IllegalArgumentException("Product not found with ID: " + id);
        }
        productRepository.updateActiveStatus(id, isActive);
    }

    @Transactional
    public void deleteProduct(UUID id) {
        if (!productRepository.existsById(id)) {
            throw new IllegalArgumentException("Product not found with ID: " + id);
        }
        productCategoryRepository.deleteByProductId(id);
        productRepository.deleteById(id);
    }

    @Transactional(readOnly = true)
    public List<ProductVariantSummary> listVariants(UUID productId) {
        if (!productRepository.existsById(productId)) {
            throw new IllegalArgumentException("Product not found with ID: " + productId);
        }
        return productVariantRepository.findByProductId(productId).stream()
                .map(this::toVariantSummary)
                .toList();
    }

    @Transactional
    public ProductVariantSummary createVariant(UUID productId, CreateVariantRequest req) {
        if (!productRepository.existsById(productId)) {
            throw new IllegalArgumentException("Product not found with ID: " + productId);
        }
        String sku = req.sku().trim().toUpperCase(Locale.ROOT);
        if (productVariantRepository.existsBySku(sku)) {
            throw new IllegalArgumentException("SKU already exists: " + sku);
        }

        BigDecimal listPrice = req.listPrice() != null ? req.listPrice() : BigDecimal.ZERO;
        BigDecimal salePrice = req.salePrice() != null ? req.salePrice() : listPrice;
        int stock = req.quantityOnHand() != null ? req.quantityOnHand() : 0;
        int reorder = req.reorderLevel() != null ? req.reorderLevel() : 10;
        BigDecimal weight = req.weightGram() != null ? req.weightGram() : BigDecimal.ZERO;

        ProductVariant variant = ProductVariant.builder()
                .productId(productId)
                .sku(sku)
                .variantName(req.variantName().trim())
                .attributes(req.attributes())
                .listPrice(listPrice)
                .salePrice(salePrice)
                .quantityOnHand(stock)
                .quantityReserved(0)
                .reorderLevel(reorder)
                .weightGram(weight)
                .isActive(req.isActive() != null ? req.isActive() : true)
                .build();

        ProductVariant saved = productVariantRepository.save(variant);
        return toVariantSummary(saved);
    }

    @Transactional
    public ProductVariantSummary updateVariant(UUID productId, UUID variantId, UpdateVariantRequest req) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Variant not found with ID: " + variantId));

        if (!variant.getProductId().equals(productId)) {
            throw new IllegalArgumentException("Variant does not belong to product: " + productId);
        }

        String newSku = req.sku().trim().toUpperCase(Locale.ROOT);
        if (!variant.getSku().equalsIgnoreCase(newSku) && productVariantRepository.existsBySku(newSku)) {
            throw new IllegalArgumentException("SKU already exists: " + newSku);
        }

        variant.setSku(newSku);
        variant.setVariantName(req.variantName().trim());
        variant.setAttributes(req.attributes());
        if (req.listPrice() != null) variant.setListPrice(req.listPrice());
        if (req.salePrice() != null) variant.setSalePrice(req.salePrice());
        if (req.quantityOnHand() != null) variant.setQuantityOnHand(req.quantityOnHand());
        if (req.reorderLevel() != null) variant.setReorderLevel(req.reorderLevel());
        if (req.weightGram() != null) variant.setWeightGram(req.weightGram());
        if (req.isActive() != null) variant.setIsActive(req.isActive());

        ProductVariant saved = productVariantRepository.save(variant);
        return toVariantSummary(saved);
    }

    @Transactional
    public void deleteVariant(UUID productId, UUID variantId) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Variant not found with ID: " + variantId));

        if (!variant.getProductId().equals(productId)) {
            throw new IllegalArgumentException("Variant does not belong to product: " + productId);
        }

        productVariantRepository.deleteById(variantId);
    }

    private ProductVariantSummary toVariantSummary(ProductVariant v) {
        int reserved = v.getQuantityReserved() != null ? v.getQuantityReserved() : 0;
        int onHand = v.getQuantityOnHand() != null ? v.getQuantityOnHand() : 0;
        return new ProductVariantSummary(
                v.getId(),
                v.getSku(),
                v.getVariantName(),
                v.getAttributes(),
                v.getListPrice(),
                v.getSalePrice(),
                onHand,
                reserved,
                onHand - reserved,
                v.getWeightGram(),
                v.getIsActive()
        );
    }

    private void syncProductCategories(UUID productId, List<Integer> categoryIds, Integer primaryCategoryId) {
        productCategoryRepository.deleteByProductId(productId);

        if (categoryIds == null || categoryIds.isEmpty()) {
            if (primaryCategoryId != null) {
                categoryIds = List.of(primaryCategoryId);
            } else {
                return;
            }
        }

        List<ProductCategory> mappings = new ArrayList<>();
        for (Integer catId : categoryIds) {
            if (catId == null) continue;
            boolean isPrimary = Objects.equals(catId, primaryCategoryId);
            mappings.add(ProductCategory.builder()
                    .productId(productId)
                    .categoryId(catId)
                    .isPrimary(isPrimary)
                    .build());
        }

        productCategoryRepository.saveAll(mappings);
    }

    private void createInitialVariant(Product product, CreateProductRequest req) {
        String baseSku = (req.sku() != null && !req.sku().trim().isEmpty())
                ? req.sku().trim().toUpperCase(Locale.ROOT)
                : generateDefaultSku(product.getSlug());

        BigDecimal listPrice = req.listPrice() != null ? req.listPrice() : BigDecimal.ZERO;
        BigDecimal salePrice = req.salePrice() != null ? req.salePrice() : listPrice;
        int stock = req.stockQuantity() != null ? req.stockQuantity() : 0;

        ProductVariant variant = ProductVariant.builder()
                .productId(product.getId())
                .sku(baseSku)
                .variantName("Default - " + product.getProductName())
                .listPrice(listPrice)
                .salePrice(salePrice)
                .quantityOnHand(stock)
                .quantityReserved(0)
                .isActive(true)
                .build();

        productVariantRepository.save(variant);
    }

    private String generateDefaultSku(String slug) {
        String cleaned = slug.replaceAll("[^a-zA-Z0-9]", "").toUpperCase(Locale.ROOT);
        String prefix = cleaned.length() > 6 ? cleaned.substring(0, 6) : cleaned;
        return "SKU-" + prefix + "-" + (System.currentTimeMillis() % 100000);
    }

    private ProductResponse buildProductResponse(
            Product p,
            List<ProductVariant> variants,
            Map<Integer, Category> categoryMap,
            Map<Integer, Brand> brandMap) {

        List<ProductCategory> categoryMappings = productCategoryRepository.findByProductId(p.getId());
        List<ProductCategorySummary> categorySummaries = new ArrayList<>();

        for (ProductCategory pc : categoryMappings) {
            Category cat = categoryMap.get(pc.getCategoryId());
            if (cat != null) {
                categorySummaries.add(new ProductCategorySummary(
                        cat.getId(),
                        cat.getCategoryName(),
                        cat.getSlug(),
                        Boolean.TRUE.equals(pc.getIsPrimary())
                ));
            }
        }

        // If no product_categories rows yet but p.getCategoryId() is set
        if (categorySummaries.isEmpty() && p.getCategoryId() != null) {
            Category cat = categoryMap.get(p.getCategoryId());
            if (cat != null) {
                categorySummaries.add(new ProductCategorySummary(
                        cat.getId(),
                        cat.getCategoryName(),
                        cat.getSlug(),
                        true
                ));
            }
        }

        List<ProductVariantSummary> variantSummaries = variants.stream()
                .map(this::toVariantSummary)
                .toList();

        BigDecimal minPrice = variants.stream()
                .map(ProductVariant::getSalePrice)
                .filter(Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElse(BigDecimal.ZERO);

        BigDecimal maxPrice = variants.stream()
                .map(ProductVariant::getSalePrice)
                .filter(Objects::nonNull)
                .max(Comparator.naturalOrder())
                .orElse(BigDecimal.ZERO);

        int totalStock = variants.stream()
                .mapToInt(v -> v.getQuantityOnHand() != null ? v.getQuantityOnHand() : 0)
                .sum();

        String brandName = p.getBrandId() != null && brandMap.containsKey(p.getBrandId())
                ? brandMap.get(p.getBrandId()).getBrandName()
                : null;

        return new ProductResponse(
                p.getId(),
                p.getProductName(),
                p.getSlug(),
                p.getBrandId(),
                brandName,
                p.getShortDescription(),
                p.getDescription(),
                p.getSpecifications(),
                p.getWarrantyMonths(),
                p.getThumbnailUrl(),
                p.getIsActive(),
                p.getCreatedAt(),
                p.getUpdatedAt(),
                categorySummaries,
                variantSummaries,
                minPrice,
                maxPrice,
                totalStock
        );
    }

    private String ensureUniqueSlug(String baseSlug, UUID currentProductId) {
        String slug = baseSlug;
        int count = 1;
        while (true) {
            var existing = productRepository.findBySlug(slug);
            if (existing.isEmpty() || (currentProductId != null && existing.get().getId().equals(currentProductId))) {
                return slug;
            }
            slug = baseSlug + "-" + count++;
        }
    }

    private String slugify(String input) {
        if (input == null) return "";
        String nowhitespace = WHITESPACE.matcher(input.trim().toLowerCase(Locale.ROOT)).replaceAll("-");
        String normalized = Normalizer.normalize(nowhitespace, Normalizer.Form.NFD);
        String slug = NON_LATIN.matcher(normalized).replaceAll("");
        return slug.replaceAll("-{2,}", "-").replaceAll("^-|-$", "");
    }
}
