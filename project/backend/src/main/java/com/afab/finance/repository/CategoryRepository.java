package com.afab.finance.repository;

import com.afab.finance.domain.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    @Query("SELECT c FROM Category c WHERE c.business.id = :businessId OR c.business IS NULL ORDER BY c.name ASC")
    List<Category> findAllForBusiness(@Param("businessId") UUID businessId);

    @Query("SELECT COUNT(c) > 0 FROM Category c WHERE c.business.id = :businessId AND LOWER(c.name) = LOWER(:name) AND c.type = :type")
    boolean existsByBusinessAndNameIgnoreCaseAndType(@Param("businessId") UUID businessId, @Param("name") String name, @Param("type") String type);

    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.category.id = :categoryId AND t.deletedAt IS NULL")
    long countActiveTransactionsByCategoryId(@Param("categoryId") UUID categoryId);
}
