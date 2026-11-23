package com.afab.budgets.repository;

import com.afab.budgets.domain.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, UUID> {

    @Query("SELECT b FROM Budget b LEFT JOIN FETCH b.category WHERE b.id = :id AND b.archivedAt IS NULL")
    Optional<Budget> findActiveById(@Param("id") UUID id);

    @Query("SELECT b FROM Budget b LEFT JOIN FETCH b.category " +
           "WHERE b.business.id = :businessId " +
           "AND (:includeArchived = TRUE OR b.archivedAt IS NULL) " +
           "ORDER BY b.status ASC, b.startDate DESC, b.createdAt DESC")
    List<Budget> findAllByBusinessId(
            @Param("businessId") UUID businessId,
            @Param("includeArchived") boolean includeArchived
    );

    @Query("SELECT b FROM Budget b LEFT JOIN FETCH b.category " +
           "WHERE b.business.id = :businessId " +
           "AND b.archivedAt IS NULL " +
           "AND b.status = 'ACTIVE' " +
           "AND b.startDate <= :referenceDate " +
           "AND b.endDate >= :referenceDate " +
           "ORDER BY b.createdAt ASC")
    List<Budget> findCurrentActiveByBusinessId(
            @Param("businessId") UUID businessId,
            @Param("referenceDate") LocalDate referenceDate
    );
}
