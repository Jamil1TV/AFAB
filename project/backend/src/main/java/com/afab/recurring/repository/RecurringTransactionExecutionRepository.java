package com.afab.recurring.repository;

import com.afab.recurring.domain.RecurringTransactionExecution;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface RecurringTransactionExecutionRepository extends JpaRepository<RecurringTransactionExecution, UUID> {
    boolean existsByRecurringTransactionIdAndScheduledDate(UUID recurringTransactionId, LocalDate scheduledDate);
    List<RecurringTransactionExecution> findByRecurringTransactionIdOrderByScheduledDateDesc(UUID recurringTransactionId);
}
