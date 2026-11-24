package com.afab.ai.service;

import com.afab.ai.dto.AiPulseDTO;
import com.afab.ai.dto.AiPulseDTO.PulseAlert;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.receipts.repository.ReceiptRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * AFAB Pulse: Fast (<50ms) deterministic financial anomaly, leak, and burn-rate detector.
 */
@Service
public class AiPulseService {

    private final CurrentBusinessService currentBusinessService;
    private final TransactionRepository transactionRepository;
    private final BudgetService budgetService;
    private final InvoiceRepository invoiceRepository;
    private final ReceiptRepository receiptRepository;

    public AiPulseService(
            CurrentBusinessService currentBusinessService,
            TransactionRepository transactionRepository,
            BudgetService budgetService,
            InvoiceRepository invoiceRepository,
            ReceiptRepository receiptRepository
    ) {
        this.currentBusinessService = currentBusinessService;
        this.transactionRepository = transactionRepository;
        this.budgetService = budgetService;
        this.invoiceRepository = invoiceRepository;
        this.receiptRepository = receiptRepository;
    }

    @Transactional(readOnly = true)
    public AiPulseDTO getPulse(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return buildPulseForBusiness(business);
    }

    @Transactional(readOnly = true)
    public AiPulseDTO buildPulseForBusiness(Business business) {
        UUID bizId = business.getId();
        String currency = business.getCurrency() != null && !business.getCurrency().isBlank()
                ? business.getCurrency() : "USD";
        LocalDate today = LocalDate.now();
        YearMonth ym = YearMonth.from(today);
        LocalDate monthStart = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        BigDecimal monthRev = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "INCOME", monthStart, monthEnd));
        BigDecimal monthExp = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "EXPENSE", monthStart, monthEnd));
        BigDecimal monthNet = monthRev.subtract(monthExp);

        List<PulseAlert> alerts = new ArrayList<>();

        // 1. Category Spending Spikes (>30% above 3-month trailing average)
        LocalDate trailStart = ym.minusMonths(3).atDay(1);
        LocalDate trailEnd = ym.minusMonths(1).atEndOfMonth();
        List<Object[]> currentCats = transactionRepository.findCategoryBreakdownByType(bizId, "EXPENSE", monthStart, today);
        List<Object[]> trailingCats = transactionRepository.findCategoryBreakdownByType(bizId, "EXPENSE", trailStart, trailEnd);
        Map<String, BigDecimal> trailingAvgByCat = new HashMap<>();
        if (trailingCats != null) {
            for (Object[] row : trailingCats) {
                String cat = String.valueOf(row[0]);
                BigDecimal sum3m = row[2] instanceof BigDecimal bd ? bd : BigDecimal.ZERO;
                trailingAvgByCat.put(cat, sum3m.divide(BigDecimal.valueOf(3), 2, RoundingMode.HALF_UP));
            }
        }
        if (currentCats != null) {
            for (Object[] row : currentCats) {
                String cat = String.valueOf(row[0]);
                BigDecimal currAmt = row[2] instanceof BigDecimal bd ? bd : BigDecimal.ZERO;
                BigDecimal avgAmt = trailingAvgByCat.getOrDefault(cat, BigDecimal.ZERO);
                if (avgAmt.compareTo(new BigDecimal("25")) >= 0 && currAmt.compareTo(avgAmt) > 0) {
                    BigDecimal pctUp = currAmt.subtract(avgAmt)
                            .divide(avgAmt, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(0, RoundingMode.HALF_UP);
                    if (pctUp.compareTo(new BigDecimal("30")) >= 0 && currAmt.subtract(avgAmt).compareTo(new BigDecimal("30")) >= 0) {
                        String sev = pctUp.compareTo(new BigDecimal("60")) >= 0 ? "HIGH" : "MEDIUM";
                        alerts.add(new PulseAlert(
                                "spike-" + cat.toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9]", "-"),
                                "SPENDING_SPIKE",
                                sev,
                                cat + " spend up " + pctUp.toPlainString() + "% vs avg",
                                "Spent " + currAmt.setScale(2, RoundingMode.HALF_UP) + " " + currency
                                        + " this month vs " + avgAmt + " " + currency + " 3-month average.",
                                currAmt,
                                currency,
                                "Analyze Spike",
                                "Analyze why my " + cat + " spending jumped " + pctUp.toPlainString() + "% this month compared to the last 3 months.",
                                "/dashboard/expenses"
                        ));
                    }
                }
            }
        }

        // 2. Potential Duplicate Expenses within 3 days
        List<Transaction> recentExpenses = transactionRepository.searchTransactionsWithCategory(
                bizId, "EXPENSE", today.minusDays(30), today, null, PageRequest.of(0, 60)
        );
        Set<String> flaggedDupKeys = new HashSet<>();
        for (int i = 0; i < recentExpenses.size(); i++) {
            Transaction a = recentExpenses.get(i);
            if (a.getAmount() == null || a.getTransactionDate() == null || a.getDescription() == null) continue;
            for (int j = i + 1; j < recentExpenses.size(); j++) {
                Transaction b = recentExpenses.get(j);
                if (b.getAmount() == null || b.getTransactionDate() == null || b.getDescription() == null) continue;
                if (a.getAmount().compareTo(b.getAmount()) == 0
                        && Math.abs(ChronoUnit.DAYS.between(a.getTransactionDate(), b.getTransactionDate())) <= 3
                        && a.getDescription().trim().equalsIgnoreCase(b.getDescription().trim())) {
                    String dupKey = a.getDescription().trim().toLowerCase(Locale.ROOT) + "::" + a.getAmount().stripTrailingZeros().toPlainString();
                    if (flaggedDupKeys.add(dupKey)) {
                        alerts.add(new PulseAlert(
                                "dup-" + a.getId().toString().substring(0, 8),
                                "DUPLICATE_EXPENSE",
                                "MEDIUM",
                                "Possible duplicate: " + a.getDescription(),
                                "Two " + a.getAmount().setScale(2, RoundingMode.HALF_UP) + " " + currency + " charges within 3 days ("
                                        + b.getTransactionDate() + " & " + a.getTransactionDate() + ").",
                                a.getAmount(),
                                currency,
                                "Check Duplicate",
                                "Search my recent transactions for '" + a.getDescription() + "' and check if there is a duplicate charge.",
                                "/dashboard/transactions"
                        ));
                    }
                }
            }
        }

        // 3. Budget Burn-Rate Velocity
        BudgetSummaryDTO budgets = budgetService.buildSummaryForBusiness(business, today);
        if (budgets != null && budgets.budgets() != null) {
            for (BudgetDTO b : budgets.budgets()) {
                if (b.startDate() == null || b.endDate() == null || b.budgetAmount().compareTo(BigDecimal.ZERO) <= 0) {
                    continue;
                }
                if ("OVER_BUDGET".equalsIgnoreCase(b.alertLevel())) {
                    alerts.add(new PulseAlert(
                            "budget-over-" + b.id().toString().substring(0, 8),
                            "BUDGET_BURN",
                            "HIGH",
                            "Over budget: " + b.name(),
                            "Consumed " + b.percentageConsumed().setScale(1, RoundingMode.HALF_UP) + "% (" + b.actualSpending().setScale(2, RoundingMode.HALF_UP)
                                    + " / " + b.budgetAmount().setScale(2, RoundingMode.HALF_UP) + " " + currency + ").",
                            b.overBudgetAmount(),
                            currency,
                            "Inspect Budget",
                            "Inspect the '" + b.name() + "' budget overrun and list the transactions pushing it over limit.",
                            "/dashboard/budgets"
                    ));
                } else {
                    long totalDays = Math.max(1, ChronoUnit.DAYS.between(b.startDate(), b.endDate()) + 1);
                    long elapsedDays = Math.max(0, ChronoUnit.DAYS.between(b.startDate(), today) + 1);
                    if (elapsedDays >= 3 && elapsedDays < totalDays && b.actualSpending().compareTo(BigDecimal.ZERO) > 0) {
                        BigDecimal dailyBurn = b.actualSpending().divide(BigDecimal.valueOf(elapsedDays), 4, RoundingMode.HALF_UP);
                        BigDecimal projectedSpend = dailyBurn.multiply(BigDecimal.valueOf(totalDays));
                        if (projectedSpend.compareTo(b.budgetAmount()) > 0 && dailyBurn.compareTo(BigDecimal.ZERO) > 0) {
                            int projectedFullDay = b.budgetAmount().divide(dailyBurn, 0, RoundingMode.CEILING).intValue();
                            alerts.add(new PulseAlert(
                                    "budget-vel-" + b.id().toString().substring(0, 8),
                                    "BUDGET_BURN",
                                    "MEDIUM",
                                    "Fast burn rate on " + b.name(),
                                    "At current pace (" + dailyBurn.setScale(2, RoundingMode.HALF_UP) + " " + currency
                                            + "/day), this budget hits 100% by day " + Math.min((int) totalDays, projectedFullDay) + ".",
                                    projectedSpend.setScale(2, RoundingMode.HALF_UP),
                                    currency,
                                    "Analyze Pace",
                                    "Analyze the burn rate of my '" + b.name() + "' budget and show top transactions driving it.",
                                    "/dashboard/budgets"
                            ));
                        }
                    }
                }
            }
        }

        // 4. High-Value / Recent Expenses Missing Receipts
        int missingReceiptCount = 0;
        BigDecimal missingReceiptTotal = BigDecimal.ZERO;
        List<Transaction> scanReceipts = transactionRepository.searchTransactionsWithCategory(
                bizId, "EXPENSE", today.minusDays(60), today, null, PageRequest.of(0, 40)
        );
        for (Transaction tx : scanReceipts) {
            boolean hasReceipt = (tx.getReceiptUrl() != null && !tx.getReceiptUrl().isBlank())
                    || !receiptRepository.findActiveByBusinessIdAndTransactionId(bizId, tx.getId()).isEmpty();
            if (!hasReceipt) {
                missingReceiptCount++;
                missingReceiptTotal = missingReceiptTotal.add(safe(tx.getAmount()));
            }
        }
        if (missingReceiptCount > 0) {
            alerts.add(new PulseAlert(
                    "missing-receipts",
                    "MISSING_RECEIPTS",
                    missingReceiptCount >= 5 ? "MEDIUM" : "INFO",
                    missingReceiptCount + " expense(s) missing receipts",
                    "Totaling " + missingReceiptTotal.setScale(2, RoundingMode.HALF_UP) + " " + currency + " over the last 60 days without attached proof.",
                    missingReceiptTotal.setScale(2, RoundingMode.HALF_UP),
                    currency,
                    "Review Missing",
                    "Show me all expenses missing receipts in the last 60 days.",
                    "/dashboard/transactions"
            ));
        }

        // 5. Overdue Invoice Aging
        List<Invoice> allInvoices = invoiceRepository.findAllByBusinessIdWithCustomer(bizId);
        int overdueCount = 0;
        BigDecimal overdueTotal = BigDecimal.ZERO;
        Invoice topOverdue = null;
        long topOverdueDays = 0;
        for (Invoice inv : allInvoices) {
            if (inv.computeEffectiveStatus(today) == InvoiceStatus.OVERDUE) {
                overdueCount++;
                BigDecimal out = safe(inv.getOutstandingBalance());
                overdueTotal = overdueTotal.add(out);
                long days = inv.getDueDate() != null ? Math.max(1, ChronoUnit.DAYS.between(inv.getDueDate(), today)) : 1;
                if (topOverdue == null || out.compareTo(safe(topOverdue.getOutstandingBalance())) > 0) {
                    topOverdue = inv;
                    topOverdueDays = days;
                }
            }
        }
        if (overdueCount > 0 && topOverdue != null) {
            String custName = topOverdue.getCustomer() != null ? topOverdue.getCustomer().getName() : "Customer";
            alerts.add(new PulseAlert(
                    "overdue-invoices",
                    "OVERDUE_INVOICES",
                    "HIGH",
                    overdueCount + " overdue invoice(s) (" + overdueTotal.setScale(2, RoundingMode.HALF_UP) + " " + currency + ")",
                    "Largest overdue: " + topOverdue.getInvoiceNumber() + " (" + custName + ", " + topOverdueDays + "d overdue).",
                    overdueTotal.setScale(2, RoundingMode.HALF_UP),
                    currency,
                    "Draft Reminder",
                    "Draft a polite payment reminder (Email & WhatsApp) for overdue invoice " + topOverdue.getInvoiceNumber() + ".",
                    "/dashboard/invoices"
            ));
        }

        alerts.sort(Comparator.comparingInt(a -> severityRank(a.severity())));
        List<PulseAlert> capped = alerts.stream().limit(8).toList();

        int highCount = (int) capped.stream().filter(a -> "HIGH".equals(a.severity())).count();
        int medCount = (int) capped.stream().filter(a -> "MEDIUM".equals(a.severity())).count();
        int infoCount = (int) capped.stream().filter(a -> "INFO".equals(a.severity())).count();

        return new AiPulseDTO(
                currency,
                Instant.now(),
                highCount,
                medCount,
                infoCount,
                monthRev.setScale(2, RoundingMode.HALF_UP),
                monthExp.setScale(2, RoundingMode.HALF_UP),
                monthNet.setScale(2, RoundingMode.HALF_UP),
                overdueTotal.setScale(2, RoundingMode.HALF_UP),
                overdueCount,
                missingReceiptCount,
                capped
        );
    }

    private int severityRank(String sev) {
        return switch (sev != null ? sev : "") {
            case "HIGH" -> 0;
            case "MEDIUM" -> 1;
            default -> 2;
        };
    }

    private BigDecimal safe(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }
}
