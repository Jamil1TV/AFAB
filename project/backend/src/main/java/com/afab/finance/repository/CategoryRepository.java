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
}
