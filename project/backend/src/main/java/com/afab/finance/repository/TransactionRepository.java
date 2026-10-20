package com.afab.finance.repository;

import com.afab.finance.domain.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    @Query("SELECT t FROM Transaction t WHERE t.id = :id AND t.deletedAt IS NULL")
    Optional<Transaction> findActiveById(@Param("id") UUID id);

    @Query("SELECT t FROM Transaction t WHERE t.business.id = :businessId " +
           "AND t.deletedAt IS NULL " +
           "AND t.parentTransaction IS NULL " +
           "AND (:type IS NULL OR t.type = :type) " +
           "AND (:categoryId IS NULL OR t.category.id = :categoryId) " +
           "AND (:status IS NULL OR t.status = :status) " +
           "AND (:paymentMethod IS NULL OR t.paymentMethod = :paymentMethod) " +
           "AND (:taxDeductible IS NULL OR t.taxDeductible = :taxDeductible) " +
           "AND (CAST(:startDate AS date) IS NULL OR t.transactionDate >= :startDate) " +
           "AND (CAST(:endDate AS date) IS NULL OR t.transactionDate <= :endDate) " +
           "AND (:search IS NULL OR LOWER(t.description) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%'))) " +
           "ORDER BY t.transactionDate DESC, t.createdAt DESC")
    Page<Transaction> searchTransactions(
            @Param("businessId") UUID businessId,
            @Param("type") String type,
            @Param("categoryId") UUID categoryId,
            @Param("status") String status,
            @Param("paymentMethod") String paymentMethod,
            @Param("taxDeductible") Boolean taxDeductible,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("search") String search,
            Pageable pageable
    );

    @Query("SELECT t FROM Transaction t WHERE t.business.id = :businessId " +
           "AND t.deletedAt IS NULL " +
           "AND (:excludeId IS NULL OR t.id <> :excludeId) " +
           "AND t.amount = :amount " +
           "AND LOWER(t.description) = LOWER(:description) " +
           "AND t.transactionDate BETWEEN :fromDate AND :toDate")
    List<Transaction> findPotentialDuplicates(
            @Param("businessId") UUID businessId,
            @Param("excludeId") UUID excludeId,
            @Param("amount") BigDecimal amount,
            @Param("description") String description,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate
    );

    @Query("SELECT t FROM Transaction t WHERE t.business.id = :businessId " +
           "AND t.deletedAt IS NULL " +
           "AND t.type = 'EXPENSE' " +
           "AND LOWER(t.description) = LOWER(:description) " +
           "AND t.transactionDate < :currentDate " +
           "ORDER BY t.transactionDate DESC")
    List<Transaction> findPastExpensesByDescription(
            @Param("businessId") UUID businessId,
            @Param("description") String description,
            @Param("currentDate") LocalDate currentDate,
            Pageable pageable
    );

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t " +
           "WHERE t.business.id = :businessId " +
           "AND t.type = :type " +
           "AND t.status = 'COMPLETED' " +
           "AND t.deletedAt IS NULL " +
           "AND t.parentTransaction IS NULL " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate")
    BigDecimal sumCompletedAmountByBusinessAndTypeAndDateRange(
            @Param("businessId") UUID businessId,
            @Param("type") String type,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("SELECT COALESCE(c.name, 'Uncategorized'), COALESCE(c.color, '#8b5cf6'), COALESCE(SUM(t.amount), 0) " +
           "FROM Transaction t LEFT JOIN t.category c " +
           "WHERE t.business.id = :businessId " +
           "AND t.type = 'EXPENSE' " +
           "AND t.status = 'COMPLETED' " +
           "AND t.deletedAt IS NULL " +
           "AND t.parentTransaction IS NULL " +
           "AND t.transactionDate BETWEEN :startDate AND :endDate " +
           "GROUP BY COALESCE(c.name, 'Uncategorized'), COALESCE(c.color, '#8b5cf6') " +
           "ORDER BY SUM(t.amount) DESC")
    List<Object[]> findExpenseCategoryBreakdown(
            @Param("businessId") UUID businessId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    @Query("SELECT t FROM Transaction t " +
           "WHERE t.business.id = :businessId " +
           "AND t.deletedAt IS NULL " +
           "AND t.parentTransaction IS NULL " +
           "ORDER BY t.transactionDate DESC, t.createdAt DESC")
    List<Transaction> findRecentTransactions(
            @Param("businessId") UUID businessId,
            Pageable pageable
    );

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t WHERE t.business.id = :businessId AND t.type = :type AND t.deletedAt IS NULL AND t.parentTransaction IS NULL")
    BigDecimal sumAmountByBusinessAndType(@Param("businessId") UUID businessId, @Param("type") String type);

    @Query("SELECT COUNT(t) FROM Transaction t WHERE t.business.id = :businessId AND t.deletedAt IS NULL AND t.parentTransaction IS NULL")
    long countByBusinessIdAndDeletedAtIsNull(@Param("businessId") UUID businessId);
}
