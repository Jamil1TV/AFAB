package com.afab.ai;

import com.afab.ai.dto.AiPulseDTO;
import com.afab.ai.service.AiPulseService;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.customers.domain.Customer;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiPulseServiceTest {

    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private TransactionRepository transactionRepository;
    @Mock private BudgetService budgetService;
    @Mock private InvoiceRepository invoiceRepository;
    @Mock private ReceiptRepository receiptRepository;

    private AiPulseService pulseService;
    private Business business;

    @BeforeEach
    void setUp() {
        pulseService = new AiPulseService(
                currentBusinessService, transactionRepository, budgetService, invoiceRepository, receiptRepository
        );
        User owner = new User("Lina", "CEO", "lina@afab.test", "hash");
        owner.setId(UUID.randomUUID());
        business = new Business(owner, "Olive Co", "TND");
        business.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Detects spending spikes, duplicate expenses, budget burn-rate, missing receipts, and overdue invoices")
    void detectsAllFivePulseSignalFamilies() {
        LocalDate today = LocalDate.now();
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(business.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("12000.00"));
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(business.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("4500.00"));

        // Category spike: Marketing 900 this month vs 900/3 = 300 3-mo avg (+200%)
        when(transactionRepository.findCategoryBreakdownByType(
                eq(business.getId()), eq("EXPENSE"), eq(today.withDayOfMonth(1)), eq(today)
        )).thenReturn(List.<Object[]>of(new Object[]{"Marketing", "#8b5cf6", new BigDecimal("900.00")}));
        when(transactionRepository.findCategoryBreakdownByType(
                eq(business.getId()), eq("EXPENSE"), eq(java.time.YearMonth.from(today).minusMonths(3).atDay(1)), eq(java.time.YearMonth.from(today).minusMonths(1).atEndOfMonth())
        )).thenReturn(List.<Object[]>of(new Object[]{"Marketing", "#8b5cf6", new BigDecimal("900.00")}));

        // Duplicate expenses missing receipts
        Transaction t1 = new Transaction();
        t1.setId(UUID.randomUUID());
        t1.setBusiness(business);
        t1.setDescription("Facebook Ads");
        t1.setAmount(new BigDecimal("250.00"));
        t1.setTransactionDate(today.minusDays(1));

        Transaction t2 = new Transaction();
        t2.setId(UUID.randomUUID());
        t2.setBusiness(business);
        t2.setDescription("Facebook Ads");
        t2.setAmount(new BigDecimal("250.00"));
        t2.setTransactionDate(today.minusDays(2));

        when(transactionRepository.searchTransactionsWithCategory(
                eq(business.getId()), eq("EXPENSE"), any(LocalDate.class), eq(today), eq(null), any()
        )).thenReturn(List.of(t1, t2));
        when(receiptRepository.findActiveByBusinessIdAndTransactionId(eq(business.getId()), any())).thenReturn(List.of());

        // Fast budget burn rate
        BudgetDTO fastBudget = new BudgetDTO(
                UUID.randomUUID(), business.getId(), "Marketing Cap", new BigDecimal("1000.00"), "TND",
                null, "Marketing", "#8b5cf6", "MONTHLY", today.minusDays(5), today.plusDays(24),
                80, null, "ACTIVE", new BigDecimal("600.00"), new BigDecimal("400.00"),
                BigDecimal.ZERO, new BigDecimal("60.0"), "OK", Instant.now(), Instant.now()
        );
        when(budgetService.buildSummaryForBusiness(business, today)).thenReturn(
                new BudgetSummaryDTO("TND", 1, 0, 0, new BigDecimal("1000.00"), new BigDecimal("600.00"), new BigDecimal("400.00"), List.of(fastBudget))
        );

        // Overdue invoice
        Customer c = new Customer();
        c.setId(UUID.randomUUID());
        c.setName("Atlas SARL");
        Invoice overdue = new Invoice();
        overdue.setId(UUID.randomUUID());
        overdue.setBusiness(business);
        overdue.setCustomer(c);
        overdue.setInvoiceNumber("INV-2026-0077");
        overdue.setStatus(InvoiceStatus.UNPAID);
        overdue.setIssueDate(today.minusDays(30));
        overdue.setDueDate(today.minusDays(8));
        overdue.setCurrency("TND");
        overdue.setTotalAmount(new BigDecimal("1500.00"));
        overdue.setOutstandingBalance(new BigDecimal("1500.00"));
        when(invoiceRepository.findAllByBusinessIdWithCustomer(business.getId())).thenReturn(List.of(overdue));

        AiPulseDTO pulse = pulseService.buildPulseForBusiness(business);

        assertThat(pulse.alerts()).extracting(AiPulseDTO.PulseAlert::type).contains(
                "DUPLICATE_EXPENSE", "BUDGET_BURN", "MISSING_RECEIPTS", "OVERDUE_INVOICES"
        );
        assertThat(pulse.overdueCount()).isEqualTo(1);
        assertThat(pulse.missingReceiptCount()).isEqualTo(2);
        assertThat(pulse.highCount()).isGreaterThanOrEqualTo(1);
    }
}
