package com.afab.reports.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.reports.dto.*;
import com.afab.subscription.EntitlementService;
import com.afab.subscription.PlanLimitReachedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

@Service
public class ReportService {

    private final CurrentBusinessService currentBusinessService;
    private final TransactionRepository transactionRepository;
    private final EntitlementService entitlementService;
    private final CsvReportExporter csvReportExporter;
    private final PdfReportExporter pdfReportExporter;

    public ReportService(
            CurrentBusinessService currentBusinessService,
            TransactionRepository transactionRepository,
            EntitlementService entitlementService,
            CsvReportExporter csvReportExporter,
            PdfReportExporter pdfReportExporter
    ) {
        this.currentBusinessService = currentBusinessService;
        this.transactionRepository = transactionRepository;
        this.entitlementService = entitlementService;
        this.csvReportExporter = csvReportExporter;
        this.pdfReportExporter = pdfReportExporter;
    }

    /**
     * Build Profit & Loss Statement with cash-basis totals and category breakdowns.
     */
    @Transactional(readOnly = true)
    public ProfitAndLossReportDTO getProfitAndLoss(String period, LocalDate customStart, LocalDate customEnd, String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        validateReportLevel(period, customStart, customEnd, userEmail);

        DateRange range = resolveRange(period, customStart, customEnd);
        UUID businessId = business.getId();
        String currency = resolveCurrency(business);

        BigDecimal revenue = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "INCOME", range.startDate, range.endDate
        );
        BigDecimal expenses = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "EXPENSE", range.startDate, range.endDate
        );
        BigDecimal netOperatingIncome = revenue.subtract(expenses);

        double margin = 0.0;
        if (revenue.compareTo(BigDecimal.ZERO) > 0) {
            margin = netOperatingIncome.divide(revenue, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).doubleValue();
        }

        List<CategoryShareDTO> revenueBreakdown = fetchCategoryShares(businessId, "INCOME", range.startDate, range.endDate, revenue);
        List<CategoryShareDTO> expenseBreakdown = fetchCategoryShares(businessId, "EXPENSE", range.startDate, range.endDate, expenses);

        ProfitAndLossReportDTO dto = new ProfitAndLossReportDTO();
        dto.setPeriod(range.label);
        dto.setCurrency(currency);
        dto.setStartDate(range.startDate.atStartOfDay().toInstant(java.time.ZoneOffset.UTC));
        dto.setEndDate(range.endDate.atTime(23, 59, 59).toInstant(java.time.ZoneOffset.UTC));
        dto.setTotalRevenue(revenue);
        dto.setTotalExpenses(expenses);
        dto.setGrossProfit(revenue);
        dto.setNetOperatingIncome(netOperatingIncome);
        dto.setProfitMarginPct(margin);
        dto.setRevenueBreakdown(revenueBreakdown);
        dto.setExpenseBreakdown(expenseBreakdown);

        return dto;
    }

    /**
     * Build Cash Flow Statement with inflows, outflows, and monthly trend.
     */
    @Transactional(readOnly = true)
    public CashFlowReportDTO getCashFlow(String period, LocalDate customStart, LocalDate customEnd, String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        validateReportLevel(period, customStart, customEnd, userEmail);

        DateRange range = resolveRange(period, customStart, customEnd);
        UUID businessId = business.getId();
        String currency = resolveCurrency(business);

        BigDecimal inflow = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "INCOME", range.startDate, range.endDate
        );
        BigDecimal outflow = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                businessId, "EXPENSE", range.startDate, range.endDate
        );
        BigDecimal net = inflow.subtract(outflow);

        // Trailing 6 months cash flow trend
        List<MonthlyCashFlowDTO> monthlyTrend = new ArrayList<>();
        YearMonth currentYm = YearMonth.now();
        for (int i = 5; i >= 0; i--) {
            YearMonth ym = currentYm.minusMonths(i);
            LocalDate start = ym.atDay(1);
            LocalDate end = ym.atEndOfMonth();
            BigDecimal mInflow = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                    businessId, "INCOME", start, end
            );
            BigDecimal mOutflow = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                    businessId, "EXPENSE", start, end
            );
            monthlyTrend.add(new MonthlyCashFlowDTO(ym.toString(), mInflow, mOutflow, mInflow.subtract(mOutflow)));
        }

        CashFlowReportDTO dto = new CashFlowReportDTO();
        dto.setPeriod(range.label);
        dto.setCurrency(currency);
        dto.setStartDate(range.startDate.atStartOfDay().toInstant(java.time.ZoneOffset.UTC));
        dto.setEndDate(range.endDate.atTime(23, 59, 59).toInstant(java.time.ZoneOffset.UTC));
        dto.setCashInflow(inflow);
        dto.setCashOutflow(outflow);
        dto.setNetCashChange(net);
        dto.setMonthlyTrend(monthlyTrend);

        return dto;
    }

    /**
     * Period Comparison Report (e.g. This Month vs Last Month).
     */
    @Transactional(readOnly = true)
    public ComparisonReportDTO getComparison(String primaryPeriod, String comparisonPeriod, String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        // Period comparison requires advanced report level (Plus or Pro)
        var snapshot = entitlementService.getEntitlementsSnapshot(userEmail);
        String level = String.valueOf(snapshot.getEntitlements().getOrDefault("reports.level", "basic"));
        if ("basic".equalsIgnoreCase(level)) {
            throw new PlanLimitReachedException("reports.level", 0, 0, "plus");
        }

        DateRange pRange = resolveRange(primaryPeriod, null, null);
        DateRange cRange = resolveRange(comparisonPeriod, null, null);
        UUID businessId = business.getId();
        String currency = resolveCurrency(business);

        BigDecimal pRev = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(businessId, "INCOME", pRange.startDate, pRange.endDate);
        BigDecimal pExp = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(businessId, "EXPENSE", pRange.startDate, pRange.endDate);
        BigDecimal pNet = pRev.subtract(pExp);

        BigDecimal cRev = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(businessId, "INCOME", cRange.startDate, cRange.endDate);
        BigDecimal cExp = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(businessId, "EXPENSE", cRange.startDate, cRange.endDate);
        BigDecimal cNet = cRev.subtract(cExp);

        ComparisonReportDTO dto = new ComparisonReportDTO();
        dto.setCurrency(currency);
        dto.setPrimaryPeriodLabel(pRange.label);
        dto.setPrimaryRevenue(pRev);
        dto.setPrimaryExpenses(pExp);
        dto.setPrimaryNetIncome(pNet);

        dto.setComparisonPeriodLabel(cRange.label);
        dto.setComparisonRevenue(cRev);
        dto.setComparisonExpenses(cExp);
        dto.setComparisonNetIncome(cNet);

        dto.setRevenueDifference(pRev.subtract(cRev));
        dto.setRevenueDifferencePct(calcPctChange(pRev, cRev));

        dto.setExpensesDifference(pExp.subtract(cExp));
        dto.setExpensesDifferencePct(calcPctChange(pExp, cExp));

        dto.setNetIncomeDifference(pNet.subtract(cNet));
        dto.setNetIncomeDifferencePct(calcPctChange(pNet, cNet));

        return dto;
    }

    /**
     * Export Profit & Loss Report as CSV. Consumes 1 export quota unit.
     */
    @Transactional
    public byte[] exportCsv(String period, LocalDate customStart, LocalDate customEnd, String userEmail) {
        // Enforce & consume monthly export quota
        entitlementService.consume(userEmail, "export.per_month", 1);

        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        ProfitAndLossReportDTO pnl = getProfitAndLoss(period, customStart, customEnd, userEmail);
        DateRange range = resolveRange(period, customStart, customEnd);

        List<Transaction> transactions = transactionRepository.findCompletedTransactionsForReport(
                business.getId(), range.startDate, range.endDate
        );

        return csvReportExporter.generateProfitAndLossCsv(business, pnl, transactions);
    }

    /**
     * Export Profit & Loss Report as PDF. Consumes 1 export quota unit.
     */
    @Transactional
    public byte[] exportPdf(String period, LocalDate customStart, LocalDate customEnd, String userEmail) {
        // Enforce & consume monthly export quota
        entitlementService.consume(userEmail, "export.per_month", 1);

        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        ProfitAndLossReportDTO pnl = getProfitAndLoss(period, customStart, customEnd, userEmail);

        return pdfReportExporter.generateProfitAndLossPdf(business, pnl);
    }

    // ── Helper Validation & Date Resolution ─────────────────────────

    private void validateReportLevel(String period, LocalDate customStart, LocalDate customEnd, String userEmail) {
        var snapshot = entitlementService.getEntitlementsSnapshot(userEmail);
        String level = String.valueOf(snapshot.getEntitlements().getOrDefault("reports.level", "basic"));

        boolean isCustom = (customStart != null && customEnd != null) || "custom".equalsIgnoreCase(period);
        boolean isYearly = "year".equalsIgnoreCase(period) || "this_year".equalsIgnoreCase(period) || "last_year".equalsIgnoreCase(period);

        if (isCustom && !"custom".equalsIgnoreCase(level)) {
            throw new PlanLimitReachedException("reports.level", 0, 0, "pro");
        }

        if (isYearly && "basic".equalsIgnoreCase(level)) {
            throw new PlanLimitReachedException("reports.level", 0, 0, "plus");
        }
    }

    private DateRange resolveRange(String period, LocalDate customStart, LocalDate customEnd) {
        LocalDate today = LocalDate.now();
        if (customStart != null && customEnd != null) {
            return new DateRange(customStart, customEnd, customStart + " to " + customEnd);
        }

        if (period == null || period.isBlank()) {
            period = "this_month";
        }

        return switch (period.toLowerCase()) {
            case "last_month" -> {
                YearMonth lm = YearMonth.now().minusMonths(1);
                yield new DateRange(lm.atDay(1), lm.atEndOfMonth(), lm.toString());
            }
            case "this_quarter" -> {
                int currentQuarter = (today.getMonthValue() - 1) / 3 + 1;
                LocalDate start = LocalDate.of(today.getYear(), (currentQuarter - 1) * 3 + 1, 1);
                LocalDate end = start.plusMonths(3).minusDays(1);
                yield new DateRange(start, end, "Q" + currentQuarter + " " + today.getYear());
            }
            case "this_year", "year" -> {
                LocalDate start = LocalDate.of(today.getYear(), 1, 1);
                LocalDate end = LocalDate.of(today.getYear(), 12, 31);
                yield new DateRange(start, end, String.valueOf(today.getYear()));
            }
            case "last_year" -> {
                int lastYr = today.getYear() - 1;
                yield new DateRange(LocalDate.of(lastYr, 1, 1), LocalDate.of(lastYr, 12, 31), String.valueOf(lastYr));
            }
            default -> { // this_month
                YearMonth tm = YearMonth.now();
                yield new DateRange(tm.atDay(1), tm.atEndOfMonth(), tm.toString());
            }
        };
    }

    private List<CategoryShareDTO> fetchCategoryShares(UUID businessId, String type, LocalDate start, LocalDate end, BigDecimal total) {
        List<Object[]> rawList = transactionRepository.findCategoryBreakdownByType(businessId, type, start, end);
        List<CategoryShareDTO> shares = new ArrayList<>();

        for (Object[] row : rawList) {
            String name = (String) row[0];
            BigDecimal amount = (BigDecimal) row[2];
            double pct = 0.0;
            if (total != null && total.compareTo(BigDecimal.ZERO) > 0) {
                pct = amount.divide(total, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100)).doubleValue();
            }
            shares.add(new CategoryShareDTO(name, amount, pct, 1));
        }
        return shares;
    }

    private String resolveCurrency(Business business) {
        return (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD";
    }

    private double calcPctChange(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.compareTo(BigDecimal.ZERO) == 0) {
            return (current != null && current.compareTo(BigDecimal.ZERO) > 0) ? 100.0 : 0.0;
        }
        return current.subtract(previous)
                .divide(previous.abs(), 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .doubleValue();
    }

    private static class DateRange {
        final LocalDate startDate;
        final LocalDate endDate;
        final String label;

        DateRange(LocalDate startDate, LocalDate endDate, String label) {
            this.startDate = startDate;
            this.endDate = endDate;
            this.label = label;
        }
    }
}
