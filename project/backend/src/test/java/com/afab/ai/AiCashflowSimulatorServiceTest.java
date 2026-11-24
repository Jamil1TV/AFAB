package com.afab.ai;

import com.afab.ai.service.AiCashflowSimulatorService;
import com.afab.ai.service.AiCashflowSimulatorService.SimulationResult;
import com.afab.business.Business;
import com.afab.customers.domain.Customer;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.recurring.domain.RecurrenceFrequency;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.repository.RecurringTransactionRepository;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiCashflowSimulatorServiceTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private RecurringTransactionRepository recurringRepository;
    @Mock private InvoiceRepository invoiceRepository;

    private AiCashflowSimulatorService simulatorService;
    private Business business;

    @BeforeEach
    void setUp() {
        simulatorService = new AiCashflowSimulatorService(
                transactionRepository, recurringRepository, invoiceRepository
        );
        User owner = new User("Sam", "CFO", "sam@afab.test", "hash");
        owner.setId(UUID.randomUUID());
        business = new Business(owner, "Maghreb Tech", "TND");
        business.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Simulates exact BigDecimal hiring cost + delayed customer invoice impact with area chart")
    void simulatesHiringAndDelayedInvoiceDeterministically() {
        // Trailing 3 months avg: Rev = 9,000/3 = 3,000/mo, Exp = 3,000/3 = 1,000/mo
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(business.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("9000.00"));
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(business.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("3000.00"));

        RecurringTransaction rent = new RecurringTransaction();
        rent.setType("EXPENSE");
        rent.setAmount(new BigDecimal("800.00"));
        rent.setFrequency(RecurrenceFrequency.MONTHLY);
        rent.setActive(true);
        when(recurringRepository.findAllByBusinessId(business.getId())).thenReturn(List.of(rent));

        Customer acme = new Customer();
        acme.setId(UUID.randomUUID());
        acme.setName("Acme Corp");

        Invoice inv = new Invoice();
        inv.setId(UUID.randomUUID());
        inv.setBusiness(business);
        inv.setCustomer(acme);
        inv.setInvoiceNumber("INV-2026-0042");
        inv.setStatus(InvoiceStatus.UNPAID);
        inv.setIssueDate(LocalDate.now());
        inv.setDueDate(LocalDate.now());
        inv.setTotalAmount(new BigDecimal("2000.00"));
        inv.setPaidAmount(BigDecimal.ZERO);
        inv.setOutstandingBalance(new BigDecimal("2000.00"));
        when(invoiceRepository.findAllByBusinessIdWithCustomer(business.getId())).thenReturn(List.of(inv));

        // 4 months horizon, hiring at +2500/month, Acme delayed 35 days (pushes inflow from month 0 to month 1+)
        SimulationResult res = simulatorService.simulate(business, Map.of(
                "months", 4,
                "extraMonthlyExpense", 2500,
                "delayedCustomerName", "Acme",
                "delayedCustomerPaymentDays", 35
        ));

        // Baseline: (3000 - 1000) * 4 + 2000 invoice = 10,000.00 TND
        // Scenario: Baseline 10,000 - (2500 * 4 hiring = 10,000) = 0.00 TND (month 1 starts at -500.00 before delayed invoice arrives -> DEFICIT_RISK)
        assertThat((BigDecimal) res.payload().get("endingCumulativeBaseline"))
                .isEqualByComparingTo("10000.00");
        assertThat((BigDecimal) res.payload().get("endingCumulativeScenario"))
                .isEqualByComparingTo("0.00");
        assertThat((BigDecimal) res.payload().get("delayedInvoiceAmount"))
                .isEqualByComparingTo("2000.00");
        assertThat(res.payload().get("verdict")).isEqualTo("DEFICIT_RISK");
        assertThat(res.chart().chartType()).isEqualTo("area");
        assertThat(res.chart().data()).hasSize(4);
    }
}
