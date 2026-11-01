package joppe.backend.admin.service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Queue;
import java.util.Set;
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
import joppe.backend.common.util.CsvHelper;
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
import joppe.backend.domain.catalog.VariantMedia;
import joppe.backend.domain.catalog.VariantMediaRepository;
import joppe.backend.media.domain.UploadedMedia;
import joppe.backend.media.domain.UploadedMediaRepository;
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
    private final VariantMediaRepository variantMediaRepository;
    private final UploadedMediaRepository uploadedMediaRepository;

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
                boolean matchesSku = (p.getSku() != null && p.getSku().toLowerCase(Locale.ROOT).contains(searchLower))
                        || variants.stream().anyMatch(v -> v.getSku().toLowerCase(Locale.ROOT).contains(searchLower));
                boolean matchesParentSku = p.getParentSku() != null && p.getParentSku().toLowerCase(Locale.ROOT).contains(searchLower);
                boolean matchesSlug = p.getSlug().toLowerCase(Locale.ROOT).contains(searchLower);
                if (!matchesName && !matchesSku && !matchesParentSku && !matchesSlug) {
                    continue;
                }
            }

            responses.add(buildProductResponse(p, variants, categoryMap, brandMap));
        }

        return responses;
    }

    @Transactional(readOnly = true)
    public byte[] exportProductsCsv(String search, Integer categoryId, Integer brandId, Boolean isActive) {
        List<ProductResponse> products = listProducts(search, categoryId, brandId, isActive);
        StringBuilder sb = new StringBuilder();
        sb.append('﻿'); // UTF-8 BOM
        sb.append("ID,Product Name,SKU,Parent SKU,Slug,Brand,Active,Categories,Min Price,Max Price,Total Stock,Created At\r\n");

        for (ProductResponse p : products) {
            String categoriesStr = p.categories() == null ? "" : p.categories().stream()
                    .map(c -> c.categoryName() + (Boolean.TRUE.equals(c.isPrimary()) ? " (Primary)" : ""))
                    .collect(Collectors.joining("; "));

            sb.append(CsvHelper.escape(p.id())).append(",")
              .append(CsvHelper.escape(p.productName())).append(",")
              .append(CsvHelper.escape(p.sku())).append(",")
              .append(CsvHelper.escape(p.parentSku())).append(",")
              .append(CsvHelper.escape(p.slug())).append(",")
              .append(CsvHelper.escape(p.brandName())).append(",")
              .append(p.isActive() != null && p.isActive() ? "Active" : "Inactive").append(",")
              .append(CsvHelper.escape(categoriesStr)).append(",")
              .append(p.minPrice() != null ? p.minPrice().toPlainString() : "").append(",")
              .append(p.maxPrice() != null ? p.maxPrice().toPlainString() : "").append(",")
              .append(p.totalStock() != null ? p.totalStock() : 0).append(",")
              .append(CsvHelper.escape(p.createdAt())).append("\r\n");
        }

        return sb.toString().getBytes(StandardCharsets.UTF_8);
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
                .orElse(null);

        if (product == null) {
            // Check if slug matches sku
            product = productRepository.findBySku(slug.toUpperCase(Locale.ROOT)).orElse(null);
        }

        if (product == null) {
            throw new IllegalArgumentException("Product not found with slug or SKU: " + slug);
        }

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

        String sku = req.sku().trim().toUpperCase(Locale.ROOT);
        if (productRepository.existsBySku(sku) || productVariantRepository.existsBySku(sku)) {
            throw new IllegalArgumentException("SKU already exists: " + sku);
        }

        String parentSku = (req.parentSku() != null && !req.parentSku().isBlank())
                ? req.parentSku().trim().toUpperCase(Locale.ROOT)
                : null;
        if (parentSku != null && !productRepository.existsBySku(parentSku)) {
            throw new IllegalArgumentException("Parent product with SKU not found: " + parentSku);
        }

        // Rule: When adding a product, if not specified the slug will be the sku with spaces replaced with "-"
        String rawSlug = (req.slug() != null && !req.slug().trim().isEmpty())
                ? req.slug().trim()
                : sku.toLowerCase(Locale.ROOT).replaceAll("\\s+", "-");
        String finalSlug = ensureUniqueSlug(rawSlug, null);

        Integer primaryCategoryId = req.primaryCategoryId();
        if (primaryCategoryId == null && req.categoryIds() != null && !req.categoryIds().isEmpty()) {
            primaryCategoryId = req.categoryIds().getFirst();
        }

        Product product = Product.builder()
                .categoryId(primaryCategoryId)
                .brandId(req.brandId())
                .productName(req.productName().trim())
                .sku(sku)
                .parentSku(parentSku)
                .slug(finalSlug)
                .isActive(req.isActive() != null ? req.isActive() : true)
                .build();

        Product saved = productRepository.save(product);

        // Associate multiple categories
        syncProductCategories(saved.getId(), req.categoryIds(), primaryCategoryId);

        // Create default initial variant
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

        String newSku = (req.sku() != null && !req.sku().isBlank())
                ? req.sku().trim().toUpperCase(Locale.ROOT)
                : product.getSku();

        if (!newSku.equalsIgnoreCase(product.getSku()) && (productRepository.existsBySku(newSku) || productVariantRepository.existsBySku(newSku))) {
            throw new IllegalArgumentException("SKU already exists: " + newSku);
        }

        String parentSku = (req.parentSku() != null && !req.parentSku().isBlank())
                ? req.parentSku().trim().toUpperCase(Locale.ROOT)
                : null;
        if (parentSku != null && !parentSku.equalsIgnoreCase(product.getSku()) && !productRepository.existsBySku(parentSku)) {
            throw new IllegalArgumentException("Parent product with SKU not found: " + parentSku);
        }

        // Slug is immutable to prevent routing and SEO breakage
        Integer primaryCategoryId = req.primaryCategoryId();
        if (primaryCategoryId == null && req.categoryIds() != null && !req.categoryIds().isEmpty()) {
            primaryCategoryId = req.categoryIds().getFirst();
        }

        product.setProductName(req.productName().trim());
        product.setSku(newSku);
        product.setParentSku(parentSku);
        product.setBrandId(req.brandId());
        product.setCategoryId(primaryCategoryId);
        if (req.isActive() != null) {
            product.setIsActive(req.isActive());
        }

        Product saved = productRepository.save(product);

        // Sync primary variant fields (SKU, price, stock, thumbnail, description)
        List<ProductVariant> variants = productVariantRepository.findByProductId(saved.getId());
        if (!variants.isEmpty()) {
            ProductVariant v = variants.getFirst();
            v.setSku(newSku);
            v.setVariantName(saved.getProductName());
            if (req.listPrice() != null) v.setListPrice(req.listPrice());
            if (req.salePrice() != null) {
                BigDecimal effSale = (req.salePrice().compareTo(BigDecimal.ZERO) > 0)
                        ? req.salePrice()
                        : (req.listPrice() != null ? req.listPrice() : v.getListPrice());
                v.setSalePrice(effSale);
            } else if (req.listPrice() != null && (v.getSalePrice() == null || v.getSalePrice().compareTo(BigDecimal.ZERO) == 0)) {
                v.setSalePrice(req.listPrice());
            }
            if (req.stockQuantity() != null) v.setQuantityOnHand(req.stockQuantity());
            if (req.thumbnailUrl() != null) v.setThumbnailUrl(req.thumbnailUrl());
            if (req.description() != null) v.setDescription(req.description());
            productVariantRepository.save(v);
        } else {
            // Create initial variant if not existed
            BigDecimal listPrice = req.listPrice() != null ? req.listPrice() : BigDecimal.ZERO;
            BigDecimal salePrice = (req.salePrice() != null && req.salePrice().compareTo(BigDecimal.ZERO) > 0)
                    ? req.salePrice()
                    : listPrice;

            ProductVariant v = ProductVariant.builder()
                    .productId(saved.getId())
                    .sku(newSku)
                    .variantName(saved.getProductName())
                    .listPrice(listPrice)
                    .salePrice(salePrice)
                    .quantityOnHand(req.stockQuantity() != null ? req.stockQuantity() : 0)
                    .thumbnailUrl(req.thumbnailUrl())
                    .description(req.description())
                    .isActive(true)
                    .build();
            productVariantRepository.save(v);
        }

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

        List<ProductVariant> variants = productVariantRepository.findByProductId(id);
        List<UUID> variantIds = variants.stream().map(ProductVariant::getId).toList();
        if (!variantIds.isEmpty()) {
            variantMediaRepository.deleteByVariantIdIn(variantIds);
            productVariantRepository.deleteAll(variants);
        }

        productCategoryRepository.deleteByProductId(id);
        productRepository.deleteById(id);
    }

    // =========================================================================
    // Product Variant Management
    // =========================================================================

    @Transactional(readOnly = true)
    public List<ProductVariantSummary> listVariants(UUID productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        return productVariantRepository.findByProductId(productId).stream()
                .map(v -> toVariantSummary(v, product.getSlug(), product.getParentSku()))
                .toList();
    }

    @Transactional
    public ProductVariantSummary createVariant(UUID productId, CreateVariantRequest req) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        String sku = req.sku().trim().toUpperCase(Locale.ROOT);
        if (productVariantRepository.existsBySku(sku) || productRepository.existsBySku(sku)) {
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
                .thumbnailUrl(req.thumbnailUrl())
                .description(req.description())
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

        // Sync album media if provided
        if (req.mediaIds() != null && !req.mediaIds().isEmpty()) {
            syncVariantMedia(saved.getId(), req.mediaIds());
        }

        return toVariantSummary(saved, product.getSlug(), product.getParentSku());
    }

    @Transactional
    public ProductVariantSummary updateVariant(UUID productId, UUID variantId, UpdateVariantRequest req) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new IllegalArgumentException("Product not found with ID: " + productId));

        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Variant not found with ID: " + variantId));

        if (!variant.getProductId().equals(productId)) {
            throw new IllegalArgumentException("Variant does not belong to product: " + productId);
        }

        String newSku = req.sku().trim().toUpperCase(Locale.ROOT);
        if (!variant.getSku().equalsIgnoreCase(newSku) && (productVariantRepository.existsBySku(newSku) || productRepository.existsBySku(newSku))) {
            throw new IllegalArgumentException("SKU already exists: " + newSku);
        }

        variant.setSku(newSku);
        variant.setVariantName(req.variantName().trim());
        variant.setThumbnailUrl(req.thumbnailUrl());
        variant.setDescription(req.description());
        variant.setAttributes(req.attributes());
        if (req.listPrice() != null) variant.setListPrice(req.listPrice());
        if (req.salePrice() != null) variant.setSalePrice(req.salePrice());
        if (req.quantityOnHand() != null) variant.setQuantityOnHand(req.quantityOnHand());
        if (req.reorderLevel() != null) variant.setReorderLevel(req.reorderLevel());
        if (req.weightGram() != null) variant.setWeightGram(req.weightGram());
        if (req.isActive() != null) variant.setIsActive(req.isActive());

        ProductVariant saved = productVariantRepository.save(variant);

        // Sync album media
        if (req.mediaIds() != null) {
            syncVariantMedia(saved.getId(), req.mediaIds());
        }

        return toVariantSummary(saved, product.getSlug(), product.getParentSku());
    }

    @Transactional
    public void deleteVariant(UUID productId, UUID variantId) {
        ProductVariant variant = productVariantRepository.findById(variantId)
                .orElseThrow(() -> new IllegalArgumentException("Variant not found with ID: " + variantId));

        if (!variant.getProductId().equals(productId)) {
            throw new IllegalArgumentException("Variant does not belong to product: " + productId);
        }

        variantMediaRepository.deleteByVariantId(variantId);
        productVariantRepository.deleteById(variantId);
    }

    private void syncVariantMedia(UUID variantId, List<UUID> mediaIds) {
        variantMediaRepository.deleteByVariantId(variantId);

        if (mediaIds == null || mediaIds.isEmpty()) {
            return;
        }

        List<VariantMedia> mappings = new ArrayList<>();
        int order = 0;
        for (UUID mediaId : mediaIds) {
            if (mediaId == null) continue;
            mappings.add(VariantMedia.builder()
                    .variantId(variantId)
                    .mediaId(mediaId)
                    .displayOrder(order++)
                    .isPrimary(order == 1)
                    .build());
        }

        variantMediaRepository.saveAll(mappings);
    }

    private ProductVariantSummary toVariantSummary(ProductVariant v, String productSlug, String parentSku) {
        int reserved = v.getQuantityReserved() != null ? v.getQuantityReserved() : 0;
        int onHand = v.getQuantityOnHand() != null ? v.getQuantityOnHand() : 0;

        String compositeSlug = (productSlug != null ? productSlug : "") + "-" + v.getSku().toLowerCase(Locale.ROOT);

        // Load album media
        List<VariantMedia> albumMappings = variantMediaRepository.findByVariantIdOrderByDisplayOrderAsc(v.getId());
        List<UUID> mediaIds = albumMappings.stream().map(VariantMedia::getMediaId).toList();
        List<String> albumUrls = Collections.emptyList();

        if (!mediaIds.isEmpty()) {
            Map<UUID, String> mediaUrlMap = uploadedMediaRepository.findAllById(mediaIds).stream()
                    .collect(Collectors.toMap(UploadedMedia::getId, UploadedMedia::getFileUrl));
            albumUrls = mediaIds.stream()
                    .map(mediaUrlMap::get)
                    .filter(Objects::nonNull)
                    .toList();
        }

        return new ProductVariantSummary(
                v.getId(),
                v.getSku(),
                parentSku,
                v.getVariantName(),
                compositeSlug,
                v.getThumbnailUrl(),
                v.getDescription(),
                albumUrls,
                mediaIds,
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
        String baseSku = product.getSku();
        BigDecimal listPrice = req.listPrice() != null ? req.listPrice() : BigDecimal.ZERO;
        BigDecimal salePrice = (req.salePrice() != null && req.salePrice().compareTo(BigDecimal.ZERO) > 0)
                ? req.salePrice()
                : listPrice;
        int stock = req.stockQuantity() != null ? req.stockQuantity() : 0;

        ProductVariant variant = ProductVariant.builder()
                .productId(product.getId())
                .sku(baseSku)
                .variantName(product.getProductName())
                .thumbnailUrl(req.thumbnailUrl())
                .description(req.description())
                .attributes(req.attributes())
                .listPrice(listPrice)
                .salePrice(salePrice)
                .quantityOnHand(stock)
                .quantityReserved(0)
                .isActive(true)
                .build();

        productVariantRepository.save(variant);
    }

    public List<Product> resolveVariantFamily(Product target) {
        if (target == null || target.getSku() == null) {
            return Collections.emptyList();
        }

        // 1. Climb up to the root ancestor
        Product root = target;
        Set<String> visitedAncestorSkus = new HashSet<>();
        visitedAncestorSkus.add(root.getSku().toUpperCase(Locale.ROOT));

        while (root.getParentSku() != null && !root.getParentSku().isBlank()) {
            String parentSkuUpper = root.getParentSku().trim().toUpperCase(Locale.ROOT);
            if (visitedAncestorSkus.contains(parentSkuUpper)) {
                break;
            }
            visitedAncestorSkus.add(parentSkuUpper);
            Optional<Product> parentOpt = productRepository.findBySku(parentSkuUpper);
            if (parentOpt.isPresent()) {
                root = parentOpt.get();
            } else {
                break;
            }
        }

        // 2. Traverse all descendants from root (BFS)
        Set<UUID> familyIds = new HashSet<>();
        List<Product> family = new ArrayList<>();
        Queue<Product> queue = new ArrayDeque<>();

        family.add(root);
        familyIds.add(root.getId());
        queue.add(root);

        while (!queue.isEmpty()) {
            Product current = queue.poll();
            if (current.getSku() == null || current.getSku().isBlank()) continue;
            List<Product> children = productRepository.findByParentSku(current.getSku().trim().toUpperCase(Locale.ROOT));
            for (Product child : children) {
                if (familyIds.add(child.getId())) {
                    family.add(child);
                    queue.add(child);
                }
            }
        }

        // 3. Return all family members except target itself
        return family.stream()
                .filter(p -> !p.getId().equals(target.getId()))
                .toList();
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

        // Resolve complete variant family (supports arbitrary hierarchy depth: A -> B, C -> D, E)
        List<Product> variantProducts = resolveVariantFamily(p);

        List<ProductVariantSummary> variantSummaries = new ArrayList<>();
        if (!variantProducts.isEmpty()) {
            for (Product vp : variantProducts) {
                List<ProductVariant> vpVariants = productVariantRepository.findByProductId(vp.getId());
                if (!vpVariants.isEmpty()) {
                    ProductVariant primaryVariant = vpVariants.getFirst();
                    variantSummaries.add(toVariantSummary(primaryVariant, vp.getSlug(), vp.getParentSku()));
                }
            }
        } else {
            variantSummaries = variants.stream()
                    .map(v -> toVariantSummary(v, p.getSlug(), p.getParentSku()))
                    .toList();
        }

        java.util.function.Function<ProductVariant, BigDecimal> effectivePrice = v -> {
            if (v.getSalePrice() != null && v.getSalePrice().compareTo(BigDecimal.ZERO) > 0) {
                return v.getSalePrice();
            }
            return (v.getListPrice() != null && v.getListPrice().compareTo(BigDecimal.ZERO) > 0)
                    ? v.getListPrice()
                    : BigDecimal.ZERO;
        };

        BigDecimal minPrice = variants.stream()
                .map(effectivePrice)
                .filter(pr -> pr.compareTo(BigDecimal.ZERO) > 0)
                .min(Comparator.naturalOrder())
                .orElse(BigDecimal.ZERO);

        BigDecimal maxPrice = variants.stream()
                .map(effectivePrice)
                .filter(pr -> pr.compareTo(BigDecimal.ZERO) > 0)
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
                p.getSku(),
                p.getParentSku(),
                p.getSlug(),
                p.getBrandId(),
                brandName,
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

    private String slugify(String input) {
        if (input == null) return "";
        String nowhitespace = WHITESPACE.matcher(input.trim()).replaceAll("-");
        String normalized = Normalizer.normalize(nowhitespace, Normalizer.Form.NFD);
        String slug = NON_LATIN.matcher(normalized).replaceAll("");
        return slug.toLowerCase(Locale.ROOT).replaceAll("-+", "-").replaceAll("^-|-$", "");
    }

    private String ensureUniqueSlug(String baseSlug, UUID excludeId) {
        String slug = baseSlug;
        int counter = 1;
        while (true) {
            var existing = productRepository.findBySlug(slug);
            if (existing.isEmpty() || (excludeId != null && existing.get().getId().equals(excludeId))) {
                return slug;
            }
            slug = baseSlug + "-" + counter++;
        }
    }
}
