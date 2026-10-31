package com.afab.finance.stats;

import com.afab.business.Business;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FinanceStatsServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private FinanceStatsService financeStatsService;

    private Business testBusiness;
    private UUID businessId;

    @BeforeEach
    void setUp() {
        businessId = UUID.randomUUID();
        testBusiness = new Business();
        testBusiness.setId(businessId);
        testBusiness.setName("Atlas Ventures");
        testBusiness.setCurrency("USD");
    }

    @Test
    @DisplayName("buildDashboardSummary: computes cash-basis KPIs, profit, and deltas correctly")
    void testBuildDashboardSummaryWithData() {
        // Current period: Revenue $5,000, Expenses $2,000 -> Profit $3,000
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("5000.00"), new BigDecimal("4000.00")); // current, previous

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(businessId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("2000.00"), new BigDecimal("1000.00")); // current, previous

        // Mock recent transactions
        Transaction tx1 = new Transaction();
        tx1.setId(UUID.randomUUID());
        tx1.setDescription("Enterprise License");
        tx1.setAmount(new BigDecimal("5000.00"));
        tx1.setType("INCOME");
        tx1.setStatus("COMPLETED");
        tx1.setTransactionDate(LocalDate.now());

        when(transactionRepository.findRecentTransactions(eq(businessId), any(Pageable.class)))
                .thenReturn(List.of(tx1));

        // Mock category breakdown
        when(transactionRepository.findExpenseCategoryBreakdown(eq(businessId), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.<Object[]>of(new Object[]{"Hosting", "#8b5cf6", new BigDecimal("2000.00")}));

        DashboardSummaryDTO summary = financeStatsService.buildDashboardSummary(testBusiness, "month");

        assertThat(summary).isNotNull();
        assertThat(summary.getCurrency()).isEqualTo("USD");
        assertThat(summary.getBusinessName()).isEqualTo("Atlas Ventures");

        // KPI assertions
        assertThat(summary.getKpiData().getRevenue().getRawValue()).isEqualByComparingTo("5000.00");
        assertThat(summary.getKpiData().getExpenses().getRawValue()).isEqualByComparingTo("2000.00");
        assertThat(summary.getKpiData().getProfit().getRawValue()).isEqualByComparingTo("3000.00");
        assertThat(summary.getKpiData().getCashFlow().getRawValue()).isEqualByComparingTo("3000.00");

        // Delta percentage: (5000 - 4000) / 4000 = +25.0%
        assertThat(summary.getKpiData().getRevenue().getChange()).isEqualTo("+25.0%");
        assertThat(summary.getKpiData().getRevenue().getIsPositive()).isTrue();

        // Expenses increased from 1000 to 2000: +100.0%, isPositive = false (for expenses higher is negative)
        assertThat(summary.getKpiData().getExpenses().getIsPositive()).isFalse();

        // Categories breakdown
        assertThat(summary.getExpenseCategories()).hasSize(1);
        assertThat(summary.getExpenseCategories().get(0).getName()).isEqualTo("Hosting");
        assertThat(summary.getExpenseCategories().get(0).getPercentage()).isEqualTo(100.0);

        // Recent transactions
        assertThat(summary.getTransactions()).hasSize(1);
        assertThat(summary.getTransactions().get(0).getIsCredit()).isTrue();
        assertThat(summary.getTransactions().get(0).getInitials()).isEqualTo("EL");
    }

    @Test
    @DisplayName("buildDashboardSummary: handles empty business with zero transactions gracefully")
    void testBuildDashboardSummaryEmpty() {
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(businessId), any(), any(), any()
        )).thenReturn(BigDecimal.ZERO);

        when(transactionRepository.findRecentTransactions(eq(businessId), any(Pageable.class)))
                .thenReturn(List.of());

        when(transactionRepository.findExpenseCategoryBreakdown(eq(businessId), any(), any()))
                .thenReturn(List.of());

        DashboardSummaryDTO summary = financeStatsService.buildDashboardSummary(testBusiness, "month");

        assertThat(summary).isNotNull();
        assertThat(summary.getKpiData().getRevenue().getRawValue()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(summary.getKpiData().getRevenue().getChange()).isEqualTo("0.0%");
        assertThat(summary.getTransactions()).isEmpty();
        assertThat(summary.getExpenseCategories()).isEmpty();
    }

    @Test
    @DisplayName("buildExpenseSummary: computes real totals, dynamic average per day, and real categories")
    void testBuildExpenseSummary() {
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(businessId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("3000.00"));

        Transaction highest = new Transaction();
        highest.setDescription("MacBook Pro");
        highest.setAmount(new BigDecimal("2500.00"));

        when(transactionRepository.findHighestTransactionInDateRange(
                eq(businessId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class), any(Pageable.class)
        )).thenReturn(List.of(highest));

        when(transactionRepository.findCategoryBreakdownByType(
                eq(businessId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(List.of(
                new Object[]{"Hardware", "#8b5cf6", new BigDecimal("2500.00")},
                new Object[]{"Office", "#10b981", new BigDecimal("500.00")}
        ));

        when(transactionRepository.findDailyOverviewByType(
                eq(businessId), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(Collections.singletonList(
                new Object[]{LocalDate.now(), new BigDecimal("3000.00")}
        ));

        com.afab.finance.dto.ExpenseSummaryDTO summary = financeStatsService.buildExpenseSummary(testBusiness, "month");

        assertThat(summary).isNotNull();
        assertThat(summary.getTotalExpenses()).isEqualByComparingTo(new BigDecimal("3000.00"));
        assertThat(summary.getAvgPerDay()).isGreaterThan(BigDecimal.ZERO);
        assertThat(summary.getHighestExpenseTitle()).isEqualTo("MacBook Pro");
        assertThat(summary.getHighestExpenseAmount()).isEqualByComparingTo(new BigDecimal("2500.00"));
        assertThat(summary.getCategoryCount()).isEqualTo(2);
        assertThat(summary.getCategoryBreakdown()).hasSize(2);
        assertThat(summary.getCategoryBreakdown().get(0).getName()).isEqualTo("Hardware");
        assertThat(summary.getCategoryBreakdown().get(0).getPercentage()).isEqualTo(83.3);
        // Honest empty recurring list (no hardcoded Adobe/Shopify)
        assertThat(summary.getRecurringList()).isEmpty();
        assertThat(summary.getRecurringTotal()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(summary.getDailyOverview()).hasSize(1);
    }

    @Test
    @DisplayName("buildRevenueSummary: computes real income totals, sources, and empty top products")
    void testBuildRevenueSummary() {
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("10000.00"));

        Transaction highest = new Transaction();
        highest.setDescription("Enterprise Contract");
        highest.setAmount(new BigDecimal("8000.00"));
        highest.setTransactionDate(LocalDate.now());

        when(transactionRepository.findHighestTransactionInDateRange(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class), any(Pageable.class)
        )).thenReturn(List.of(highest));

        when(transactionRepository.findCategoryBreakdownByType(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(Collections.singletonList(
                new Object[]{"Consulting", "#10b981", new BigDecimal("10000.00")}
        ));

        when(transactionRepository.findDailyOverviewByType(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(Collections.singletonList(
                new Object[]{LocalDate.now(), new BigDecimal("10000.00")}
        ));

        when(transactionRepository.countCompletedByBusinessAndTypeAndDateRange(
                eq(businessId), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(5L);

        com.afab.finance.dto.RevenueSummaryDTO summary = financeStatsService.buildRevenueSummary(testBusiness, "month");

        assertThat(summary).isNotNull();
        assertThat(summary.getTotalRevenue()).isEqualByComparingTo(new BigDecimal("10000.00"));
        assertThat(summary.getGrossRevenue()).isEqualByComparingTo(new BigDecimal("10000.00"));
        assertThat(summary.getNetRevenue()).isEqualByComparingTo(new BigDecimal("10000.00"));
        assertThat(summary.getHighestRevenueAmount()).isEqualByComparingTo(new BigDecimal("8000.00"));
        assertThat(summary.getHighestRevenueDate()).isEqualTo(LocalDate.now().toString());
        assertThat(summary.getTotalInvoices()).isEqualTo(5);
        assertThat(summary.getRevenueBySource()).hasSize(1);
        // Honest empty top products list (no hardcoded AFAB Pro Plan)
        assertThat(summary.getTopProducts()).isEmpty();
    }
}
