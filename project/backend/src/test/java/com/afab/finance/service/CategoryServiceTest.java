package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.domain.Category;
import com.afab.finance.dto.CategoryDTO;
import com.afab.finance.dto.CreateCategoryRequest;
import com.afab.finance.dto.UpdateCategoryRequest;
import com.afab.finance.repository.CategoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CurrentBusinessService currentBusinessService;

    @InjectMocks
    private CategoryService categoryService;

    private Business testBusiness;
    private UUID businessId;
    private final String userEmail = "owner@afab.test";

    @BeforeEach
    void setUp() {
        businessId = UUID.randomUUID();
        testBusiness = new Business();
        testBusiness.setId(businessId);
        testBusiness.setName("Acme Corp");
    }

    @Test
    @DisplayName("getCategories: returns default categories and business custom categories")
    void testGetCategories() {
        Category systemCat = new Category();
        systemCat.setId(UUID.randomUUID());
        systemCat.setName("Sales");
        systemCat.setType("INCOME");
        systemCat.setBusiness(null); // system default

        Category customCat = new Category();
        customCat.setId(UUID.randomUUID());
        customCat.setName("Cloud Hosting");
        customCat.setType("EXPENSE");
        customCat.setBusiness(testBusiness); // custom

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findAllForBusiness(businessId))
                .thenReturn(List.of(systemCat, customCat));

        List<CategoryDTO> results = categoryService.getCategories(userEmail);

        assertThat(results).hasSize(2);
        assertThat(results.get(0).getName()).isEqualTo("Sales");
        assertThat(results.get(0).isSystemDefault()).isTrue();
        assertThat(results.get(1).getName()).isEqualTo("Cloud Hosting");
        assertThat(results.get(1).isSystemDefault()).isFalse();
    }

    @Test
    @DisplayName("createCategory: succeeds when no duplicate exists")
    void testCreateCategorySuccess() {
        CreateCategoryRequest request = new CreateCategoryRequest();
        request.setName("Office Supplies");
        request.setType("EXPENSE");
        request.setColor("#10b981");
        request.setIcon("Folder");

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.existsByBusinessAndNameIgnoreCaseAndType(businessId, "Office Supplies", "EXPENSE"))
                .thenReturn(false);

        Category savedCategory = new Category();
        savedCategory.setId(UUID.randomUUID());
        savedCategory.setName(request.getName());
        savedCategory.setType(request.getType());
        savedCategory.setColor(request.getColor());
        savedCategory.setIcon(request.getIcon());
        savedCategory.setBusiness(testBusiness);

        when(categoryRepository.save(any(Category.class))).thenReturn(savedCategory);

        CategoryDTO created = categoryService.createCategory(userEmail, request);

        assertThat(created).isNotNull();
        assertThat(created.getName()).isEqualTo("Office Supplies");
        assertThat(created.getType()).isEqualTo("EXPENSE");
        assertThat(created.isSystemDefault()).isFalse();
        verify(categoryRepository, times(1)).save(any(Category.class));
    }

    @Test
    @DisplayName("createCategory: throws ConflictException when duplicate name exists for business")
    void testCreateCategoryDuplicateConflict() {
        CreateCategoryRequest request = new CreateCategoryRequest();
        request.setName("Office Supplies");
        request.setType("EXPENSE");

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.existsByBusinessAndNameIgnoreCaseAndType(businessId, "Office Supplies", "EXPENSE"))
                .thenReturn(true);

        assertThatThrownBy(() -> categoryService.createCategory(userEmail, request))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already exists");

        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    @DisplayName("updateCategory: throws ForbiddenException when attempting to edit a system default category")
    void testUpdateCategorySystemDefaultForbidden() {
        UUID catId = UUID.randomUUID();
        Category systemCat = new Category();
        systemCat.setId(catId);
        systemCat.setName("Salary");
        systemCat.setType("INCOME");
        systemCat.setBusiness(null); // system default

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(systemCat));

        UpdateCategoryRequest request = new UpdateCategoryRequest();
        request.setName("New Salary");

        assertThatThrownBy(() -> categoryService.updateCategory(userEmail, catId, request))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("System default categories cannot be modified");
    }

    @Test
    @DisplayName("deleteCategory: throws ConflictException if active transactions are linked (Rule D5)")
    void testDeleteCategoryReferencedByTransactionsConflict() {
        UUID catId = UUID.randomUUID();
        Category customCat = new Category();
        customCat.setId(catId);
        customCat.setName("Subscriptions");
        customCat.setType("EXPENSE");
        customCat.setBusiness(testBusiness);

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(customCat));
        when(categoryRepository.countActiveTransactionsByCategoryId(catId)).thenReturn(3L);

        assertThatThrownBy(() -> categoryService.deleteCategory(userEmail, catId))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Cannot delete category because it is used by 3 transaction(s)");

        verify(categoryRepository, never()).delete(any());
    }

    @Test
    @DisplayName("deleteCategory: succeeds when category has 0 active transactions")
    void testDeleteCategorySuccess() {
        UUID catId = UUID.randomUUID();
        Category customCat = new Category();
        customCat.setId(catId);
        customCat.setName("Obsolete Project");
        customCat.setType("EXPENSE");
        customCat.setBusiness(testBusiness);

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(customCat));
        when(categoryRepository.countActiveTransactionsByCategoryId(catId)).thenReturn(0L);

        categoryService.deleteCategory(userEmail, catId);

        verify(categoryRepository, times(1)).delete(customCat);
    }
}
