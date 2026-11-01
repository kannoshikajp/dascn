package joppe.backend.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
import joppe.backend.domain.catalog.VariantMediaRepository;
import joppe.backend.media.domain.UploadedMediaRepository;
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

    @Mock
    private VariantMediaRepository variantMediaRepository;

    @Mock
    private UploadedMediaRepository uploadedMediaRepository;

    private AdminProductService service;

    @BeforeEach
    void setUp() {
        service = new AdminProductService(
                productRepository,
                productCategoryRepository,
                categoryRepository,
                brandRepository,
                productVariantRepository,
                variantMediaRepository,
                uploadedMediaRepository
        );
    }

    @Test
    void createProduct_WithSkuAndAutoSlug_Success() {
        UUID productId = UUID.randomUUID();
        // slug is empty -> should auto slug from SKU: "ROG STRIX 16G" -> "rog-strix-16g"
        CreateProductRequest request = new CreateProductRequest(
                "ASUS ROG Strix G16",
                "ROG STRIX 16G",
                null, // parentSku
                null, // slug empty, should auto derive
                1,
                List.of(10, 20),
                10,
                true,
                "https://cdn.joppe.vn/g16.png",
                "Full description here",
                null,
                new BigDecimal("45000000"),
                new BigDecimal("42000000"),
                15
        );

        Product saved = Product.builder()
                .id(productId)
                .productName("ASUS ROG Strix G16")
                .sku("ROG STRIX 16G")
                .slug("rog-strix-16g")
                .brandId(1)
                .categoryId(10)
                .isActive(true)
                .build();

        Category c1 = Category.builder().id(10).categoryName("Laptops").slug("laptops").build();
        Brand brand = Brand.builder().id(1).brandName("ASUS").slug("asus").build();

        ProductVariant variant = ProductVariant.builder()
                .id(UUID.randomUUID())
                .productId(productId)
                .sku("ROG STRIX 16G")
                .variantName("ASUS ROG Strix G16")
                .listPrice(new BigDecimal("45000000"))
                .salePrice(new BigDecimal("42000000"))
                .quantityOnHand(15)
                .quantityReserved(0)
                .isActive(true)
                .build();

        when(brandRepository.existsById(1)).thenReturn(true);
        when(productRepository.existsBySku("ROG STRIX 16G")).thenReturn(false);
        when(productRepository.findBySlug("rog-strix-16g")).thenReturn(Optional.empty());
        when(productRepository.save(any(Product.class))).thenReturn(saved);
        when(productRepository.findById(productId)).thenReturn(Optional.of(saved));
        when(productVariantRepository.findByProductId(productId)).thenReturn(List.of(variant));
        when(categoryRepository.findAll()).thenReturn(List.of(c1));
        when(brandRepository.findAll()).thenReturn(List.of(brand));

        List<ProductCategory> mappings = List.of(
                ProductCategory.builder().productId(productId).categoryId(10).isPrimary(true).build()
        );
        when(productCategoryRepository.findByProductId(productId)).thenReturn(mappings);

        ProductResponse response = service.createProduct(request);

        assertNotNull(response);
        assertEquals(productId, response.id());
        assertEquals("ASUS ROG Strix G16", response.productName());
        assertEquals("ROG STRIX 16G", response.sku());
        assertEquals("rog-strix-16g", response.slug());
        assertEquals(15, response.totalStock());
        assertEquals(new BigDecimal("42000000"), response.minPrice());

        verify(productVariantRepository).save(any(ProductVariant.class));
    }

    @Test
    void getProduct_queryChildC_returnsFatherA_andSiblingsB_D_E() {
        // Setup: Father A, Children B, C, D, E (with parentSku = A.sku)
        UUID pCId = UUID.randomUUID();
        UUID pAId = UUID.randomUUID();
        UUID pBId = UUID.randomUUID();
        UUID pDId = UUID.randomUUID();
        UUID pEId = UUID.randomUUID();

        Product prodA = Product.builder().id(pAId).productName("Laptop Pro A").sku("SKU-A").slug("laptop-a").build();
        Product prodB = Product.builder().id(pBId).productName("Laptop Pro B").sku("SKU-B").parentSku("SKU-A").slug("laptop-b").build();
        Product prodC = Product.builder().id(pCId).productName("Laptop Pro C").sku("SKU-C").parentSku("SKU-A").slug("laptop-c").build();
        Product prodD = Product.builder().id(pDId).productName("Laptop Pro D").sku("SKU-D").parentSku("SKU-A").slug("laptop-d").build();
        Product prodE = Product.builder().id(pEId).productName("Laptop Pro E").sku("SKU-E").parentSku("SKU-A").slug("laptop-e").build();

        when(productRepository.findById(pCId)).thenReturn(Optional.of(prodC));
        when(productRepository.findBySku("SKU-A")).thenReturn(Optional.of(prodA));
        when(productRepository.findByParentSku("SKU-A")).thenReturn(List.of(prodB, prodC, prodD, prodE));

        // Mock variant for each product
        when(productVariantRepository.findByProductId(pCId)).thenReturn(List.of(
                ProductVariant.builder().productId(pCId).sku("SKU-C").variantName("Model C").salePrice(BigDecimal.valueOf(100)).build()
        ));
        when(productVariantRepository.findByProductId(pAId)).thenReturn(List.of(
                ProductVariant.builder().productId(pAId).sku("SKU-A").variantName("Model A").salePrice(BigDecimal.valueOf(100)).build()
        ));
        when(productVariantRepository.findByProductId(pBId)).thenReturn(List.of(
                ProductVariant.builder().productId(pBId).sku("SKU-B").variantName("Model B").salePrice(BigDecimal.valueOf(110)).build()
        ));
        when(productVariantRepository.findByProductId(pDId)).thenReturn(List.of(
                ProductVariant.builder().productId(pDId).sku("SKU-D").variantName("Model D").salePrice(BigDecimal.valueOf(120)).build()
        ));
        when(productVariantRepository.findByProductId(pEId)).thenReturn(List.of(
                ProductVariant.builder().productId(pEId).sku("SKU-E").variantName("Model E").salePrice(BigDecimal.valueOf(130)).build()
        ));

        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(pCId)).thenReturn(List.of());

        ProductResponse response = service.getProductById(pCId);

        assertNotNull(response);
        assertEquals("SKU-C", response.sku());
        assertEquals("SKU-A", response.parentSku());

        // Check variant list: must contain A, B, D, E (total 4, excluding C itself!)
        List<String> variantSkus = response.variants().stream().map(ProductVariantSummary::sku).toList();
        assertEquals(4, variantSkus.size());
        assertTrue(variantSkus.contains("SKU-A"), "Must contain Father A");
        assertTrue(variantSkus.contains("SKU-B"), "Must contain Sibling B");
        assertTrue(variantSkus.contains("SKU-D"), "Must contain Sibling D");
        assertTrue(variantSkus.contains("SKU-E"), "Must contain Sibling E");
        assertTrue(!variantSkus.contains("SKU-C"), "Must NOT contain queried product C");
    }

    @Test
    void getProduct_nestedHierarchy_queryB_returns_A_C_D_E() {
        // Hierarchy: A is root parent -> has children B and C
        // C also has children -> D and E
        // Querying B must return complete family: A, C, D, E (excluding B)
        UUID pAId = UUID.randomUUID();
        UUID pBId = UUID.randomUUID();
        UUID pCId = UUID.randomUUID();
        UUID pDId = UUID.randomUUID();
        UUID pEId = UUID.randomUUID();

        Product prodA = Product.builder().id(pAId).productName("Product A").sku("SKU-A").slug("prod-a").build();
        Product prodB = Product.builder().id(pBId).productName("Product B").sku("SKU-B").parentSku("SKU-A").slug("prod-b").build();
        Product prodC = Product.builder().id(pCId).productName("Product C").sku("SKU-C").parentSku("SKU-A").slug("prod-c").build();
        Product prodD = Product.builder().id(pDId).productName("Product D").sku("SKU-D").parentSku("SKU-C").slug("prod-d").build();
        Product prodE = Product.builder().id(pEId).productName("Product E").sku("SKU-E").parentSku("SKU-C").slug("prod-e").build();

        when(productRepository.findById(pBId)).thenReturn(Optional.of(prodB));
        when(productRepository.findBySku("SKU-A")).thenReturn(Optional.of(prodA));
        // A has children B and C
        when(productRepository.findByParentSku("SKU-A")).thenReturn(List.of(prodB, prodC));
        // B has no children
        when(productRepository.findByParentSku("SKU-B")).thenReturn(List.of());
        // C has children D and E
        when(productRepository.findByParentSku("SKU-C")).thenReturn(List.of(prodD, prodE));
        // D and E have no children
        when(productRepository.findByParentSku("SKU-D")).thenReturn(List.of());
        when(productRepository.findByParentSku("SKU-E")).thenReturn(List.of());

        // Mock variant for each product
        when(productVariantRepository.findByProductId(pBId)).thenReturn(List.of(ProductVariant.builder().productId(pBId).sku("SKU-B").variantName("B").build()));
        when(productVariantRepository.findByProductId(pAId)).thenReturn(List.of(ProductVariant.builder().productId(pAId).sku("SKU-A").variantName("A").build()));
        when(productVariantRepository.findByProductId(pCId)).thenReturn(List.of(ProductVariant.builder().productId(pCId).sku("SKU-C").variantName("C").build()));
        when(productVariantRepository.findByProductId(pDId)).thenReturn(List.of(ProductVariant.builder().productId(pDId).sku("SKU-D").variantName("D").build()));
        when(productVariantRepository.findByProductId(pEId)).thenReturn(List.of(ProductVariant.builder().productId(pEId).sku("SKU-E").variantName("E").build()));

        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(pBId)).thenReturn(List.of());

        ProductResponse response = service.getProductById(pBId);

        assertNotNull(response);
        assertEquals("SKU-B", response.sku());

        List<String> variantSkus = response.variants().stream().map(ProductVariantSummary::sku).toList();
        assertEquals(4, variantSkus.size());
        assertTrue(variantSkus.contains("SKU-A"), "Must contain Root A");
        assertTrue(variantSkus.contains("SKU-C"), "Must contain Sibling C");
        assertTrue(variantSkus.contains("SKU-D"), "Must contain Child of C: D");
        assertTrue(variantSkus.contains("SKU-E"), "Must contain Child of C: E");
        assertTrue(!variantSkus.contains("SKU-B"), "Must NOT contain queried B");
    }

    @Test
    void listProducts_FiltersBySkuAndParentSku() {
        UUID p1Id = UUID.randomUUID();
        Product p1 = Product.builder()
                .id(p1Id)
                .productName("Mouse Logitech G502")
                .sku("LOGI-G502-HERO")
                .slug("mouse-g502")
                .isActive(true)
                .build();

        when(productRepository.findFiltered(null, null, true)).thenReturn(List.of(p1));
        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productVariantRepository.findByProductId(p1Id)).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(p1Id)).thenReturn(List.of());

        List<ProductResponse> results = service.listProducts("g502-hero", null, null, true);

        assertEquals(1, results.size());
        assertEquals("Mouse Logitech G502", results.getFirst().productName());
        assertEquals("LOGI-G502-HERO", results.getFirst().sku());
    }

    @Test
    void updateProduct_UpdatesSkuAndParentSku() {
        UUID productId = UUID.randomUUID();
        Product existing = Product.builder().id(productId).productName("Old Name").sku("OLD-SKU").slug("old-slug").isActive(true).build();

        UpdateProductRequest req = new UpdateProductRequest(
                "New Name",
                "NEW-SKU",
                "FATHER-SKU",
                "new-slug",
                null,
                List.of(5),
                5,
                true
        );

        Product updated = Product.builder()
                .id(productId)
                .productName("New Name")
                .sku("NEW-SKU")
                .parentSku("FATHER-SKU")
                .slug("new-slug")
                .categoryId(5)
                .isActive(true)
                .build();

        ProductVariant v = ProductVariant.builder().id(UUID.randomUUID()).productId(productId).sku("OLD-SKU").build();

        when(productRepository.findById(productId)).thenReturn(Optional.of(existing), Optional.of(updated));
        when(productRepository.existsBySku("NEW-SKU")).thenReturn(false);
        when(productRepository.existsBySku("FATHER-SKU")).thenReturn(true);
        when(productRepository.save(any(Product.class))).thenReturn(updated);
        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productVariantRepository.findByProductId(productId)).thenReturn(List.of(v));
        when(productCategoryRepository.findByProductId(productId)).thenReturn(List.of());

        ProductResponse res = service.updateProduct(productId, req);

        assertNotNull(res);
        assertEquals("New Name", res.productName());
        assertEquals("NEW-SKU", res.sku());
        assertEquals("FATHER-SKU", res.parentSku());
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
    void exportProductsCsv_Success() {
        UUID productId = UUID.randomUUID();
        Product p = Product.builder()
                .id(productId)
                .productName("ASUS ROG Strix G16")
                .sku("SKU-ROG-G16-01")
                .slug("asus-rog-strix-g16")
                .isActive(true)
                .build();

        when(productRepository.findFiltered(null, null, null)).thenReturn(List.of(p));
        when(categoryRepository.findAll()).thenReturn(List.of());
        when(brandRepository.findAll()).thenReturn(List.of());
        when(productVariantRepository.findByProductId(productId)).thenReturn(List.of());
        when(productCategoryRepository.findByProductId(productId)).thenReturn(List.of());

        byte[] csvBytes = service.exportProductsCsv(null, null, null, null);

        assertNotNull(csvBytes);
        String csv = new String(csvBytes, java.nio.charset.StandardCharsets.UTF_8);
        assertTrue(csv.startsWith("﻿ID,Product Name,SKU,Parent SKU,Slug,Brand,Active,Categories,Min Price,Max Price,Total Stock,Created At"));
        assertTrue(csv.contains("ASUS ROG Strix G16"));
        assertTrue(csv.contains("SKU-ROG-G16-01"));
        assertTrue(csv.contains("Active"));
    }
}
