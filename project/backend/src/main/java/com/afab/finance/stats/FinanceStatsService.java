package com.afab.finance.stats;

import com.afab.business.Business;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.dashboard.dto.DashboardSummaryDTO.*;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Finance Stats Service — Single Source of Truth for financial aggregation.
 *
 * Accounting Semantics (Locked per Decision D4):
 * 1. Cash basis: Only COMPLETED transactions count towards financial performance metrics.
 * 2. Uniqueness: Root transactions only (parentTransaction IS NULL) to prevent split items from inflating totals.
 * 3. Soft-deletes: Transactions with deletedAt IS NOT NULL are strictly excluded.
 * 4. Multi-tenant: All aggregations are isolated to the caller's active business.
 */
@Service
public class FinanceStatsService {

    private final TransactionRepository transactionRepository;

    public FinanceStatsService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    @Transactional(readOnly = true)
    public DashboardSummaryDTO buildDashboardSummary(Business business, String period) {
        UUID businessId = business.getId();
        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";
        String businessName = (business.getName() != null && !business.getName().isBlank())
                ? business.getName() : "My Business";

        // 1. Resolve date boundaries for current and previous comparative period
        DateRange currentRange = resolveDateRange(period);
        DateRange previousRange = resolvePreviousDateRange(currentRange);

        // 2. Aggregate current period totals (COMPLETED only)
        BigDecimal currentRevenue = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "INCOME", currentRange.startDate, currentRange.endDate
        );
        BigDecimal currentExpenses = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "EXPENSE", currentRange.startDate, currentRange.endDate
        );
        BigDecimal currentProfit = currentRevenue.subtract(currentExpenses);
        BigDecimal currentCashFlow = currentProfit; // Cash basis: Net cash inflow/outflow

        // 3. Aggregate previous period totals for comparative delta
        BigDecimal prevRevenue = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "INCOME", previousRange.startDate, previousRange.endDate
        );
        BigDecimal prevExpenses = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "EXPENSE", previousRange.startDate, previousRange.endDate
        );
        BigDecimal prevProfit = prevRevenue.subtract(prevExpenses);
        BigDecimal prevCashFlow = prevProfit;

        // 4. Compute KPI Metrics with percentage deltas
        KpiMetric revenueMetric = buildKpiMetric(currentRevenue, prevRevenue, currency, false);
        KpiMetric expensesMetric = buildKpiMetric(currentExpenses, prevExpenses, currency, true);
        KpiMetric profitMetric = buildKpiMetric(currentProfit, prevProfit, currency, false);
        KpiMetric cashFlowMetric = buildKpiMetric(currentCashFlow, prevCashFlow, currency, false);
        KpiData kpiData = new KpiData(revenueMetric, expensesMetric, profitMetric, cashFlowMetric);

        // 5. 6-Month Monthly Trend (Trailing 6 months)
        List<RevenueDataPoint> revenueData = buildTrailing6MonthsTrend(businessId);

        // 6. Category Breakdown for Expenses in current period
        List<ExpenseCategory> expenseCategories = buildExpenseCategories(businessId, currentRange, currentExpenses, currency);

        // 7. Recent Transactions (Latest 5 items)
        List<TransactionItem> recentTransactions = buildRecentTransactions(businessId, currency);

        // 8. Honest Placeholders: Reminders & Customers (will be populated in Phase 8 & 14)
        List<ReminderItem> reminders = List.of();
        List<CustomerItem> customers = List.of();

        return new DashboardSummaryDTO(
                kpiData,
                revenueData,
                recentTransactions,
                expenseCategories,
                reminders,
                customers,
                currency,
                businessName
        );
    }

    private KpiMetric buildKpiMetric(BigDecimal current, BigDecimal previous, String currency, boolean isExpense) {
        BigDecimal delta = current.subtract(previous);
        BigDecimal pct;
        boolean isPositive;

        if (previous.compareTo(BigDecimal.ZERO) == 0) {
            if (current.compareTo(BigDecimal.ZERO) == 0) {
                pct = BigDecimal.ZERO;
            } else if (current.compareTo(BigDecimal.ZERO) > 0) {
                pct = new BigDecimal("100.0");
            } else {
                pct = new BigDecimal("-100.0");
            }
        } else {
            pct = delta.divide(previous.abs(), 4, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"))
                    .setScale(1, RoundingMode.HALF_UP);
        }

        // For expenses: decrease is positive, increase is negative
        if (isExpense) {
            isPositive = current.compareTo(previous) <= 0;
        } else {
            isPositive = current.compareTo(previous) >= 0;
        }

        String sign = pct.compareTo(BigDecimal.ZERO) > 0 ? "+" : "";
        String changeStr = sign + pct.setScale(1, RoundingMode.HALF_UP) + "%";
        String formattedValue = formatMoney(current, currency);

        return new KpiMetric(formattedValue, changeStr, isPositive, current, pct);
    }

    private List<RevenueDataPoint> buildTrailing6MonthsTrend(UUID businessId) {
        List<RevenueDataPoint> points = new ArrayList<>();
        YearMonth currentYm = YearMonth.now();

        for (int i = 5; i >= 0; i--) {
            YearMonth ym = currentYm.minusMonths(i);
            LocalDate start = ym.atDay(1);
            LocalDate end = ym.atEndOfMonth();

            BigDecimal rev = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                    businessId, "INCOME", start, end
            );
            BigDecimal exp = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                    businessId, "EXPENSE", start, end
            );

            String isoMonth = ym.toString(); // "2026-05"
            String shortName = ym.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH); // "May"

            points.add(new RevenueDataPoint(isoMonth, shortName, rev.doubleValue(), exp.doubleValue()));
        }

        return points;
    }

    private List<ExpenseCategory> buildExpenseCategories(UUID businessId, DateRange range, BigDecimal totalExpenses, String currency) {
        List<Object[]> rawList = transactionRepository.findExpenseCategoryBreakdown(
                businessId, range.startDate, range.endDate
        );

        List<ExpenseCategory> categories = new ArrayList<>();
        for (Object[] row : rawList) {
            String name = (String) row[0];
            String color = (String) row[1];
            BigDecimal amount = (BigDecimal) row[2];

            double percentage = 0.0;
            if (totalExpenses != null && totalExpenses.compareTo(BigDecimal.ZERO) > 0) {
                percentage = amount.divide(totalExpenses, 4, RoundingMode.HALF_UP)
                        .multiply(new BigDecimal("100"))
                        .doubleValue();
                percentage = Math.round(percentage * 10.0) / 10.0;
            }

            categories.add(new ExpenseCategory(
                    name,
                    formatMoney(amount, currency),
                    amount.doubleValue(),
                    percentage,
                    color
            ));
        }

        return categories;
    }

    private List<TransactionItem> buildRecentTransactions(UUID businessId, String currency) {
        List<Transaction> txList = transactionRepository.findRecentTransactions(
                businessId, PageRequest.of(0, 5)
        );

        List<TransactionItem> items = new ArrayList<>();
        for (Transaction tx : txList) {
            boolean isCredit = "INCOME".equalsIgnoreCase(tx.getType());
            String initials = extractInitials(tx.getDescription());
            String color = isCredit ? "bg-emerald-500" : "bg-purple-500";
            String dateStr = tx.getTransactionDate() != null ? tx.getTransactionDate().toString() : "";
            String status = tx.getStatus() != null ? tx.getStatus() : "Completed";

            items.add(new TransactionItem(
                    tx.getId() != null ? tx.getId().toString() : "",
                    tx.getDescription(),
                    tx.getDescription(),
                    (isCredit ? "+" : "-") + formatMoney(tx.getAmount(), currency),
                    tx.getAmount(),
                    dateStr,
                    tx.getType(),
                    status,
                    color,
                    initials,
                    isCredit
            ));
        }

        return items;
    }

    private DateRange resolveDateRange(String period) {
        LocalDate today = LocalDate.now();
        if (period == null || period.isBlank() || "month".equalsIgnoreCase(period) || "monthly".equalsIgnoreCase(period)) {
            YearMonth ym = YearMonth.from(today);
            return new DateRange(ym.atDay(1), ym.atEndOfMonth());
        }
        if ("30d".equalsIgnoreCase(period) || "weekly".equalsIgnoreCase(period) || "week".equalsIgnoreCase(period)) {
            int days = "weekly".equalsIgnoreCase(period) || "week".equalsIgnoreCase(period) ? 7 : 30;
            return new DateRange(today.minusDays(days - 1), today);
        }
        if ("year".equalsIgnoreCase(period) || "yearly".equalsIgnoreCase(period)) {
            return new DateRange(LocalDate.of(today.getYear(), 1, 1), LocalDate.of(today.getYear(), 12, 31));
        }
        // Default to current month
        YearMonth ym = YearMonth.from(today);
        return new DateRange(ym.atDay(1), ym.atEndOfMonth());
    }

    private DateRange resolvePreviousDateRange(DateRange current) {
        long days = ChronoUnit.DAYS.between(current.startDate, current.endDate) + 1;
        LocalDate prevEnd = current.startDate.minusDays(1);
        LocalDate prevStart = prevEnd.minusDays(days - 1);
        return new DateRange(prevStart, prevEnd);
    }

    private String extractInitials(String desc) {
        if (desc == null || desc.isBlank()) return "TX";
        String[] parts = desc.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
        }
        return ("" + parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase();
    }

    private String formatMoney(BigDecimal amount, String currency) {
        if (amount == null) amount = BigDecimal.ZERO;
        BigDecimal rounded = amount.setScale(2, RoundingMode.HALF_UP);
        return currency + " " + rounded.toPlainString();
    }

    private static class DateRange {
        final LocalDate startDate;
        final LocalDate endDate;

        DateRange(LocalDate startDate, LocalDate endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
}
