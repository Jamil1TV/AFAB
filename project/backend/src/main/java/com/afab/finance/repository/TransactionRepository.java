package com.afab.finance.repository;

import com.afab.finance.domain.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    @Query("SELECT t FROM Transaction t WHERE t.business.id = :businessId " +
           "AND (:type IS NULL OR t.type = :type) " +
           "AND (:categoryId IS NULL OR t.category.id = :categoryId) " +
           "AND (:search IS NULL OR LOWER(t.description) LIKE LOWER(CONCAT('%', :search, '%'))) " +
           "ORDER BY t.transactionDate DESC, t.createdAt DESC")
    Page<Transaction> searchTransactions(
            @Param("businessId") UUID businessId,
            @Param("type") String type,
            @Param("categoryId") UUID categoryId,
            @Param("search") String search,
            Pageable pageable
    );

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transaction t WHERE t.business.id = :businessId AND t.type = :type")
    BigDecimal sumAmountByBusinessAndType(@Param("businessId") UUID businessId, @Param("type") String type);

    long countByBusinessId(UUID businessId);
}
