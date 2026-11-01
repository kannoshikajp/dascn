package joppe.backend.admin.service;

import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;
import joppe.backend.admin.dto.CategoryNodeResponse;
import joppe.backend.admin.dto.CategoryResponse;
import joppe.backend.admin.dto.CreateCategoryRequest;
import joppe.backend.admin.dto.UpdateCategoryRequest;
import joppe.backend.common.util.CsvHelper;
import joppe.backend.domain.catalog.Category;
import joppe.backend.domain.catalog.CategoryRepository;
import joppe.backend.domain.catalog.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CategoryManagementService {

    private static final Pattern NON_LATIN = Pattern.compile("[^\\w-]");
    private static final Pattern WHITESPACE = Pattern.compile("[\\s]");

    private final CategoryRepository categoryRepository;
    private final ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<CategoryResponse> listCategoriesFlat(String search, Boolean isActive) {
        List<Category> all = categoryRepository.findAllByOrderByCategoryNameAsc();
        Map<Integer, String> nameMap = new HashMap<>();
        Map<Integer, Long> childCountMap = new HashMap<>();

        for (Category c : all) {
            nameMap.put(c.getId(), c.getCategoryName());
            if (c.getParentId() != null) {
                childCountMap.put(c.getParentId(), childCountMap.getOrDefault(c.getParentId(), 0L) + 1);
            }
        }

        String searchLower = (search != null && !search.isBlank()) ? search.trim().toLowerCase(Locale.ROOT) : null;

        return all.stream()
                .filter(c -> {
                    if (isActive != null && !isActive.equals(c.getIsActive())) {
                        return false;
                    }
                    if (searchLower != null) {
                        return c.getCategoryName().toLowerCase(Locale.ROOT).contains(searchLower)
                                || c.getSlug().toLowerCase(Locale.ROOT).contains(searchLower);
                    }
                    return true;
                })
                .map(c -> {
                    String parentName = c.getParentId() != null ? nameMap.get(c.getParentId()) : null;
                    long productCount = productRepository.countByCategoryId(c.getId());
                    long childCount = childCountMap.getOrDefault(c.getId(), 0L);

                    return new CategoryResponse(
                            c.getId(),
                            c.getParentId(),
                            parentName,
                            c.getCategoryName(),
                            c.getSlug(),
                            c.getIconUrl(),
                            c.getIsActive(),
                            c.getCreatedAt(),
                            productCount,
                            childCount
                    );
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public byte[] exportCategoriesCsv(String search, Boolean isActive) {
        List<CategoryResponse> categories = listCategoriesFlat(search, isActive);
        StringBuilder sb = new StringBuilder();
        sb.append('﻿'); // UTF-8 BOM
        sb.append("ID,Category Name,Slug,Parent ID,Parent Name,Active,Product Count,Child Count,Created At\r\n");

        for (CategoryResponse c : categories) {
            sb.append(c.id()).append(",")
              .append(CsvHelper.escape(c.categoryName())).append(",")
              .append(CsvHelper.escape(c.slug())).append(",")
              .append(c.parentId() != null ? c.parentId() : "").append(",")
              .append(CsvHelper.escape(c.parentName())).append(",")
              .append(c.isActive() != null && c.isActive() ? "Active" : "Inactive").append(",")
              .append(c.productCount()).append(",")
              .append(c.childCount()).append(",")
              .append(CsvHelper.escape(c.createdAt())).append("\r\n");
        }

        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Transactional(readOnly = true)
    public List<CategoryNodeResponse> listCategoryTree(Boolean isActive) {
        List<Category> categories = (isActive != null && isActive)
                ? categoryRepository.findByIsActiveTrue()
                : categoryRepository.findAllByOrderByCategoryNameAsc();

        Map<Integer, List<Category>> childrenMap = new HashMap<>();
        List<Category> rootCategories = new ArrayList<>();
        Set<Integer> allIds = new HashSet<>();

        for (Category c : categories) {
            allIds.add(c.getId());
        }

        for (Category c : categories) {
            if (c.getParentId() == null || !allIds.contains(c.getParentId())) {
                rootCategories.add(c);
            } else {
                childrenMap.computeIfAbsent(c.getParentId(), k -> new ArrayList<>()).add(c);
            }
        }

        return rootCategories.stream()
                .map(root -> buildNode(root, childrenMap))
                .toList();
    }

    private CategoryNodeResponse buildNode(Category current, Map<Integer, List<Category>> childrenMap) {
        List<Category> children = childrenMap.getOrDefault(current.getId(), Collections.emptyList());
        List<CategoryNodeResponse> childNodes = children.stream()
                .map(ch -> buildNode(ch, childrenMap))
                .toList();

        long productCount = productRepository.countByCategoryId(current.getId());

        return new CategoryNodeResponse(
                current.getId(),
                current.getParentId(),
                current.getCategoryName(),
                current.getSlug(),
                current.getIconUrl(),
                current.getIsActive(),
                productCount,
                childNodes
        );
    }

    @Transactional(readOnly = true)
    public CategoryResponse getCategory(Integer id) {
        Category c = categoryRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Category not found with ID: " + id));

        String parentName = null;
        if (c.getParentId() != null) {
            parentName = categoryRepository.findById(c.getParentId())
                    .map(Category::getCategoryName)
                    .orElse(null);
        }

        long productCount = productRepository.countByCategoryId(c.getId());
        long childCount = categoryRepository.countByParentId(c.getId());

        return new CategoryResponse(
                c.getId(),
                c.getParentId(),
                parentName,
                c.getCategoryName(),
                c.getSlug(),
                c.getIconUrl(),
                c.getIsActive(),
                c.getCreatedAt(),
                productCount,
                childCount
        );
    }

    @Transactional
    public CategoryResponse createCategory(CreateCategoryRequest request) {
        String slug = (request.slug() != null && !request.slug().isBlank())
                ? slugify(request.slug())
                : slugify(request.categoryName());

        if (categoryRepository.existsBySlug(slug)) {
            throw new IllegalArgumentException("Category slug already exists: " + slug);
        }

        if (request.parentId() != null && !categoryRepository.existsById(request.parentId())) {
            throw new IllegalArgumentException("Parent category does not exist with ID: " + request.parentId());
        }

        Category category = Category.builder()
                .parentId(request.parentId())
                .categoryName(request.categoryName().trim())
                .slug(slug)
                .iconUrl(request.iconUrl())
                .isActive(request.isActive() != null ? request.isActive() : true)
                .build();

        Category saved = categoryRepository.save(category);
        return getCategory(saved.getId());
    }

    @Transactional
    public CategoryResponse updateCategory(Integer id, UpdateCategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Category not found with ID: " + id));

        Integer newParentId = request.parentId();
        if (newParentId != null) {
            if (newParentId.equals(id)) {
                throw new IllegalArgumentException("Category cannot be its own parent");
            }
            if (!categoryRepository.existsById(newParentId)) {
                throw new IllegalArgumentException("Parent category does not exist with ID: " + newParentId);
            }
            if (isDescendantOf(newParentId, id)) {
                throw new IllegalArgumentException("Cannot assign parent to a subcategory (cycle detected)");
            }
        }

        String newSlug = (request.slug() != null && !request.slug().isBlank())
                ? slugify(request.slug())
                : slugify(request.categoryName());

        if (!newSlug.equals(category.getSlug()) && categoryRepository.existsBySlug(newSlug)) {
            throw new IllegalArgumentException("Category slug already exists: " + newSlug);
        }

        category.setParentId(newParentId);
        category.setCategoryName(request.categoryName().trim());
        category.setSlug(newSlug);
        category.setIconUrl(request.iconUrl());
        if (request.isActive() != null) {
            category.setIsActive(request.isActive());
        }

        Category saved = categoryRepository.save(category);
        return getCategory(saved.getId());
    }

    @Transactional
    public void updateStatus(Integer id, boolean isActive) {
        if (!categoryRepository.existsById(id)) {
            throw new IllegalArgumentException("Category not found with ID: " + id);
        }
        categoryRepository.updateActiveStatus(id, isActive);
    }

    @Transactional
    public void deleteCategory(Integer id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Category not found with ID: " + id));

        long childCount = categoryRepository.countByParentId(id);
        if (childCount > 0) {
            throw new IllegalStateException("Cannot delete category with " + childCount + " subcategories. Please reassign or delete subcategories first.");
        }

        long productCount = productRepository.countByCategoryId(id);
        if (productCount > 0) {
            throw new IllegalStateException("Cannot delete category with " + productCount + " linked products. Please reassign products first.");
        }

        categoryRepository.delete(category);
    }

    private boolean isDescendantOf(Integer candidateDescendantId, Integer potentialAncestorId) {
        Integer current = candidateDescendantId;
        Set<Integer> visited = new HashSet<>();

        while (current != null) {
            if (current.equals(potentialAncestorId)) {
                return true;
            }
            if (!visited.add(current)) {
                break;
            }
            current = categoryRepository.findById(current).map(Category::getParentId).orElse(null);
        }
        return false;
    }

    private String slugify(String input) {
        if (input == null) return "";
        String nowhitespace = WHITESPACE.matcher(input.trim()).replaceAll("-");
        String normalized = Normalizer.normalize(nowhitespace, Normalizer.Form.NFD);
        String slug = NON_LATIN.matcher(normalized).replaceAll("");
        return slug.toLowerCase(Locale.ENGLISH).replaceAll("-{2,}", "-");
    }
}
