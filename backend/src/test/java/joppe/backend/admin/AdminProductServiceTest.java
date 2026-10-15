package joppe.backend.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import joppe.backend.admin.dto.CreateProductRequest;
import joppe.backend.admin.dto.CreateVariantRequest;
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.dto.ProductVariantSummary;
import joppe.backend.admin.dto.UpdateProductRequest;
import joppe.backend.admin.dto.UpdateVariantRequest;
import joppe.backend.admin.service.AdminProductService;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class AdminProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ProductCategoryRepository productCategoryRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private BrandRepository brandRepository;

    @Mock
    private ProductVariantRepository productVariantRepository;

    private AdminProductService service;

    @BeforeEach
    void setUp() {
        service = new AdminProductService(
                productRepository,
                productCategoryRepository,
                categoryRepository,
                brandRepository,
                productVariantRepository
        );
    }

    @Test
    void createProduct_WithMultipleCategories_Success() {
        UUID productId = UUID.randomUUID();
        CreateProductRequest request = new CreateProductRequest(
                "ASUS ROG Strix G16",
                "asus-rog-strix-g16",
                1,
                List.of(10, 20, 30),
                10,
                "High performance gaming laptop",
                "Full description here",
                "{\"cpu\": \"i9-13980HX\"}",
                24,
                "https://cdn.joppe.vn/g16.png",
                true,
                "SKU-ROG-G16-01",
                new BigDecimal("45000000"),
                new BigDecimal("42000000"),
                15
        );

        Product saved = Product.builder()
                .id(productId)
                .productName("ASUS ROG Strix G16")
                .slug("asus-rog-strix-g16")
                .brandId(1)
                .categoryId(10)
                .shortDescription("High performance gaming laptop")
                .description("Full description here")
                .specifications("{\"cpu\": \"i9-13980HX\"}")
                .warrantyMonths(24)
                .thumbnailUrl("https://cdn.joppe.vn/g16.png")
                .isActive(true)
                .build();

        Category c1 = Category.builder().id(10).categoryName("Laptops").slug("laptops").build();
        Category c2 = Category.builder().id(20).categoryName("Gaming").slug("gaming").build();
        Category c3 = Category.builder().id(30).categoryName("ASUS").slug("asus").build();
        Brand brand = Brand.builder().id(1).brandName("ASUS").slug("asus").build();

        ProductVariant variant = ProductVariant.builder()
                .id(UUID.randomUUID())
                .productId(productId)
                .sku("SKU-ROG-G16-01")
                .variantName("Default - ASUS ROG Strix G16")
                .listPrice(new BigDecimal("45000000"))
                .salePrice(new BigDecimal("42000000"))
                .quantityOnHand(15)
                .quantityReserved(0)
                .isActive(true)
                .build();

        when(brandRepository.existsById(1)).thenReturn(true);
        when(productRepository.findBySlug("asus-rog-strix-g16")).thenReturn(Optional.empty());
        when(productRepository.save(any(Product.class))).thenReturn(saved);
        when(productRepository.findById(productId)).thenReturn(Optional.of(saved));
        when(productVariantRepository.findByProductId(productId)).thenReturn(List.of(variant));
        when(categoryRepository.findAll()).thenReturn(List.of(c1, c2, c3));
        when(brandRepository.findAll()).thenReturn(List.of(brand));

        List<ProductCategory> mappings = List.of(
                ProductCategory.builder().productId(productId).categoryId(10).isPrimary(true).build(),
                ProductCategory.builder().productId(productId).categoryId(20).isPrimary(false).build(),
                ProductCategory.builder().productId(productId).categoryId(30).isPrimary(false).build()
        );
        when(productCategoryRepository.findByProductId(productId)).thenReturn(mappings);

        ProductResponse response = service.createProduct(request);

        assertNotNull(response);
        assertEquals(productId, response.id());
        assertEquals("ASUS ROG Strix G16", response.productName());
        assertEquals("asus-rog-strix-g16", response.slug());
        assertEquals(3, response.categories().size());
        assertTrue(response.categories().stream().anyMatch(c -> c.id().equals(10) && c.isPrimary()));
        assertTrue(response.categories().stream().anyMatch(c -> c.id().equals(20) && !c.isPrimary()));
        assertTrue(response.categories().stream().anyMatch(c -> c.id().equals(30) && !c.isPrimary()));
        assertEquals(1, response.variants().size());
        assertEquals(15, response.totalStock());
        assertEquals(new BigDecimal("42000000"), response.minPrice());

        verify(productCategoryRepository).deleteByProductId(productId);
        verify(productCategoryRepository).saveAll(anyList());
        verify(productVariantRepository).save(any(ProductVariant.class));
    }

    @Test
    void listProducts_FiltersCorrectly() {
        UUID p1Id = UUID.randomUUID();
        Product p1 = Product.builder().id(p1Id).productName("Mouse Logitech G502").slug("mouse-g502").isActive(true).build();

        when(productRepository.findFiltered(null, null, true)).thenReturn(List.of(p1));
        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productVariantRepository.findByProductId(p1Id)).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(p1Id)).thenReturn(List.of());

        List<ProductResponse> results = service.listProducts("logitech", null, null, true);

        assertEquals(1, results.size());
        assertEquals("Mouse Logitech G502", results.getFirst().productName());
    }

    @Test
    void updateProduct_RewiresCategories() {
        UUID productId = UUID.randomUUID();
        Product existing = Product.builder().id(productId).productName("Old Name").slug("old-slug").isActive(true).build();

        UpdateProductRequest req = new UpdateProductRequest(
                "New Name",
                "new-slug",
                null,
                List.of(5, 6),
                5,
                "New short desc",
                "New desc",
                null,
                12,
                null,
                true
        );

        Product updated = Product.builder().id(productId).productName("New Name").slug("new-slug").categoryId(5).isActive(true).build();

        when(productRepository.findById(productId)).thenReturn(Optional.of(existing), Optional.of(updated));
        when(productRepository.findBySlug("new-slug")).thenReturn(Optional.empty());
        when(productRepository.save(any(Product.class))).thenReturn(updated);
        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productVariantRepository.findByProductId(productId)).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(productId)).thenReturn(List.of());

        ProductResponse res = service.updateProduct(productId, req);

        assertNotNull(res);
        assertEquals("New Name", res.productName());
        verify(productCategoryRepository).deleteByProductId(productId);
        verify(productCategoryRepository).saveAll(anyList());
    }

    @Test
    void deleteProduct_RemovesAssociationAndProduct() {
        UUID productId = UUID.randomUUID();
        when(productRepository.existsById(productId)).thenReturn(true);

        service.deleteProduct(productId);

        verify(productCategoryRepository).deleteByProductId(productId);
        verify(productRepository).deleteById(productId);
    }

    @Test
    void createVariant_WithStructuredAttributes_Success() {
        UUID productId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        String attributes = "{\"RAM\": \"32GB\", \"GPU\": \"RTX 4070\", \"SSD\": \"1TB\"}";

        CreateVariantRequest req = new CreateVariantRequest(
                "SKU-ROG-32GB-4070",
                "32GB RAM / RTX 4070",
                attributes,
                new BigDecimal("55000000"),
                new BigDecimal("51000000"),
                8,
                5,
                new BigDecimal("2500"),
                true
        );

        ProductVariant saved = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .sku("SKU-ROG-32GB-4070")
                .variantName("32GB RAM / RTX 4070")
                .attributes(attributes)
                .listPrice(new BigDecimal("55000000"))
                .salePrice(new BigDecimal("51000000"))
                .quantityOnHand(8)
                .quantityReserved(1)
                .reorderLevel(5)
                .weightGram(new BigDecimal("2500"))
                .isActive(true)
                .build();

        when(productRepository.existsById(productId)).thenReturn(true);
        when(productVariantRepository.existsBySku("SKU-ROG-32GB-4070")).thenReturn(false);
        when(productVariantRepository.save(any(ProductVariant.class))).thenReturn(saved);

        ProductVariantSummary result = service.createVariant(productId, req);

        assertNotNull(result);
        assertEquals("SKU-ROG-32GB-4070", result.sku());
        assertEquals("32GB RAM / RTX 4070", result.variantName());
        assertEquals(attributes, result.attributes());
        assertEquals(8, result.quantityOnHand());
        assertEquals(1, result.quantityReserved());
        assertEquals(7, result.availableQuantity());
    }

    @Test
    void updateVariant_Success() {
        UUID productId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();
        String oldAttrs = "{\"RAM\": \"16GB\"}";
        String newAttrs = "{\"RAM\": \"16GB\", \"Color\": \"White\"}";

        ProductVariant existing = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .sku("SKU-ROG-OLD")
                .variantName("Old Variant")
                .attributes(oldAttrs)
                .listPrice(new BigDecimal("40000000"))
                .salePrice(new BigDecimal("38000000"))
                .quantityOnHand(5)
                .quantityReserved(0)
                .isActive(true)
                .build();

        UpdateVariantRequest req = new UpdateVariantRequest(
                "SKU-ROG-UPDATED",
                "Updated Variant",
                newAttrs,
                new BigDecimal("42000000"),
                new BigDecimal("39000000"),
                10,
                5,
                new BigDecimal("2300"),
                true
        );

        when(productVariantRepository.findById(variantId)).thenReturn(Optional.of(existing));
        when(productVariantRepository.existsBySku("SKU-ROG-UPDATED")).thenReturn(false);
        when(productVariantRepository.save(any(ProductVariant.class))).thenAnswer(i -> i.getArgument(0));

        ProductVariantSummary result = service.updateVariant(productId, variantId, req);

        assertNotNull(result);
        assertEquals("SKU-ROG-UPDATED", result.sku());
        assertEquals("Updated Variant", result.variantName());
        assertEquals(newAttrs, result.attributes());
        assertEquals(10, result.quantityOnHand());
    }

    @Test
    void deleteVariant_Success() {
        UUID productId = UUID.randomUUID();
        UUID variantId = UUID.randomUUID();

        ProductVariant variant = ProductVariant.builder()
                .id(variantId)
                .productId(productId)
                .build();

        when(productVariantRepository.findById(variantId)).thenReturn(Optional.of(variant));

        service.deleteVariant(productId, variantId);

        verify(productVariantRepository).deleteById(variantId);
    }
}
