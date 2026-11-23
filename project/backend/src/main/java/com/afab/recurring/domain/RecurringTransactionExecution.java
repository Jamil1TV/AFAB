package com.afab.recurring.domain;

import com.afab.business.Business;
import com.afab.finance.domain.Transaction;
import jakarta.persistence.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "recurring_transaction_executions")
public class RecurringTransactionExecution {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recurring_transaction_id", nullable = false)
    private RecurringTransaction recurringTransaction;

    @Column(name = "scheduled_date", nullable = false)
    private LocalDate scheduledDate;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false, unique = true)
    private Transaction transaction;

    @Column(name = "executed_at", nullable = false, updatable = false)
    private Instant executedAt;

    @PrePersist
    protected void onCreate() {
        this.executedAt = Instant.now();
    }

    public RecurringTransactionExecution() {}

    public RecurringTransactionExecution(
            Business business,
            RecurringTransaction recurringTransaction,
            LocalDate scheduledDate,
            Transaction transaction
    ) {
        this.business = business;
        this.recurringTransaction = recurringTransaction;
        this.scheduledDate = scheduledDate;
        this.transaction = transaction;
    }

    public UUID getId() { return id; }
    public Business getBusiness() { return business; }
    public RecurringTransaction getRecurringTransaction() { return recurringTransaction; }
    public LocalDate getScheduledDate() { return scheduledDate; }
    public Transaction getTransaction() { return transaction; }
    public Instant getExecutedAt() { return executedAt; }
}
