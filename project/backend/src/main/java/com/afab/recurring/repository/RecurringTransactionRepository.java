package com.afab.recurring.repository;

import com.afab.recurring.domain.RecurringTransaction;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecurringTransactionRepository extends JpaRepository<RecurringTransaction, UUID> {

    @Query("SELECT r FROM RecurringTransaction r LEFT JOIN FETCH r.category WHERE r.business.id = :businessId ORDER BY r.active DESC, r.nextExecutionDate ASC")
    List<RecurringTransaction> findAllByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT r FROM RecurringTransaction r JOIN FETCH r.business b LEFT JOIN FETCH r.category " +
           "WHERE r.active = TRUE AND b.archivedAt IS NULL AND r.nextExecutionDate <= :cutoffDate")
    List<RecurringTransaction> findPotentiallyDueRules(@Param("cutoffDate") LocalDate cutoffDate);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM RecurringTransaction r JOIN FETCH r.business LEFT JOIN FETCH r.category WHERE r.id = :id")
    Optional<RecurringTransaction> findByIdForUpdate(@Param("id") UUID id);
}
