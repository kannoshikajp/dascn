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
import joppe.backend.admin.dto.ProductResponse;
import joppe.backend.admin.dto.UpdateProductRequest;
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
}
