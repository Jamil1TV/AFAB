package com.afab.ai.tools;

import com.afab.ai.domain.AiToolAudit;
import com.afab.ai.domain.AiToolAuditRepository;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.dto.AiEvidenceItem;
import com.afab.ai.gateway.AiModelGateway.GatewayToolDefinition;
import com.afab.ai.rag.AiVectorRepository;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.customers.service.CustomerFinancialMetricsProvider;
import com.afab.customers.service.CustomerFinancialMetricsProvider.CustomerMetrics;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.repository.RecurringTransactionRepository;
import com.afab.user.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

/**
 * Narrow, read-only financial tool catalog for AFAB Copilot.
 * - Zero raw SQL generation.
 * - Never accepts businessId from the model (always bound server-side).
 * - All math uses BigDecimal and established Java finance services.
 * - Audits every tool call without persisting secrets or raw prompt bodies.
 */
@Service
public class AiFinanceToolRegistry {

    private static final Logger log = LoggerFactory.getLogger(AiFinanceToolRegistry.class);

    public record ToolExecutionResult(
            String toolName,
            String jsonResult,
            List<AiEvidenceItem> evidence
    ) {}

    private final FinanceStatsService financeStatsService;
    private final TransactionRepository transactionRepository;
    private final InvoiceRepository invoiceRepository;
    private final CustomerRepository customerRepository;
    private final CustomerFinancialMetricsProvider customerMetricsProvider;
    private final BudgetService budgetService;
    private final RecurringTransactionRepository recurringRepository;
    private final ReceiptRepository receiptRepository;
    private final BusinessMemoryRepository memoryRepository;
    private final AiVectorRepository vectorRepository;
    private final AiToolAuditRepository toolAuditRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    public AiFinanceToolRegistry(
            FinanceStatsService financeStatsService,
            TransactionRepository transactionRepository,
            InvoiceRepository invoiceRepository,
            CustomerRepository customerRepository,
            @Autowired(required = false) CustomerFinancialMetricsProvider customerMetricsProvider,
            BudgetService budgetService,
            RecurringTransactionRepository recurringRepository,
            ReceiptRepository receiptRepository,
            BusinessMemoryRepository memoryRepository,
            AiVectorRepository vectorRepository,
            AiToolAuditRepository toolAuditRepository
    ) {
        this.financeStatsService = financeStatsService;
        this.transactionRepository = transactionRepository;
        this.invoiceRepository = invoiceRepository;
        this.customerRepository = customerRepository;
        this.customerMetricsProvider = customerMetricsProvider;
        this.budgetService = budgetService;
        this.recurringRepository = recurringRepository;
        this.receiptRepository = receiptRepository;
        this.memoryRepository = memoryRepository;
        this.vectorRepository = vectorRepository;
        this.toolAuditRepository = toolAuditRepository;
    }

    public List<GatewayToolDefinition> getToolDefinitions() {
        return List.of(
                new GatewayToolDefinition(
                        "get_business_summary",
                        "Get exact revenue, expenses, net profit, profit margin, and deltas for the active business.",
                        schema(Map.of(
                                "period", Map.of("type", "string", "enum", List.of("week", "month", "quarter", "year"),
                                        "description", "Reporting window: week, month, quarter, or year")
                        ), List.of("period"))
                ),
                new GatewayToolDefinition(
                        "compare_periods",
                        "Compare deterministic revenue, expenses, and net profit between two ISO date ranges (YYYY-MM-DD).",
                        schema(Map.of(
                                "fromA", Map.of("type", "string", "description", "Start date of period A (YYYY-MM-DD)"),
                                "toA", Map.of("type", "string", "description", "End date of period A (YYYY-MM-DD)"),
                                "fromB", Map.of("type", "string", "description", "Start date of period B / baseline (YYYY-MM-DD)"),
                                "toB", Map.of("type", "string", "description", "End date of period B / baseline (YYYY-MM-DD)")
                        ), List.of("fromA", "toA", "fromB", "toB"))
                ),
                new GatewayToolDefinition(
                        "get_category_breakdown",
                        "Get category totals and percentage shares for EXPENSE or INCOME in an optional date range.",
                        schema(Map.of(
                                "type", Map.of("type", "string", "enum", List.of("EXPENSE", "INCOME")),
                                "fromDate", Map.of("type", "string", "description", "Optional YYYY-MM-DD start date"),
                                "toDate", Map.of("type", "string", "description", "Optional YYYY-MM-DD end date")
                        ), List.of("type"))
                ),
                new GatewayToolDefinition(
                        "search_transactions",
                        "Search ledger transactions by type, keyword, date range, or missing receipt status.",
                        schema(Map.of(
                                "type", Map.of("type", "string", "enum", List.of("ALL", "EXPENSE", "INCOME")),
                                "search", Map.of("type", "string", "description", "Optional keyword match on description"),
                                "fromDate", Map.of("type", "string", "description", "Optional YYYY-MM-DD start date"),
                                "toDate", Map.of("type", "string", "description", "Optional YYYY-MM-DD end date"),
                                "missingReceiptOnly", Map.of("type", "boolean", "description", "Set true to list transactions lacking attached receipts"),
                                "limit", Map.of("type", "integer", "description", "Max rows (1 to 25)")
                        ), List.of())
                ),
                new GatewayToolDefinition(
                        "get_invoices_overview",
                        "Get real invoices summary, unpaid/overdue totals, and matching invoice list.",
                        schema(Map.of(
                                "status", Map.of("type", "string", "enum", List.of("ALL", "DRAFT", "UNPAID", "PARTIALLY_PAID", "PAID", "OVERDUE", "CANCELLED")),
                                "overdueOnly", Map.of("type", "boolean"),
                                "customerSearch", Map.of("type", "string"),
                                "limit", Map.of("type", "integer")
                        ), List.of())
                ),
                new GatewayToolDefinition(
                        "get_customers_overview",
                        "Get customers list with real paid revenue, outstanding balance, and invoice counts.",
                        schema(Map.of(
                                "search", Map.of("type", "string"),
                                "limit", Map.of("type", "integer")
                        ), List.of())
                ),
                new GatewayToolDefinition(
                        "get_budgets_status",
                        "Get active business budgets with actual spending, remaining amount, percentage consumed, and alert levels.",
                        schema(Map.of(), List.of())
                ),
                new GatewayToolDefinition(
                        "get_recurring_commitments",
                        "Get configured recurring income and expense schedules and next execution dates.",
                        schema(Map.of(), List.of())
                ),
                new GatewayToolDefinition(
                        "get_data_coverage",
                        "Inspect which financial domains exist for this business and which domains are unavailable (e.g., live bank balances, supplier AP bills).",
                        schema(Map.of(), List.of())
                )
        );
    }

    @Transactional
    public ToolExecutionResult executeTool(
            User user,
            Business business,
            UUID conversationId,
            String toolName,
            Map<String, Object> rawArgs
    ) {
        long startNs = System.nanoTime();
        Map<String, Object> args = rawArgs != null ? rawArgs : Map.of();
        List<AiEvidenceItem> evidence = new ArrayList<>();
        String status = "OK";
        Map<String, Object> payload;

        try {
            payload = switch (toolName) {
                case "get_business_summary" -> runGetBusinessSummary(business, args, evidence);
                case "compare_periods" -> runComparePeriods(business, args);
                case "get_category_breakdown" -> runGetCategoryBreakdown(business, args, evidence);
                case "search_transactions" -> runSearchTransactions(business, args, evidence);
                case "get_invoices_overview" -> runGetInvoicesOverview(business, args, evidence);
                case "get_customers_overview" -> runGetCustomersOverview(business, args, evidence);
                case "get_budgets_status" -> runGetBudgetsStatus(business, evidence);
                case "get_recurring_commitments" -> runGetRecurringCommitments(business, evidence);
                case "get_data_coverage" -> runGetDataCoverage(business);
                default -> {
                    status = "REJECTED_UNKNOWN_TOOL";
                    yield Map.of("error", "Tool not allowed: " + toolName);
                }
            };
        } catch (IllegalArgumentException e) {
            status = "INVALID_ARGUMENTS";
            payload = Map.of("error", e.getMessage());
        } catch (Exception e) {
            log.warn("AI tool '{}' failed: {}", toolName, e.getMessage());
            status = "ERROR";
            payload = Map.of("error", "Tool execution failed cleanly.");
        }

        long durationMs = Math.max(0L, (System.nanoTime() - startNs) / 1_000_000L);
        recordAudit(user, business, conversationId, toolName, args, status, durationMs);

        String json;
        try {
            json = objectMapper.writeValueAsString(payload);
        } catch (Exception e) {
            json = "{\"error\":\"Serialization failed\"}";
        }
        return new ToolExecutionResult(toolName, json, List.copyOf(evidence));
    }

    private Map<String, Object> runGetBusinessSummary(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence
    ) {
        String period = stringArg(args, "period", "month").toLowerCase(Locale.ROOT);
        String currency = resolveCurrency(business);

        if ("quarter".equals(period)) {
            LocalDate today = LocalDate.now();
            int qStartMonth = ((today.getMonthValue() - 1) / 3) * 3 + 1;
            LocalDate start = LocalDate.of(today.getYear(), qStartMonth, 1);
            LocalDate end = start.plusMonths(3).minusDays(1);
            LocalDate prevStart = start.minusMonths(3);
            LocalDate prevEnd = start.minusDays(1);

            BigDecimal rev = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "INCOME", start, end));
            BigDecimal exp = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "EXPENSE", start, end));
            BigDecimal net = rev.subtract(exp);
            BigDecimal prevRev = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "INCOME", prevStart, prevEnd));
            BigDecimal prevExp = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), "EXPENSE", prevStart, prevEnd));

            evidence.add(new AiEvidenceItem(
                    "SUMMARY", "quarter-" + start, "Quarterly P&L (" + start + " to " + end + ")",
                    "Cash-basis revenue minus expenses", net, currency, end.toString(), "/dashboard"
            ));

            Map<String, Object> res = new LinkedHashMap<>();
            res.put("period", "quarter");
            res.put("fromDate", start.toString());
            res.put("toDate", end.toString());
            res.put("currency", currency);
            res.put("revenue", rev);
            res.put("expenses", exp);
            res.put("netProfit", net);
            res.put("previousRevenue", prevRev);
            res.put("previousExpenses", prevExp);
            res.put("calculationMethod", "cash_basis_completed_root_transactions");
            return res;
        }

        String statsPeriod = switch (period) {
            case "week", "weekly" -> "week";
            case "year", "yearly" -> "year";
            default -> "month";
        };
        DashboardSummaryDTO summary = financeStatsService.buildDashboardSummary(business, statsPeriod);
        var kpi = summary.getKpiData();
        BigDecimal rev = kpi != null && kpi.getRevenue() != null && kpi.getRevenue().getRawValue() != null
                ? kpi.getRevenue().getRawValue() : BigDecimal.ZERO;
        BigDecimal exp = kpi != null && kpi.getExpenses() != null && kpi.getExpenses().getRawValue() != null
                ? kpi.getExpenses().getRawValue() : BigDecimal.ZERO;
        BigDecimal profit = kpi != null && kpi.getProfit() != null && kpi.getProfit().getRawValue() != null
                ? kpi.getProfit().getRawValue() : rev.subtract(exp);

        evidence.add(new AiEvidenceItem(
                "SUMMARY", "summary-" + statsPeriod, "Business Summary (" + statsPeriod + ")",
                "Verified cash-basis totals in " + currency, profit, currency, LocalDate.now().toString(), "/dashboard"
        ));

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("period", statsPeriod);
        res.put("businessName", business.getName());
        res.put("currency", currency);
        res.put("revenue", rev);
        res.put("revenueChange", kpi != null && kpi.getRevenue() != null ? kpi.getRevenue().getChange() : "0.0%");
        res.put("expenses", exp);
        res.put("expensesChange", kpi != null && kpi.getExpenses() != null ? kpi.getExpenses().getChange() : "0.0%");
        res.put("netProfit", profit);
        res.put("profitChange", kpi != null && kpi.getProfit() != null ? kpi.getProfit().getChange() : "0.0%");
        res.put("topExpenseCategories", summary.getExpenseCategories() != null ? summary.getExpenseCategories() : List.of());
        res.put("calculationMethod", "cash_basis_completed_root_transactions");
        return res;
    }

    private Map<String, Object> runComparePeriods(Business business, Map<String, Object> args) {
        LocalDate fromA = parseDateRequired(args, "fromA");
        LocalDate toA = parseDateRequired(args, "toA");
        LocalDate fromB = parseDateRequired(args, "fromB");
        LocalDate toB = parseDateRequired(args, "toB");
        if (fromA.isAfter(toA) || fromB.isAfter(toB)) {
            throw new IllegalArgumentException("Start date cannot be after end date.");
        }

        UUID bizId = business.getId();
        BigDecimal revA = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "INCOME", fromA, toA));
        BigDecimal expA = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "EXPENSE", fromA, toA));
        BigDecimal netA = revA.subtract(expA);

        BigDecimal revB = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "INCOME", fromB, toB));
        BigDecimal expB = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(bizId, "EXPENSE", fromB, toB));
        BigDecimal netB = revB.subtract(expB);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("currency", resolveCurrency(business));
        res.put("periodA", Map.of("from", fromA.toString(), "to", toA.toString(), "revenue", revA, "expenses", expA, "netProfit", netA));
        res.put("periodB", Map.of("from", fromB.toString(), "to", toB.toString(), "revenue", revB, "expenses", expB, "netProfit", netB));
        res.put("revenueDelta", revA.subtract(revB));
        res.put("revenueDeltaPct", pctChange(revA, revB));
        res.put("expenseDelta", expA.subtract(expB));
        res.put("expenseDeltaPct", pctChange(expA, expB));
        res.put("netProfitDelta", netA.subtract(netB));
        res.put("calculationMethod", "cash_basis_completed_root_transactions");
        return res;
    }

    private Map<String, Object> runGetCategoryBreakdown(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence
    ) {
        String type = stringArg(args, "type", "EXPENSE").toUpperCase(Locale.ROOT);
        if (!"EXPENSE".equals(type) && !"INCOME".equals(type)) {
            throw new IllegalArgumentException("Category breakdown type must be EXPENSE or INCOME.");
        }
        YearMonth ym = YearMonth.now();
        LocalDate from = parseDateOptional(args, "fromDate", ym.atDay(1));
        LocalDate to = parseDateOptional(args, "toDate", ym.atEndOfMonth());
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("fromDate cannot be after toDate.");
        }

        List<Object[]> rows = transactionRepository.findCategoryBreakdownByType(business.getId(), type, from, to);
        BigDecimal total = safe(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(business.getId(), type, from, to));
        String currency = resolveCurrency(business);

        List<Map<String, Object>> items = new ArrayList<>();
        for (Object[] row : rows) {
            String cat = String.valueOf(row[0]);
            BigDecimal amount = row[2] instanceof BigDecimal bd ? bd : BigDecimal.ZERO;
            BigDecimal sharePct = total.compareTo(BigDecimal.ZERO) > 0
                    ? amount.multiply(BigDecimal.valueOf(100)).divide(total, 1, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            items.add(Map.of("category", cat, "amount", amount, "sharePercent", sharePct));
        }

        evidence.add(new AiEvidenceItem(
                "REPORT", "cat-" + type.toLowerCase(Locale.ROOT),
                type + " Category Breakdown",
                from + " to " + to,
                total, currency, to.toString(),
                "EXPENSE".equals(type) ? "/dashboard/expenses" : "/dashboard/revenue"
        ));

        return Map.of(
                "type", type,
                "fromDate", from.toString(),
                "toDate", to.toString(),
                "currency", currency,
                "totalAmount", total,
                "categories", items
        );
    }

    private Map<String, Object> runSearchTransactions(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence
    ) {
        String rawType = stringArg(args, "type", "ALL").toUpperCase(Locale.ROOT);
        String typeFilter = ("EXPENSE".equals(rawType) || "INCOME".equals(rawType)) ? rawType : null;
        String search = trimOrNull(stringArg(args, "search", null));
        LocalDate fromDate = parseDateOptional(args, "fromDate", null);
        LocalDate toDate = parseDateOptional(args, "toDate", null);
        boolean missingReceiptOnly = boolArg(args, "missingReceiptOnly");
        int limit = intArg(args, "limit", 12, 1, 25);

        int fetchSize = missingReceiptOnly ? 50 : limit;
        List<Transaction> matches = transactionRepository.searchTransactionsWithCategory(
                business.getId(), typeFilter, fromDate, toDate, search, PageRequest.of(0, fetchSize)
        );

        String currency = resolveCurrency(business);
        List<Map<String, Object>> rows = new ArrayList<>();
        BigDecimal totalMatched = BigDecimal.ZERO;

        for (Transaction tx : matches) {
            boolean hasReceipt = (tx.getReceiptUrl() != null && !tx.getReceiptUrl().isBlank())
                    || !receiptRepository.findActiveByBusinessIdAndTransactionId(business.getId(), tx.getId()).isEmpty();
            if (missingReceiptOnly && hasReceipt) {
                continue;
            }
            if (rows.size() >= limit) {
                continue;
            }
            BigDecimal amt = safe(tx.getAmount());
            totalMatched = totalMatched.add(amt);

            String catName = tx.getCategory() != null ? tx.getCategory().getName() : "Uncategorized";
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", tx.getId().toString());
            item.put("type", tx.getType());
            item.put("description", tx.getDescription());
            item.put("amount", amt);
            item.put("currency", tx.getCurrency() != null ? tx.getCurrency() : currency);
            item.put("originalAmount", tx.getOriginalAmount());
            item.put("originalCurrency", tx.getOriginalCurrency());
            item.put("category", catName);
            item.put("date", tx.getTransactionDate() != null ? tx.getTransactionDate().toString() : "");
            item.put("status", tx.getStatus());
            item.put("paymentMethod", tx.getPaymentMethod());
            item.put("hasReceipt", hasReceipt);
            rows.add(item);

            if (evidence.size() < 6) {
                evidence.add(new AiEvidenceItem(
                        "TRANSACTION",
                        tx.getId().toString(),
                        tx.getDescription(),
                        tx.getType() + " • " + catName + (hasReceipt ? "" : " • Missing receipt"),
                        amt,
                        tx.getCurrency() != null ? tx.getCurrency() : currency,
                        tx.getTransactionDate() != null ? tx.getTransactionDate().toString() : "",
                        "/dashboard/transactions"
                ));
            }
        }

        return Map.of(
                "currency", currency,
                "returnedCount", rows.size(),
                "sumOfReturnedRows", totalMatched,
                "missingReceiptOnly", missingReceiptOnly,
                "transactions", rows
        );
    }

    private Map<String, Object> runGetInvoicesOverview(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence
    ) {
        LocalDate today = LocalDate.now();
        String statusFilter = trimOrNull(stringArg(args, "status", "ALL"));
        boolean overdueOnly = boolArg(args, "overdueOnly");
        String customerSearch = trimOrNull(stringArg(args, "customerSearch", null));
        int limit = intArg(args, "limit", 12, 1, 25);

        List<Invoice> all = invoiceRepository.findAllByBusinessIdWithCustomer(business.getId());
        BigDecimal totalInvoiced = BigDecimal.ZERO;
        BigDecimal totalPaid = BigDecimal.ZERO;
        BigDecimal totalOutstanding = BigDecimal.ZERO;
        BigDecimal overdueTotal = BigDecimal.ZERO;
        int overdueCount = 0;

        List<Map<String, Object>> matching = new ArrayList<>();
        for (Invoice inv : all) {
            InvoiceStatus eff = inv.computeEffectiveStatus(today);
            if (eff != InvoiceStatus.CANCELLED && eff != InvoiceStatus.DRAFT) {
                totalInvoiced = totalInvoiced.add(safe(inv.getTotalAmount()));
                totalPaid = totalPaid.add(safe(inv.getPaidAmount()));
                totalOutstanding = totalOutstanding.add(safe(inv.getOutstandingBalance()));
            }
            if (eff == InvoiceStatus.OVERDUE) {
                overdueCount++;
                overdueTotal = overdueTotal.add(safe(inv.getOutstandingBalance()));
            }

            if (overdueOnly && eff != InvoiceStatus.OVERDUE) continue;
            if (statusFilter != null && !"ALL".equalsIgnoreCase(statusFilter) && !eff.name().equalsIgnoreCase(statusFilter)) continue;

            String custName = inv.getCustomer() != null ? inv.getCustomer().getName() : "Unassigned";
            if (customerSearch != null && !custName.toLowerCase(Locale.ROOT).contains(customerSearch.toLowerCase(Locale.ROOT))) {
                continue;
            }
            if (matching.size() < limit) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", inv.getId().toString());
                row.put("invoiceNumber", inv.getInvoiceNumber());
                row.put("customer", custName);
                row.put("status", eff.name());
                row.put("issueDate", inv.getIssueDate() != null ? inv.getIssueDate().toString() : "");
                row.put("dueDate", inv.getDueDate() != null ? inv.getDueDate().toString() : "");
                row.put("totalAmount", safe(inv.getTotalAmount()));
                row.put("paidAmount", safe(inv.getPaidAmount()));
                row.put("outstandingBalance", safe(inv.getOutstandingBalance()));
                row.put("currency", inv.getCurrency());
                matching.add(row);

                if (evidence.size() < 6) {
                    evidence.add(new AiEvidenceItem(
                            "INVOICE",
                            inv.getId().toString(),
                            "Invoice " + inv.getInvoiceNumber() + " (" + custName + ")",
                            eff.name() + " • Due " + inv.getDueDate(),
                            safe(inv.getOutstandingBalance()).compareTo(BigDecimal.ZERO) > 0
                                    ? safe(inv.getOutstandingBalance()) : safe(inv.getTotalAmount()),
                            inv.getCurrency(),
                            inv.getDueDate() != null ? inv.getDueDate().toString() : "",
                            "/dashboard/invoices"
                    ));
                }
            }
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("currency", resolveCurrency(business));
        res.put("totalInvoicesCount", all.size());
        res.put("totalInvoiced", totalInvoiced);
        res.put("totalPaid", totalPaid);
        res.put("totalOutstanding", totalOutstanding);
        res.put("overdueCount", overdueCount);
        res.put("overdueTotal", overdueTotal);
        res.put("invoices", matching);
        return res;
    }

    private Map<String, Object> runGetCustomersOverview(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence
    ) {
        String search = trimOrNull(stringArg(args, "search", null));
        int limit = intArg(args, "limit", 10, 1, 20);
        String currency = resolveCurrency(business);

        List<Customer> customers = customerRepository.findAllActiveByBusinessId(business.getId());
        Map<UUID, CustomerMetrics> metricsMap = customerMetricsProvider != null
                ? customerMetricsProvider.getMetricsForBusiness(business.getId())
                : Map.of();

        List<Map<String, Object>> rows = new ArrayList<>();
        for (Customer c : customers) {
            if (search != null) {
                String q = search.toLowerCase(Locale.ROOT);
                boolean matched = (c.getName() != null && c.getName().toLowerCase(Locale.ROOT).contains(q))
                        || (c.getCompanyName() != null && c.getCompanyName().toLowerCase(Locale.ROOT).contains(q))
                        || (c.getCustomerCode() != null && c.getCustomerCode().toLowerCase(Locale.ROOT).contains(q));
                if (!matched) continue;
            }
            CustomerMetrics m = metricsMap.getOrDefault(c.getId(), CustomerMetrics.empty());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id", c.getId().toString());
            item.put("customerCode", c.getCustomerCode());
            item.put("name", c.getName());
            item.put("group", c.getCustomerGroup());
            item.put("status", c.getStatus());
            item.put("paidRevenue", m.totalPaidRevenue());
            item.put("outstandingBalance", m.outstandingBalance());
            item.put("invoiceCount", m.invoiceCount());
            rows.add(item);
        }

        rows.sort((a, b) -> ((BigDecimal) b.get("paidRevenue")).compareTo((BigDecimal) a.get("paidRevenue")));
        List<Map<String, Object>> limited = rows.stream().limit(limit).toList();

        for (Map<String, Object> r : limited) {
            if (evidence.size() >= 5) break;
            evidence.add(new AiEvidenceItem(
                    "CUSTOMER",
                    (String) r.get("id"),
                    (String) r.get("name"),
                    r.get("customerCode") + " • " + r.get("invoiceCount") + " invoices",
                    (BigDecimal) r.get("paidRevenue"),
                    currency,
                    null,
                    "/dashboard/customers"
            ));
        }

        return Map.of("currency", currency, "totalCustomers", customers.size(), "customers", limited);
    }

    private Map<String, Object> runGetBudgetsStatus(Business business, List<AiEvidenceItem> evidence) {
        BudgetSummaryDTO summary = budgetService.buildSummaryForBusiness(business, LocalDate.now());
        List<Map<String, Object>> items = new ArrayList<>();
        if (summary != null && summary.budgets() != null) {
            for (BudgetDTO b : summary.budgets()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id", b.id().toString());
                row.put("name", b.name());
                row.put("category", b.categoryName() != null ? b.categoryName() : "Overall");
                row.put("periodType", b.periodType());
                row.put("startDate", b.startDate() != null ? b.startDate().toString() : "");
                row.put("endDate", b.endDate() != null ? b.endDate().toString() : "");
                row.put("limit", b.budgetAmount());
                row.put("spent", b.actualSpending());
                row.put("remaining", b.remainingAmount());
                row.put("overBudgetAmount", b.overBudgetAmount());
                row.put("percentageConsumed", b.percentageConsumed());
                row.put("alertLevel", b.alertLevel());
                items.add(row);

                if (evidence.size() < 5) {
                    evidence.add(new AiEvidenceItem(
                            "BUDGET",
                            b.id().toString(),
                            b.name(),
                            b.alertLevel() + " (" + b.percentageConsumed().stripTrailingZeros().toPlainString() + "%)",
                            b.actualSpending(),
                            b.currency(),
                            b.endDate() != null ? b.endDate().toString() : "",
                            "/dashboard/budgets"
                    ));
                }
            }
        }
        return Map.of(
                "currency", summary != null ? summary.currency() : resolveCurrency(business),
                "activeBudgetCount", summary != null ? summary.activeBudgetCount() : 0,
                "approachingCount", summary != null ? summary.approachingCount() : 0,
                "overBudgetCount", summary != null ? summary.overBudgetCount() : 0,
                "totalBudgeted", summary != null ? summary.totalBudgeted() : BigDecimal.ZERO,
                "totalSpent", summary != null ? summary.totalSpent() : BigDecimal.ZERO,
                "budgets", items
        );
    }

    private Map<String, Object> runGetRecurringCommitments(Business business, List<AiEvidenceItem> evidence) {
        List<RecurringTransaction> rules = recurringRepository.findAllByBusinessId(business.getId());
        List<Map<String, Object>> items = new ArrayList<>();
        for (RecurringTransaction r : rules) {
            String catName = r.getCategory() != null ? r.getCategory().getName() : "Uncategorized";
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", r.getId().toString());
            row.put("type", r.getType());
            row.put("description", r.getDescription());
            row.put("amount", r.getAmount());
            row.put("currency", r.getCurrency());
            row.put("frequency", r.getFrequency().name());
            row.put("nextExecutionDate", r.getNextExecutionDate() != null ? r.getNextExecutionDate().toString() : "");
            row.put("active", r.isActive());
            row.put("category", catName);
            items.add(row);

            if (evidence.size() < 5) {
                evidence.add(new AiEvidenceItem(
                        "RECURRING",
                        r.getId().toString(),
                        r.getDescription(),
                        r.getFrequency().name() + " • " + (r.isActive() ? "Active" : "Paused"),
                        r.getAmount(),
                        r.getCurrency(),
                        r.getNextExecutionDate() != null ? r.getNextExecutionDate().toString() : "",
                        "/dashboard/recurring"
                ));
            }
        }
        return Map.of("count", items.size(), "recurringTransactions", items);
    }

    private Map<String, Object> runGetDataCoverage(Business business) {
        UUID bizId = business.getId();
        long txCount = transactionRepository.countByBusinessIdAndDeletedAtIsNull(bizId);
        int invoiceCount = invoiceRepository.findAllByBusinessIdWithCustomer(bizId).size();
        int customerCount = customerRepository.findAllActiveByBusinessId(bizId).size();
        BudgetSummaryDTO budgets = budgetService.buildSummaryForBusiness(business, LocalDate.now());
        int recurringCount = recurringRepository.findAllByBusinessId(bizId).size();
        long approvedMemories = memoryRepository.countApprovedByBusinessId(bizId);
        long ragChunks = vectorRepository.countChunks(bizId);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("businessName", business.getName());
        res.put("baseCurrency", resolveCurrency(business));
        res.put("availableDomains", Map.of(
                "transactionsCount", txCount,
                "invoicesCount", invoiceCount,
                "customersCount", customerCount,
                "activeBudgetsCount", budgets != null ? budgets.activeBudgetCount() : 0,
                "recurringRulesCount", recurringCount,
                "approvedMemoriesCount", approvedMemories,
                "indexedRagChunksCount", ragChunks
        ));
        res.put("unavailableDomains", List.of("bank_account_opening_balances", "supplier_bills_accounts_payable"));
        res.put("note", "Cash-basis P&L and invoices are tracked. Real-time bank account balances and supplier accounts payable are not stored in AFAB yet.");
        return res;
    }

    private void recordAudit(
            User user,
            Business business,
            UUID conversationId,
            String toolName,
            Map<String, Object> args,
            String resultStatus,
            long durationMs
    ) {
        try {
            String serialized = objectMapper.writeValueAsString(args);
            AiToolAudit audit = new AiToolAudit();
            audit.setBusiness(business);
            audit.setUser(user);
            audit.setConversationId(conversationId);
            audit.setToolName(toolName != null && toolName.length() > 80 ? toolName.substring(0, 80) : String.valueOf(toolName));
            audit.setArgumentsHash(AiVectorRepository.sha256Hex(serialized));
            audit.setResultStatus(resultStatus);
            audit.setApprovalStatus("AUTO_READ_ONLY");
            audit.setDurationMs(durationMs);
            toolAuditRepository.save(audit);
        } catch (Exception ignored) {
            // Audit persistence failure should not mask verified read-only tool results
        }
    }

    private Map<String, Object> schema(Map<String, Object> properties, List<String> required) {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("type", "object");
        root.put("properties", properties);
        if (!required.isEmpty()) {
            root.put("required", required);
        }
        return root;
    }

    private String stringArg(Map<String, Object> args, String key, String defaultVal) {
        Object val = args.get(key);
        return val != null ? String.valueOf(val) : defaultVal;
    }

    private boolean boolArg(Map<String, Object> args, String key) {
        Object val = args.get(key);
        if (val instanceof Boolean b) return b;
        return val != null && Boolean.parseBoolean(String.valueOf(val));
    }

    private int intArg(Map<String, Object> args, String key, int defaultVal, int min, int max) {
        Object val = args.get(key);
        if (val == null) return defaultVal;
        try {
            int parsed = val instanceof Number n ? n.intValue() : Integer.parseInt(String.valueOf(val));
            return Math.min(max, Math.max(min, parsed));
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }

    private LocalDate parseDateRequired(Map<String, Object> args, String key) {
        Object val = args.get(key);
        if (val == null || String.valueOf(val).isBlank()) {
            throw new IllegalArgumentException("Date parameter '" + key + "' is required (YYYY-MM-DD).");
        }
        try {
            return LocalDate.parse(String.valueOf(val).trim());
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid ISO date for '" + key + "': expected YYYY-MM-DD.");
        }
    }

    private LocalDate parseDateOptional(Map<String, Object> args, String key, LocalDate fallback) {
        Object val = args.get(key);
        if (val == null || String.valueOf(val).isBlank()) {
            return fallback;
        }
        try {
            return LocalDate.parse(String.valueOf(val).trim());
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid ISO date for '" + key + "': expected YYYY-MM-DD.");
        }
    }

    private BigDecimal pctChange(BigDecimal current, BigDecimal previous) {
        if (previous.compareTo(BigDecimal.ZERO) == 0) {
            return current.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO : new BigDecimal("100.0");
        }
        return current.subtract(previous)
                .divide(previous.abs(), 4, RoundingMode.HALF_UP)
                .multiply(new BigDecimal("100"))
                .setScale(1, RoundingMode.HALF_UP);
    }

    private BigDecimal safe(BigDecimal value) {
        return value != null ? value : BigDecimal.ZERO;
    }

    private String resolveCurrency(Business business) {
        return business.getCurrency() != null && !business.getCurrency().isBlank() ? business.getCurrency() : "USD";
    }

    private String trimOrNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}
