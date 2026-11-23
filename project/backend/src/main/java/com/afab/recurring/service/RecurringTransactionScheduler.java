package com.afab.recurring.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Periodically sweeps due recurring transaction rules across businesses.
 * Safe for multi-instance execution because each occurrence is guarded by
 * pessimistic locking and DB UNIQUE (recurring_transaction_id, scheduled_date).
 */
@Component
public class RecurringTransactionScheduler {

    private static final Logger log = LoggerFactory.getLogger(RecurringTransactionScheduler.class);

    private final RecurringTransactionService recurringTransactionService;
    private final boolean schedulerEnabled;

    public RecurringTransactionScheduler(
            RecurringTransactionService recurringTransactionService,
            @Value("${afab.recurring.scheduler-enabled:true}") boolean schedulerEnabled
    ) {
        this.recurringTransactionService = recurringTransactionService;
        this.schedulerEnabled = schedulerEnabled;
    }

    @Scheduled(cron = "${afab.recurring.cron:0 */15 * * * *}")
    public void runDueSchedules() {
        if (!schedulerEnabled) {
            return;
        }
        int generated = recurringTransactionService.processDueRecurringTransactions();
        if (generated > 0) {
            log.info("Recurring transaction scheduler generated {} transaction(s)", generated);
        }
    }
}
