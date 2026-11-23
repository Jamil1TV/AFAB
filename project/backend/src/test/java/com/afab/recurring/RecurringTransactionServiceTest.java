package com.afab.recurring;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.currency.ExchangeRateService;
import com.afab.finance.currency.ExchangeRateService.FxQuote;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.CategoryService;
import com.afab.finance.service.TransactionService;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.recurring.domain.RecurrenceFrequency;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.domain.RecurringTransactionExecution;
import com.afab.recurring.dto.RecurringTransactionRequest;
import com.afab.recurring.repository.RecurringTransactionExecutionRepository;
import com.afab.recurring.repository.RecurringTransactionRepository;
import com.afab.recurring.service.RecurringExecutionProcessor;
import com.afab.recurring.service.RecurringTransactionService;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RecurringTransactionServiceTest {

    @Mock private RecurringTransactionRepository recurringRepository;
    @Mock private RecurringTransactionExecutionRepository executionRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private CategoryService categoryService;
    @Mock private FinanceStatsService financeStatsService;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private AuditService auditService;

    private TransactionService transactionService;
    private RecurringExecutionProcessor processor;
    private Business business;
    private User user;

    @BeforeEach
    void setUp() {
        transactionService = new TransactionService(
                transactionRepository, categoryRepository, currentBusinessService,
                categoryService, auditService, financeStatsService, exchangeRateService
        );
        processor = new RecurringExecutionProcessor(
                recurringRepository, executionRepository, transactionRepository, transactionService
        );

        user = new User();
        user.setId(UUID.randomUUID());
        user.setEmail("owner@afab.test");

        business = new Business();
        business.setId(UUID.randomUUID());
        business.setName("Acme Corp");
        business.setCurrency("TND");
        business.setTimezone("UTC");
    }

    @Test
    void idempotentExecutionCreatesTransactionOnceAndAdvancesSchedule() {
        UUID ruleId = UUID.randomUUID();
        RecurringTransaction rule = new RecurringTransaction();
        rule.setId(ruleId);
        rule.setBusiness(business);
        rule.setType("EXPENSE");
        rule.setDescription("Office Rent");
        rule.setAmount(new BigDecimal("1500.0000"));
        rule.setCurrency("TND");
        rule.setFrequency(RecurrenceFrequency.MONTHLY);
        rule.setStartDate(LocalDate.of(2026, 1, 1));
        rule.setNextExecutionDate(LocalDate.of(2026, 1, 1));
        rule.setActive(true);

        Set<LocalDate> executedDates = new HashSet<>();
        when(recurringRepository.findByIdForUpdate(ruleId)).thenReturn(Optional.of(rule));
        when(executionRepository.existsByRecurringTransactionIdAndScheduledDate(eq(ruleId), any(LocalDate.class)))
                .thenAnswer(inv -> executedDates.contains(inv.getArgument(1)));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction tx = inv.getArgument(0);
            if (tx.getId() == null) tx.setId(UUID.randomUUID());
            return tx;
        });
        when(executionRepository.save(any(RecurringTransactionExecution.class))).thenAnswer(inv -> {
            RecurringTransactionExecution exec = inv.getArgument(0);
            executedDates.add(exec.getScheduledDate());
            return exec;
        });
        when(recurringRepository.save(any(RecurringTransaction.class))).thenAnswer(inv -> inv.getArgument(0));

        // First execution on 2026-01-01 generates exactly 1 transaction and advances nextExecutionDate to 2026-02-01
        Optional<UUID> first = processor.executeSingleDueOccurrence(ruleId, LocalDate.of(2026, 1, 1));
        assertThat(first).isPresent();
        assertThat(rule.getNextExecutionDate()).isEqualTo(LocalDate.of(2026, 2, 1));

        // Re-running on same day produces nothing (nextExecutionDate is in future)
        Optional<UUID> second = processor.executeSingleDueOccurrence(ruleId, LocalDate.of(2026, 1, 1));
        assertThat(second).isEmpty();

        // Even if nextExecutionDate were reset back to 2026-01-01 (crash recovery replay), idempotency guard skips duplicate
        rule.setNextExecutionDate(LocalDate.of(2026, 1, 1));
        Optional<UUID> replay = processor.executeSingleDueOccurrence(ruleId, LocalDate.of(2026, 1, 1));
        assertThat(replay).isEmpty();
        assertThat(rule.getNextExecutionDate()).isEqualTo(LocalDate.of(2026, 2, 1));

        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    void foreignCurrencyRecurringRuleCapturesImmutableFxSnapshotAtExecutionTime() {
        UUID ruleId = UUID.randomUUID();
        RecurringTransaction rule = new RecurringTransaction();
        rule.setId(ruleId);
        rule.setBusiness(business); // base TND
        rule.setType("EXPENSE");
        rule.setDescription("Cloud Hosting");
        rule.setAmount(new BigDecimal("100.0000"));
        rule.setCurrency("EUR");
        rule.setFrequency(RecurrenceFrequency.MONTHLY);
        rule.setStartDate(LocalDate.of(2026, 3, 1));
        rule.setEndDate(LocalDate.of(2026, 3, 15));
        rule.setNextExecutionDate(LocalDate.of(2026, 3, 1));
        rule.setActive(true);

        when(recurringRepository.findByIdForUpdate(ruleId)).thenReturn(Optional.of(rule));
        when(executionRepository.existsByRecurringTransactionIdAndScheduledDate(ruleId, LocalDate.of(2026, 3, 1))).thenReturn(false);
        when(exchangeRateService.getRateQuote("EUR", "TND"))
                .thenReturn(new FxQuote("EUR", "TND", new BigDecimal("3.350000"), "LIVE_FEED", Instant.parse("2026-03-01T00:00:00Z")));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction tx = inv.getArgument(0);
            tx.setId(UUID.randomUUID());
            return tx;
        });
        when(executionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(recurringRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Optional<UUID> created = processor.executeSingleDueOccurrence(ruleId, LocalDate.of(2026, 3, 1));
        assertThat(created).isPresent();

        ArgumentCaptor<Transaction> txCaptor = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository).save(txCaptor.capture());
        Transaction saved = txCaptor.getValue();
        assertThat(saved.getOriginalAmount()).isEqualByComparingTo("100.0000");
        assertThat(saved.getOriginalCurrency()).isEqualTo("EUR");
        assertThat(saved.getBaseCurrency()).isEqualTo("TND");
        assertThat(saved.getExchangeRate()).isEqualByComparingTo("3.350000");
        assertThat(saved.getConvertedAmount()).isEqualByComparingTo("335.0000");
        assertThat(saved.getAmount()).isEqualByComparingTo("335.0000");

        // Next date 2026-04-01 exceeds endDate 2026-03-15 -> auto-deactivated!
        assertThat(rule.isActive()).isFalse();
    }

    @Test
    void respectsBusinessTimezoneBoundaryWhenScheduling() {
        // UTC time is 2026-05-01T23:30:00Z
        // For Asia/Tokyo (UTC+9), local date is already 2026-05-02 -> rule scheduled for 2026-05-02 IS due!
        // For America/Los_Angeles (UTC-7), local date is still 2026-05-01 -> rule scheduled for 2026-05-02 is NOT due!
        Clock fixedClock = Clock.fixed(Instant.parse("2026-05-01T23:30:00Z"), ZoneOffset.UTC);
        RecurringTransactionService service = new RecurringTransactionService(
                recurringRepository, executionRepository, categoryRepository,
                currentBusinessService, processor, auditService, fixedClock
        );

        Business tokyoBiz = new Business();
        tokyoBiz.setId(UUID.randomUUID());
        tokyoBiz.setTimezone("Asia/Tokyo");

        Business laBiz = new Business();
        laBiz.setId(UUID.randomUUID());
        laBiz.setTimezone("America/Los_Angeles");

        assertThat(service.currentDateForBusiness(tokyoBiz)).isEqualTo(LocalDate.of(2026, 5, 2));
        assertThat(service.currentDateForBusiness(laBiz)).isEqualTo(LocalDate.of(2026, 5, 1));
    }

    @Test
    void crossTenantAccessToRecurringRuleIsRejected() {
        RecurringTransactionService service = new RecurringTransactionService(
                recurringRepository, executionRepository, categoryRepository,
                currentBusinessService, processor, auditService, Clock.systemUTC()
        );

        Business otherBiz = new Business();
        otherBiz.setId(UUID.randomUUID());

        RecurringTransaction foreignRule = new RecurringTransaction();
        foreignRule.setId(UUID.randomUUID());
        foreignRule.setBusiness(otherBiz);

        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(business);
        when(recurringRepository.findById(foreignRule.getId())).thenReturn(Optional.of(foreignRule));

        assertThatThrownBy(() -> service.getById("owner@afab.test", foreignRule.getId()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void cadenceCalculationsHandleWeeklyMonthlyQuarterlyYearly() {
        LocalDate base = LocalDate.of(2026, 1, 31);
        assertThat(RecurrenceFrequency.WEEKLY.nextDate(base)).isEqualTo(LocalDate.of(2026, 2, 7));
        assertThat(RecurrenceFrequency.MONTHLY.nextDate(base)).isEqualTo(LocalDate.of(2026, 2, 28));
        assertThat(RecurrenceFrequency.QUARTERLY.nextDate(base)).isEqualTo(LocalDate.of(2026, 4, 30));
        assertThat(RecurrenceFrequency.YEARLY.nextDate(base)).isEqualTo(LocalDate.of(2027, 1, 31));
    }
}
