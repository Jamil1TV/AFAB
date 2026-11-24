package com.afab.ai;

import com.afab.ai.domain.AiToolAudit;
import com.afab.ai.domain.AiToolAuditRepository;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.rag.AiVectorRepository;
import com.afab.ai.tools.AiFinanceToolRegistry;
import com.afab.ai.tools.AiFinanceToolRegistry.ToolExecutionResult;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.customers.service.CustomerFinancialMetricsProvider;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.dashboard.dto.DashboardSummaryDTO.KpiData;
import com.afab.dashboard.dto.DashboardSummaryDTO.KpiMetric;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.recurring.repository.RecurringTransactionRepository;
import com.afab.user.User;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AiFinanceToolRegistryTest {

    @Mock private FinanceStatsService financeStatsService;
    @Mock private TransactionRepository transactionRepository;
    @Mock private InvoiceRepository invoiceRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private CustomerFinancialMetricsProvider customerMetricsProvider;
    @Mock private BudgetService budgetService;
    @Mock private RecurringTransactionRepository recurringRepository;
    @Mock private ReceiptRepository receiptRepository;
    @Mock private BusinessMemoryRepository memoryRepository;
    @Mock private AiVectorRepository vectorRepository;
    @Mock private AiToolAuditRepository toolAuditRepository;

    private AiFinanceToolRegistry registry;
    private User user;
    private Business business;
    private final ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        registry = new AiFinanceToolRegistry(
                financeStatsService, transactionRepository, invoiceRepository,
                customerRepository, customerMetricsProvider, budgetService,
                recurringRepository, receiptRepository, memoryRepository,
                vectorRepository, toolAuditRepository
        );
        user = new User("Sam", "Owner", "sam@afab.test", "hash");
        user.setId(UUID.randomUUID());

        business = new Business(user, "Sam Studio", "TND");
        business.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("get_business_summary delegates to FinanceStatsService and writes tool audit without leaking args")
    void businessSummaryUsesFinanceStatsAndAudits() throws Exception {
        KpiData kpi = new KpiData(
                new KpiMetric("TND 5000.00", "+10.0%", true, new BigDecimal("5000.00"), new BigDecimal("10.0")),
                new KpiMetric("TND 1800.00", "-5.0%", true, new BigDecimal("1800.00"), new BigDecimal("-5.0")),
                new KpiMetric("TND 3200.00", "+20.0%", true, new BigDecimal("3200.00"), new BigDecimal("20.0")),
                new KpiMetric("TND 3200.00", "+20.0%", true, new BigDecimal("3200.00"), new BigDecimal("20.0"))
        );
        DashboardSummaryDTO dto = new DashboardSummaryDTO(kpi, List.of(), List.of(), List.of(), List.of(), List.of(), "TND", "Sam Studio");
        when(financeStatsService.buildDashboardSummary(business, "month")).thenReturn(dto);

        ToolExecutionResult res = registry.executeTool(user, business, UUID.randomUUID(), "get_business_summary", Map.of("period", "month"));
        JsonNode root = mapper.readTree(res.jsonResult());

        assertThat(root.path("revenue").decimalValue()).isEqualByComparingTo("5000.00");
        assertThat(root.path("expenses").decimalValue()).isEqualByComparingTo("1800.00");
        assertThat(root.path("netProfit").decimalValue()).isEqualByComparingTo("3200.00");
        assertThat(root.path("currency").asText()).isEqualTo("TND");
        assertThat(res.evidence()).hasSize(1);
        assertThat(res.evidence().get(0).href()).isEqualTo("/dashboard");

        ArgumentCaptor<AiToolAudit> auditCaptor = ArgumentCaptor.forClass(AiToolAudit.class);
        verify(toolAuditRepository).save(auditCaptor.capture());
        assertThat(auditCaptor.getValue().getToolName()).isEqualTo("get_business_summary");
        assertThat(auditCaptor.getValue().getResultStatus()).isEqualTo("OK");
        assertThat(auditCaptor.getValue().getArgumentsHash()).hasSize(64);
    }

    @Test
    @DisplayName("compare_periods computes exact BigDecimal deltas and rejects invalid date ranges cleanly")
    void comparePeriodsBigDecimalAndValidation() throws Exception {
        LocalDate fromA = LocalDate.of(2026, 11, 1);
        LocalDate toA = LocalDate.of(2026, 11, 30);
        LocalDate fromB = LocalDate.of(2026, 10, 1);
        LocalDate toB = LocalDate.of(2026, 10, 31);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "INCOME", fromA, toA))
                .thenReturn(new BigDecimal("1200.00"));
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "EXPENSE", fromA, toA))
                .thenReturn(new BigDecimal("450.00"));
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "INCOME", fromB, toB))
                .thenReturn(new BigDecimal("1000.00"));
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "EXPENSE", fromB, toB))
                .thenReturn(new BigDecimal("300.00"));

        ToolExecutionResult res = registry.executeTool(
                user, business, null, "compare_periods",
                Map.of("fromA", "2026-11-01", "toA", "2026-11-30", "fromB", "2026-10-01", "toB", "2026-10-31")
        );
        JsonNode root = mapper.readTree(res.jsonResult());
        assertThat(root.path("revenueDelta").decimalValue()).isEqualByComparingTo("200.00");
        assertThat(root.path("revenueDeltaPct").decimalValue()).isEqualByComparingTo("20.0");
        assertThat(root.path("expenseDelta").decimalValue()).isEqualByComparingTo("150.00");
        assertThat(root.path("expenseDeltaPct").decimalValue()).isEqualByComparingTo("50.0");
        assertThat(root.path("netProfitDelta").decimalValue()).isEqualByComparingTo("50.00");

        ToolExecutionResult bad = registry.executeTool(
                user, business, null, "compare_periods",
                Map.of("fromA", "2026-11-30", "toA", "2026-11-01", "fromB", "2026-10-01", "toB", "2026-10-31")
        );
        assertThat(bad.jsonResult()).contains("Start date cannot be after end date");
    }

    @Test
    @DisplayName("get_invoices_overview and get_budgets_status compute overdue totals and cite source evidence")
    void invoicesAndBudgetsEvidence() throws Exception {
        Customer customer = new Customer();
        customer.setId(UUID.randomUUID());
        customer.setName("Alpha SARL");

        Invoice overdue = new Invoice();
        overdue.setId(UUID.randomUUID());
        overdue.setBusiness(business);
        overdue.setCustomer(customer);
        overdue.setInvoiceNumber("INV-2026-0009");
        overdue.setStatus(InvoiceStatus.UNPAID);
        overdue.setIssueDate(LocalDate.now().minusDays(30));
        overdue.setDueDate(LocalDate.now().minusDays(5));
        overdue.setCurrency("TND");
        overdue.setTotalAmount(new BigDecimal("950.00"));
        overdue.setPaidAmount(new BigDecimal("200.00"));
        overdue.setOutstandingBalance(new BigDecimal("750.00"));

        when(invoiceRepository.findAllByBusinessIdWithCustomer(business.getId())).thenReturn(List.of(overdue));

        ToolExecutionResult invRes = registry.executeTool(
                user, business, null, "get_invoices_overview", Map.of("overdueOnly", true)
        );
        JsonNode invRoot = mapper.readTree(invRes.jsonResult());
        assertThat(invRoot.path("overdueCount").asInt()).isEqualTo(1);
        assertThat(invRoot.path("overdueTotal").decimalValue()).isEqualByComparingTo("750.00");
        assertThat(invRes.evidence()).hasSize(1);
        assertThat(invRes.evidence().get(0).type()).isEqualTo("INVOICE");
        assertThat(invRes.evidence().get(0).href()).isEqualTo("/dashboard/invoices");

        BudgetDTO bDto = new BudgetDTO(
                UUID.randomUUID(), business.getId(), "Marketing Cap", new BigDecimal("1000.00"), "TND",
                null, null, null, "MONTHLY", LocalDate.now().withDayOfMonth(1), LocalDate.now().withDayOfMonth(28),
                80, null, "ACTIVE", new BigDecimal("1100.00"), BigDecimal.ZERO, new BigDecimal("100.00"),
                new BigDecimal("110.00"), "OVER_BUDGET", Instant.now(), Instant.now()
        );
        when(budgetService.buildSummaryForBusiness(eq(business), any(LocalDate.class)))
                .thenReturn(new BudgetSummaryDTO("TND", 1, 0, 1, new BigDecimal("1000.00"), new BigDecimal("1100.00"), BigDecimal.ZERO, List.of(bDto)));

        ToolExecutionResult budRes = registry.executeTool(user, business, null, "get_budgets_status", Map.of());
        JsonNode budRoot = mapper.readTree(budRes.jsonResult());
        assertThat(budRoot.path("overBudgetCount").asInt()).isEqualTo(1);
        assertThat(budRes.evidence()).hasSize(1);
        assertThat(budRes.evidence().get(0).href()).isEqualTo("/dashboard/budgets");
    }

    @Test
    @DisplayName("get_data_coverage explicitly discloses missing bank balance & supplier AP domains")
    void dataCoverageDisclosesUnavailableDomains() throws Exception {
        when(transactionRepository.countByBusinessIdAndDeletedAtIsNull(business.getId())).thenReturn(12L);
        when(invoiceRepository.findAllByBusinessIdWithCustomer(business.getId())).thenReturn(List.of());
        when(customerRepository.findAllActiveByBusinessId(business.getId())).thenReturn(List.of());
        when(budgetService.buildSummaryForBusiness(eq(business), any())).thenReturn(
                new BudgetSummaryDTO("TND", 0, 0, 0, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, List.of())
        );
        when(recurringRepository.findAllByBusinessId(business.getId())).thenReturn(List.of());
        when(memoryRepository.countApprovedByBusinessId(business.getId())).thenReturn(2L);
        when(vectorRepository.countChunks(business.getId())).thenReturn(12L);

        ToolExecutionResult cov = registry.executeTool(user, business, null, "get_data_coverage", Map.of());
        JsonNode root = mapper.readTree(cov.jsonResult());
        assertThat(root.path("availableDomains").path("transactionsCount").asLong()).isEqualTo(12L);
        assertThat(root.path("unavailableDomains").toString()).contains("bank_account_opening_balances");
        assertThat(root.path("unavailableDomains").toString()).contains("supplier_bills_accounts_payable");
    }
}
