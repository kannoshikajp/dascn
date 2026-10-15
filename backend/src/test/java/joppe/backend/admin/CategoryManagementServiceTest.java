package joppe.backend.admin;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;
import joppe.backend.admin.dto.CategoryNodeResponse;
import joppe.backend.admin.dto.CategoryResponse;
import joppe.backend.admin.dto.CreateCategoryRequest;
import joppe.backend.admin.dto.UpdateCategoryRequest;
import joppe.backend.admin.service.CategoryManagementService;
import joppe.backend.domain.catalog.Category;
import joppe.backend.domain.catalog.CategoryRepository;
import joppe.backend.domain.catalog.ProductRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CategoryManagementServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private ProductRepository productRepository;

    private CategoryManagementService service;

    @BeforeEach
    void setUp() {
        service = new CategoryManagementService(categoryRepository, productRepository);
    }

    @Test
    void createCategory_Success() {
        CreateCategoryRequest request = new CreateCategoryRequest(null, "Laptop Gaming", null, null, true);
        Category saved = Category.builder().id(1).categoryName("Laptop Gaming").slug("laptop-gaming").isActive(true).build();

        when(categoryRepository.existsBySlug("laptop-gaming")).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenReturn(saved);
        when(categoryRepository.findById(1)).thenReturn(Optional.of(saved));
        when(productRepository.countByCategoryId(1)).thenReturn(0L);
        when(categoryRepository.countByParentId(1)).thenReturn(0L);

        CategoryResponse result = service.createCategory(request);

        assertNotNull(result);
        assertEquals(1, result.id());
        assertEquals("laptop-gaming", result.slug());
    }

    @Test
    void createCategory_DuplicateSlug_ThrowsException() {
        CreateCategoryRequest request = new CreateCategoryRequest(null, "Laptop", "laptop", null, true);
        when(categoryRepository.existsBySlug("laptop")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> service.createCategory(request));
    }

    @Test
    void updateCategory_CycleDetection_ThrowsException() {
        // Tree: 1 (Laptop) -> 2 (Asus) -> 3 (Gaming)
        // Trying to set 1's parent to 3 must throw cycle exception
        Category laptop = Category.builder().id(1).categoryName("Laptop").slug("laptop").build();
        Category asus = Category.builder().id(2).parentId(1).categoryName("Asus").slug("asus").build();
        Category gaming = Category.builder().id(3).parentId(2).categoryName("Gaming").slug("gaming").build();

        when(categoryRepository.findById(1)).thenReturn(Optional.of(laptop));
        when(categoryRepository.existsById(3)).thenReturn(true);
        when(categoryRepository.findById(3)).thenReturn(Optional.of(gaming));
        when(categoryRepository.findById(2)).thenReturn(Optional.of(asus));

        UpdateCategoryRequest request = new UpdateCategoryRequest(3, "Laptop", "laptop", null, true);

        assertThrows(IllegalArgumentException.class, () -> service.updateCategory(1, request));
    }

    @Test
    void deleteCategory_WithChildren_ThrowsException() {
        Category cat = Category.builder().id(1).build();
        when(categoryRepository.findById(1)).thenReturn(Optional.of(cat));
        when(categoryRepository.countByParentId(1)).thenReturn(2L);

        assertThrows(IllegalStateException.class, () -> service.deleteCategory(1));
    }

    @Test
    void deleteCategory_WithProducts_ThrowsException() {
        Category cat = Category.builder().id(1).build();
        when(categoryRepository.findById(1)).thenReturn(Optional.of(cat));
        when(categoryRepository.countByParentId(1)).thenReturn(0L);
        when(productRepository.countByCategoryId(1)).thenReturn(5L);

        assertThrows(IllegalStateException.class, () -> service.deleteCategory(1));
    }

    @Test
    void deleteCategory_Success() {
        Category cat = Category.builder().id(1).build();
        when(categoryRepository.findById(1)).thenReturn(Optional.of(cat));
        when(categoryRepository.countByParentId(1)).thenReturn(0L);
        when(productRepository.countByCategoryId(1)).thenReturn(0L);

        service.deleteCategory(1);

        verify(categoryRepository).delete(cat);
    }

    @Test
    void listCategoryTree_BuildsHierarchy() {
        Category laptop = Category.builder().id(1).parentId(null).categoryName("Laptop").slug("laptop").isActive(true).build();
        Category asus = Category.builder().id(2).parentId(1).categoryName("Asus").slug("asus").isActive(true).build();
        Category gaming = Category.builder().id(3).parentId(2).categoryName("Gaming").slug("gaming").isActive(true).build();

        when(categoryRepository.findByIsActiveTrue()).thenReturn(List.of(laptop, asus, gaming));
        when(productRepository.countByCategoryId(any())).thenReturn(0L);

        List<CategoryNodeResponse> tree = service.listCategoryTree(true);

        assertEquals(1, tree.size());
        CategoryNodeResponse root = tree.get(0);
        assertEquals("Laptop", root.categoryName());
        assertEquals(1, root.children().size());
        assertEquals("Asus", root.children().get(0).categoryName());
        assertEquals(1, root.children().get(0).children().size());
        assertEquals("Gaming", root.children().get(0).children().get(0).categoryName());
    }
}
