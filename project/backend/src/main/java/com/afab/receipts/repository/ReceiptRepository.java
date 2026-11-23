package com.afab.receipts.repository;

import com.afab.receipts.domain.Receipt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReceiptRepository extends JpaRepository<Receipt, UUID> {

    @Query("SELECT r FROM Receipt r WHERE r.id = :id AND r.deletedAt IS NULL")
    Optional<Receipt> findActiveById(@Param("id") UUID id);

    @Query("SELECT r FROM Receipt r WHERE r.business.id = :businessId AND r.transaction.id = :transactionId AND r.deletedAt IS NULL ORDER BY r.createdAt DESC")
    List<Receipt> findActiveByBusinessIdAndTransactionId(
            @Param("businessId") UUID businessId,
            @Param("transactionId") UUID transactionId
    );
}
