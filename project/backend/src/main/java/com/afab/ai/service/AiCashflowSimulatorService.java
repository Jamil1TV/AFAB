package com.afab.ai.service;

import com.afab.ai.dto.AiChartSpecDTO;
import com.afab.ai.dto.AiChartSpecDTO.SeriesSpec;
import com.afab.ai.dto.AiEvidenceItem;
import com.afab.business.Business;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.repository.RecurringTransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

/**
 * Deterministic BigDecimal Cashflow Forecasting & "What-If" Scenario Simulator.
 * Combines trailing 3-month completed transaction averages, active recurring commitments,
 * unpaid/overdue customer invoices, and user scenario shocks (e.g. hiring, delayed client payment).
 */
@Service
public class AiCashflowSimulatorService {

    public record SimulationResult(
            Map<String, Object> payload,
            AiChartSpecDTO chart,
            AiEvidenceItem evidence
    ) {}

    private final TransactionRepository transactionRepository;
    private final RecurringTransactionRepository recurringRepository;
    private final InvoiceRepository invoiceRepository;

    public AiCashflowSimulatorService(
            TransactionRepository transactionRepository,
            RecurringTransactionRepository recurringRepository,
            InvoiceRepository invoiceRepository
    ) {
        this.transactionRepository = transactionRepository;
        this.recurringRepository = recurringRepository;
        this.invoiceRepository = invoiceRepository;
    }

    public SimulationResult simulate(Business business, Map<String, Object> args) {
        UUID bizId = business.getId();
        String currency = business.getCurrency() != null && !business.getCurrency().isBlank()
                ? business.getCurrency() : "USD";
        LocalDate today = LocalDate.now();
        YearMonth currentYm = YearMonth.from(today);

        int months = intArg(args, "months", 6, 1, 12);
        BigDecimal extraMonthlyExpense = decimalArg(args, "extraMonthlyExpense", BigDecimal.ZERO).max(BigDecimal.ZERO);
        BigDecimal extraMonthlyRevenue = decimalArg(args, "extraMonthlyRevenue", BigDecimal.ZERO).max(BigDecimal.ZERO);
        BigDecimal oneTimeExpense = decimalArg(args, "oneTimeExpense", BigDecimal.ZERO).max(BigDecimal.ZERO);
        int oneTimeMonth = intArg(args, "oneTimeExpenseMonth", 1, 1, months);
        BigDecimal revenueChangePct = decimalArg(args, "revenueChangePct", BigDecimal.ZERO);
        String delayedCustomer = stringArg(args, "delayedCustomerName", null);
        int delayDays = intArg(args, "delayedCustomerPaymentDays", 0, 0, 180);

        // 1. Trailing 3 complete months average revenue & expense
        YearMonth histStartYm = currentYm.minusMonths(3);
        YearMonth histEndYm = currentYm.minusMonths(1);
        BigDecimal histRev3m = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                bizId, "INCOME", histStartYm.atDay(1), histEndYm.atEndOfMonth()
        ));
        BigDecimal histExp3m = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                bizId, "EXPENSE", histStartYm.atDay(1), histEndYm.atEndOfMonth()
        ));
        BigDecimal avgMonthlyRev = histRev3m.divide(BigDecimal.valueOf(3), 2, RoundingMode.HALF_UP);
        BigDecimal avgMonthlyExp = histExp3m.divide(BigDecimal.valueOf(3), 2, RoundingMode.HALF_UP);

        // 2. Active recurring monthly commitments (normalized to monthly equivalents)
        List<RecurringTransaction> recurringRules = recurringRepository.findAllByBusinessId(bizId);
        BigDecimal recurringMonthlyIn = BigDecimal.ZERO;
        BigDecimal recurringMonthlyOut = BigDecimal.ZERO;
        for (RecurringTransaction r : recurringRules) {
            if (!r.isActive() || r.getAmount() == null) continue;
            BigDecimal monthlyEq = toMonthlyEquivalent(r.getAmount(), r.getFrequency().name());
            if ("INCOME".equalsIgnoreCase(r.getType())) {
                recurringMonthlyIn = recurringMonthlyIn.add(monthlyEq);
            } else {
                recurringMonthlyOut = recurringMonthlyOut.add(monthlyEq);
            }
        }

        // Conservative monthly baseline takes max(trailing average, active recurring obligation)
        BigDecimal baseRecurringRevenue = avgMonthlyRev.max(recurringMonthlyIn).setScale(2, RoundingMode.HALF_UP);
        BigDecimal baseRecurringExpense = avgMonthlyExp.max(recurringMonthlyOut).setScale(2, RoundingMode.HALF_UP);

        // 3. Bucket unpaid/partially-paid invoice receivables by expected due month
        List<Invoice> allInvoices = invoiceRepository.findAllByBusinessIdWithCustomer(bizId);
        Map<YearMonth, BigDecimal> baselineInvoiceInflows = new HashMap<>();
        Map<YearMonth, BigDecimal> scenarioInvoiceInflows = new HashMap<>();
        BigDecimal delayedInvoiceAmount = BigDecimal.ZERO;

        for (Invoice inv : allInvoices) {
            InvoiceStatus eff = inv.computeEffectiveStatus(today);
            if (eff == InvoiceStatus.CANCELLED || eff == InvoiceStatus.DRAFT || eff == InvoiceStatus.PAID) {
                continue;
            }
            BigDecimal outstanding = safe(inv.getOutstandingBalance());
            if (outstanding.compareTo(BigDecimal.ZERO) <= 0) continue;

            LocalDate due = inv.getDueDate() != null ? inv.getDueDate() : today;
            YearMonth baseYm = due.isBefore(today) ? currentYm : YearMonth.from(due);
            baselineInvoiceInflows.merge(baseYm, outstanding, BigDecimal::add);

            LocalDate shiftedDue = due;
            String custName = inv.getCustomer() != null ? inv.getCustomer().getName() : "";
            boolean matchesDelay = delayDays > 0 && delayedCustomer != null && !delayedCustomer.isBlank()
                    && custName.toLowerCase(Locale.ROOT).contains(delayedCustomer.toLowerCase(Locale.ROOT));
            if (matchesDelay) {
                shiftedDue = (due.isBefore(today) ? today : due).plusDays(delayDays);
                delayedInvoiceAmount = delayedInvoiceAmount.add(outstanding);
            } else if (due.isBefore(today)) {
                shiftedDue = today;
            }
            YearMonth scenYm = YearMonth.from(shiftedDue);
            scenarioInvoiceInflows.merge(scenYm, outstanding, BigDecimal::add);
        }

        // 4. Month-by-month deterministic projection
        BigDecimal revMultiplier = BigDecimal.ONE.add(
                revenueChangePct.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP)
        ).max(BigDecimal.ZERO);

        List<Map<String, Object>> projectionRows = new ArrayList<>();
        List<Map<String, Object>> chartRows = new ArrayList<>();
        BigDecimal cumulativeBaseline = BigDecimal.ZERO;
        BigDecimal cumulativeScenario = BigDecimal.ZERO;
        BigDecimal minCumulativeScenario = null;

        for (int i = 0; i < months; i++) {
            YearMonth ym = currentYm.plusMonths(i);
            String label = ym.toString();

            BigDecimal baseInflow = baseRecurringRevenue.add(baselineInvoiceInflows.getOrDefault(ym, BigDecimal.ZERO))
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal baseOutflow = baseRecurringExpense.setScale(2, RoundingMode.HALF_UP);
            BigDecimal baseNet = baseInflow.subtract(baseOutflow).setScale(2, RoundingMode.HALF_UP);

            BigDecimal scenBaseIn = baseRecurringRevenue.multiply(revMultiplier)
                    .add(extraMonthlyRevenue)
                    .add(scenarioInvoiceInflows.getOrDefault(ym, BigDecimal.ZERO))
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal oneTimeThisMonth = (i + 1 == oneTimeMonth) ? oneTimeExpense : BigDecimal.ZERO;
            BigDecimal scenOutflow = baseRecurringExpense.add(extraMonthlyExpense).add(oneTimeThisMonth)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal scenNet = scenBaseIn.subtract(scenOutflow).setScale(2, RoundingMode.HALF_UP);

            cumulativeBaseline = cumulativeBaseline.add(baseNet).setScale(2, RoundingMode.HALF_UP);
            cumulativeScenario = cumulativeScenario.add(scenNet).setScale(2, RoundingMode.HALF_UP);
            if (minCumulativeScenario == null || cumulativeScenario.compareTo(minCumulativeScenario) < 0) {
                minCumulativeScenario = cumulativeScenario;
            }

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("month", label);
            row.put("baselineInflow", baseInflow);
            row.put("baselineOutflow", baseOutflow);
            row.put("baselineNet", baseNet);
            row.put("scenarioInflow", scenBaseIn);
            row.put("scenarioOutflow", scenOutflow);
            row.put("scenarioNet", scenNet);
            row.put("cumulativeBaseline", cumulativeBaseline);
            row.put("cumulativeScenario", cumulativeScenario);
            projectionRows.add(row);

            Map<String, Object> chartPoint = new LinkedHashMap<>();
            chartPoint.put("month", label);
            chartPoint.put("cumulativeBaseline", cumulativeBaseline);
            chartPoint.put("cumulativeScenario", cumulativeScenario);
            chartRows.add(chartPoint);
        }

        if (minCumulativeScenario == null) minCumulativeScenario = BigDecimal.ZERO;
        String verdict;
        if (minCumulativeScenario.compareTo(BigDecimal.ZERO) < 0) {
            verdict = "DEFICIT_RISK";
        } else if (cumulativeScenario.compareTo(cumulativeBaseline.multiply(new BigDecimal("0.4"))) < 0) {
            verdict = "TIGHT";
        } else {
            verdict = "AFFORDABLE";
        }

        AiChartSpecDTO chart = new AiChartSpecDTO(
                "forecast-" + UUID.randomUUID().toString().substring(0, 8),
                "area",
                months + "-Month Cashflow Projection",
                "Baseline vs. What-If Cumulative Net Cashflow (" + currency + ")",
                currency,
                "month",
                List.of(
                        new SeriesSpec("cumulativeBaseline", "Baseline Cumulative", "sky"),
                        new SeriesSpec("cumulativeScenario", "Scenario Cumulative", "primary")
                ),
                chartRows
        );

        AiEvidenceItem evidence = new AiEvidenceItem(
                "REPORT",
                "forecast-" + currentYm,
                months + "-Month Cashflow Simulation",
                "Verdict: " + verdict + " • Net scenario: " + cumulativeScenario.toPlainString() + " " + currency,
                cumulativeScenario,
                currency,
                currentYm.plusMonths(months - 1).toString(),
                "/dashboard/reports"
        );

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("currency", currency);
        payload.put("horizonMonths", months);
        payload.put("baselineMonthlyRevenueAvg", avgMonthlyRev);
        payload.put("baselineMonthlyExpenseAvg", avgMonthlyExp);
        payload.put("activeRecurringMonthlyRevenue", recurringMonthlyIn.setScale(2, RoundingMode.HALF_UP));
        payload.put("activeRecurringMonthlyExpense", recurringMonthlyOut.setScale(2, RoundingMode.HALF_UP));
        payload.put("delayedInvoiceAmount", delayedInvoiceAmount.setScale(2, RoundingMode.HALF_UP));
        payload.put("endingCumulativeBaseline", cumulativeBaseline);
        payload.put("endingCumulativeScenario", cumulativeScenario);
        payload.put("lowestCumulativePoint", minCumulativeScenario);
        payload.put("netScenarioImpact", cumulativeScenario.subtract(cumulativeBaseline).setScale(2, RoundingMode.HALF_UP));
        payload.put("verdict", verdict);
        payload.put("monthlyBreakdown", projectionRows);

        return new SimulationResult(payload, chart, evidence);
    }

    private BigDecimal toMonthlyEquivalent(BigDecimal amount, String frequency) {
        if (frequency == null) return amount;
        return switch (frequency.toUpperCase(Locale.ROOT)) {
            case "DAILY" -> amount.multiply(BigDecimal.valueOf(30));
            case "WEEKLY" -> amount.multiply(new BigDecimal("4.3333"));
            case "BIWEEKLY" -> amount.multiply(new BigDecimal("2.1667"));
            case "QUARTERLY" -> amount.divide(BigDecimal.valueOf(3), 4, RoundingMode.HALF_UP);
            case "YEARLY", "ANNUAL" -> amount.divide(BigDecimal.valueOf(12), 4, RoundingMode.HALF_UP);
            default -> amount;
        };
    }

    private BigDecimal safe(BigDecimal val) {
        return val != null ? val : BigDecimal.ZERO;
    }

    private String stringArg(Map<String, Object> args, String key, String def) {
        if (args == null) return def;
        Object val = args.get(key);
        return val != null ? String.valueOf(val) : def;
    }

    private int intArg(Map<String, Object> args, String key, int def, int min, int max) {
        if (args == null || !args.containsKey(key) || args.get(key) == null) return def;
        try {
            int v = args.get(key) instanceof Number n ? n.intValue() : Integer.parseInt(String.valueOf(args.get(key)).trim());
            return Math.min(max, Math.max(min, v));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    private BigDecimal decimalArg(Map<String, Object> args, String key, BigDecimal def) {
        if (args == null || !args.containsKey(key) || args.get(key) == null) return def;
        try {
            return new BigDecimal(String.valueOf(args.get(key)).trim());
        } catch (Exception e) {
            return def;
        }
    }
}
