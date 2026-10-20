package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Category;
import com.afab.finance.dto.CategoryDTO;
import com.afab.finance.dto.CreateCategoryRequest;
import com.afab.finance.dto.UpdateCategoryRequest;
import com.afab.finance.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final CurrentBusinessService currentBusinessService;

    public CategoryService(CategoryRepository categoryRepository, CurrentBusinessService currentBusinessService) {
        this.categoryRepository = categoryRepository;
        this.currentBusinessService = currentBusinessService;
    }

    @Transactional(readOnly = true)
    public List<CategoryDTO> getCategories(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return categoryRepository.findAllForBusiness(business.getId()).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    @Transactional
    public CategoryDTO createCategory(String userEmail, CreateCategoryRequest request) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String trimmedName = request.getName().trim();
        String upperType = request.getType().toUpperCase().trim();

        if (categoryRepository.existsByBusinessAndNameIgnoreCaseAndType(business.getId(), trimmedName, upperType)) {
            throw new ConflictException("A category with name '" + trimmedName + "' and type '" + upperType + "' already exists.");
        }

        Category category = new Category();
        category.setBusiness(business);
        category.setName(trimmedName);
        category.setType(upperType);
        category.setIcon(request.getIcon() != null && !request.getIcon().isBlank() ? request.getIcon().trim() : "Tag");
        category.setColor(request.getColor() != null && !request.getColor().isBlank() ? request.getColor().trim() : "#8b5cf6");

        category = categoryRepository.save(category);
        return mapToDTO(category);
    }

    @Transactional
    public CategoryDTO updateCategory(String userEmail, UUID id, UpdateCategoryRequest request) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with ID: " + id));

        if (category.getBusiness() == null) {
            throw new ForbiddenException("System default categories cannot be modified.");
        }

        if (!category.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not own this category.");
        }

        if (request.getName() != null && !request.getName().isBlank()) {
            String trimmedName = request.getName().trim();
            if (!category.getName().equalsIgnoreCase(trimmedName) &&
                    categoryRepository.existsByBusinessAndNameIgnoreCaseAndType(business.getId(), trimmedName, category.getType())) {
                throw new ConflictException("A category with name '" + trimmedName + "' already exists for type " + category.getType());
            }
            category.setName(trimmedName);
        }

        if (request.getIcon() != null && !request.getIcon().isBlank()) {
            category.setIcon(request.getIcon().trim());
        }

        if (request.getColor() != null && !request.getColor().isBlank()) {
            category.setColor(request.getColor().trim());
        }

        category = categoryRepository.save(category);
        return mapToDTO(category);
    }

    @Transactional
    public void deleteCategory(String userEmail, UUID id) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with ID: " + id));

        if (category.getBusiness() == null) {
            throw new ForbiddenException("System default categories cannot be deleted.");
        }

        if (!category.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not own this category.");
        }

        long usageCount = categoryRepository.countActiveTransactionsByCategoryId(id);
        if (usageCount > 0) {
            throw new ConflictException("Cannot delete category '" + category.getName() + "' because it is currently used by " + usageCount + " transaction(s).");
        }

        categoryRepository.delete(category);
    }

    public CategoryDTO mapToDTO(Category c) {
        return new CategoryDTO(
                c.getId(),
                c.getBusiness() != null ? c.getBusiness().getId() : null,
                c.getName(),
                c.getType(),
                c.getIcon(),
                c.getColor(),
                c.getCreatedAt(),
                c.getUpdatedAt()
        );
    }
}
