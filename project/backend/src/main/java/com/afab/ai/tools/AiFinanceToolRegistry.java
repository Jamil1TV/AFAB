package com.afab.ai.tools;

import com.afab.ai.domain.AiToolAudit;
import com.afab.ai.domain.AiToolAuditRepository;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.dto.AiActionDraftDTO;
import com.afab.ai.dto.AiChartSpecDTO;
import com.afab.ai.dto.AiChartSpecDTO.SeriesSpec;
import com.afab.ai.dto.AiEvidenceItem;
import com.afab.ai.dto.AiPulseDTO;
import com.afab.ai.gateway.AiModelGateway.GatewayToolDefinition;
import com.afab.ai.rag.AiVectorRepository;
import com.afab.ai.service.AiCashflowSimulatorService;
import com.afab.ai.service.AiLanguageResolver.AiLanguage;
import com.afab.ai.service.AiPulseService;
import com.afab.ai.service.BusinessMemoryService;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.customers.service.CustomerFinancialMetricsProvider;
import com.afab.customers.service.CustomerFinancialMetricsProvider.CustomerMetrics;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.CategoryRepository;
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
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Financial intelligence tool catalog for AFAB Copilot.
 * - Read tools execute 100% deterministic BigDecimal queries scoped by server-resolved businessId.
 * - Proposal tools strictly return PENDING draft cards for 1-click user confirmation (zero auto-writes).
 */
@Service
public class AiFinanceToolRegistry {

    private static final Logger log = LoggerFactory.getLogger(AiFinanceToolRegistry.class);

    public record ToolExecutionResult(
            String toolName,
            String jsonResult,
            List<AiEvidenceItem> evidence,
            List<AiChartSpecDTO> charts,
            List<AiActionDraftDTO> actionDrafts
    ) {
        public ToolExecutionResult(String toolName, String jsonResult, List<AiEvidenceItem> evidence) {
            this(toolName, jsonResult, evidence, List.of(), List.of());
        }
    }

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
    private final CategoryRepository categoryRepository;
    private final AiCashflowSimulatorService cashflowSimulatorService;
    private final AiPulseService pulseService;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

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
        this(
                financeStatsService, transactionRepository, invoiceRepository,
                customerRepository, customerMetricsProvider, budgetService,
                recurringRepository, receiptRepository, memoryRepository,
                vectorRepository, toolAuditRepository, null, null, null
        );
    }

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
            AiToolAuditRepository toolAuditRepository,
            @Autowired(required = false) CategoryRepository categoryRepository,
            @Autowired(required = false) AiCashflowSimulatorService cashflowSimulatorService,
            @Autowired(required = false) AiPulseService pulseService
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
        this.categoryRepository = categoryRepository;
        this.cashflowSimulatorService = cashflowSimulatorService;
        this.pulseService = pulseService;
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
                ),
                new GatewayToolDefinition(
                        "simulate_cashflow_forecast",
                        "Run deterministic BigDecimal cashflow projection and what-if simulation (e.g., hiring cost, one-time spend, revenue % shift, delayed customer payments).",
                        schema(Map.of(
                                "months", Map.of("type", "integer", "description", "Forecast horizon in months (1-12, default 6)"),
                                "extraMonthlyExpense", Map.of("type", "number", "description", "Added recurring monthly expense (e.g., new hire salary)"),
                                "extraMonthlyRevenue", Map.of("type", "number", "description", "Added recurring monthly revenue"),
                                "oneTimeExpense", Map.of("type", "number", "description", "One-time purchase or expense shock"),
                                "oneTimeExpenseMonth", Map.of("type", "integer", "description", "Which future month (1-12) the one-time expense hits"),
                                "revenueChangePct", Map.of("type", "number", "description", "Percentage change in baseline revenue (e.g. -15 or +20)"),
                                "delayedCustomerName", Map.of("type", "string", "description", "Optional customer whose unpaid invoices shift later"),
                                "delayedCustomerPaymentDays", Map.of("type", "integer", "description", "Delay in days for matching customer invoices")
                        ), List.of())
                ),
                new GatewayToolDefinition(
                        "get_financial_pulse",
                        "Get proactive financial anomalies & CFO alerts: category spending spikes (>30%), potential duplicate expenses, budget burn-rate projections, missing receipts, and overdue invoice aging.",
                        schema(Map.of(), List.of())
                ),
                new GatewayToolDefinition(
                        "propose_transaction_draft",
                        "Prepare an editable Transaction Draft Card for 1-click user approval (does NOT save to database yet). Use when the user asks to log/add/record an expense or income or uploads a receipt.",
                        schema(Map.of(
                                "type", Map.of("type", "string", "enum", List.of("EXPENSE", "INCOME")),
                                "amount", Map.of("type", "number", "description", "Positive amount"),
                                "currency", Map.of("type", "string", "description", "3-letter ISO currency code"),
                                "description", Map.of("type", "string", "description", "Merchant or concise description"),
                                "transactionDate", Map.of("type", "string", "description", "YYYY-MM-DD (defaults to today if omitted)"),
                                "categoryName", Map.of("type", "string", "description", "Best matching workspace category name"),
                                "paymentMethod", Map.of("type", "string", "enum", List.of("CASH", "CARD", "BANK_TRANSFER", "OTHER")),
                                "notes", Map.of("type", "string", "description", "Optional details or receipt line items"),
                                "extractedOcrText", Map.of("type", "string", "description", "Extracted text summary if scanned from a receipt/file")
                        ), List.of("type", "amount", "description"))
                ),
                new GatewayToolDefinition(
                        "propose_invoice_draft",
                        "Prepare an editable Invoice Draft Card for 1-click user approval (does NOT create in database yet).",
                        schema(Map.of(
                                "customerName", Map.of("type", "string", "description", "Customer name to match"),
                                "issueDate", Map.of("type", "string", "description", "YYYY-MM-DD (default today)"),
                                "dueDate", Map.of("type", "string", "description", "YYYY-MM-DD (default +30 days or user specified)"),
                                "currency", Map.of("type", "string", "description", "3-letter ISO currency code"),
                                "discountAmount", Map.of("type", "number"),
                                "notes", Map.of("type", "string"),
                                "items", Map.of(
                                        "type", "array",
                                        "description", "Line items with description, quantity, unitPrice, taxRate"
                                )
                        ), List.of("items"))
                ),
                new GatewayToolDefinition(
                        "propose_budget_draft",
                        "Prepare an editable Budget Draft Card for 1-click user approval (does NOT save yet).",
                        schema(Map.of(
                                "name", Map.of("type", "string"),
                                "amount", Map.of("type", "number"),
                                "categoryName", Map.of("type", "string", "description", "Optional expense category name; omit for overall budget"),
                                "periodType", Map.of("type", "string", "enum", List.of("MONTHLY", "QUARTERLY", "YEARLY", "CUSTOM")),
                                "alertThresholdPercent", Map.of("type", "integer")
                        ), List.of("name", "amount"))
                ),
                new GatewayToolDefinition(
                        "propose_payment_reminder",
                        "Prepare an Email + WhatsApp payment reminder card grounded in a real unpaid/overdue invoice's exact invoice number, due date, and outstanding balance.",
                        schema(Map.of(
                                "invoiceNumber", Map.of("type", "string", "description", "Optional specific invoice number"),
                                "customerName", Map.of("type", "string", "description", "Optional customer name filter"),
                                "tone", Map.of("type", "string", "enum", List.of("FRIENDLY", "FIRM", "FINAL"))
                        ), List.of())
                ),
                new GatewayToolDefinition(
                        "propose_business_memory",
                        "Suggest saving a durable business rule, supplier pattern, or seasonal context note to Business Memory (user approves with 1 click).",
                        schema(Map.of(
                                "memoryType", Map.of("type", "string", "enum", List.of(
                                        "BUSINESS_PROFILE", "TRANSACTION_CONTEXT", "SUPPLIER_PATTERN",
                                        "CATEGORIZATION_PREFERENCE", "DECISION_HISTORY", "OPERATIONAL_CONSTRAINT"
                                )),
                                "title", Map.of("type", "string"),
                                "content", Map.of("type", "string")
                        ), List.of("memoryType", "title", "content"))
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
        return executeTool(user, business, conversationId, toolName, rawArgs, AiLanguage.EN, null);
    }

    @Transactional
    public ToolExecutionResult executeTool(
            User user,
            Business business,
            UUID conversationId,
            String toolName,
            Map<String, Object> rawArgs,
            AiLanguage activeLanguage,
            UUID stagedReceiptAttachmentId
    ) {
        long startNs = System.nanoTime();
        Map<String, Object> args = rawArgs != null ? rawArgs : Map.of();
        List<AiEvidenceItem> evidence = new ArrayList<>();
        List<AiChartSpecDTO> charts = new ArrayList<>();
        List<AiActionDraftDTO> drafts = new ArrayList<>();
        String status = "OK";
        String approvalStatus = toolName != null && toolName.startsWith("propose_") ? "PROPOSAL_PENDING" : "AUTO_READ_ONLY";
        Map<String, Object> payload;

        try {
            payload = switch (toolName) {
                case "get_business_summary" -> runGetBusinessSummary(business, args, evidence, charts);
                case "compare_periods" -> runComparePeriods(business, args);
                case "get_category_breakdown" -> runGetCategoryBreakdown(business, args, evidence, charts);
                case "search_transactions" -> runSearchTransactions(business, args, evidence);
                case "get_invoices_overview" -> runGetInvoicesOverview(business, args, evidence);
                case "get_customers_overview" -> runGetCustomersOverview(business, args, evidence);
                case "get_budgets_status" -> runGetBudgetsStatus(business, evidence, charts);
                case "get_recurring_commitments" -> runGetRecurringCommitments(business, evidence);
                case "get_data_coverage" -> runGetDataCoverage(business);
                case "simulate_cashflow_forecast" -> runSimulateCashflow(business, args, evidence, charts);
                case "get_financial_pulse" -> runGetFinancialPulse(business, evidence);
                case "propose_transaction_draft" -> runProposeTransactionDraft(business, args, stagedReceiptAttachmentId, drafts);
                case "propose_invoice_draft" -> runProposeInvoiceDraft(business, args, drafts);
                case "propose_budget_draft" -> runProposeBudgetDraft(business, args, drafts);
                case "propose_payment_reminder" -> runProposePaymentReminder(business, args, activeLanguage, evidence, drafts);
                case "propose_business_memory" -> runProposeBusinessMemory(args, drafts);
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
        recordAudit(user, business, conversationId, toolName, args, status, approvalStatus, durationMs);

        String json;
        try {
            json = objectMapper.writeValueAsString(payload);
        } catch (Exception e) {
            json = "{\"error\":\"Serialization failed\"}";
        }
        return new ToolExecutionResult(toolName, json, List.copyOf(evidence), List.copyOf(charts), List.copyOf(drafts));
    }

    private Map<String, Object> runGetBusinessSummary(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence,
            List<AiChartSpecDTO> charts
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

            charts.add(new AiChartSpecDTO(
                    "summary-quarter-" + start,
                    "bar",
                    "Quarterly Revenue vs. Expenses",
                    "Current Quarter vs. Previous Quarter (" + currency + ")",
                    currency,
                    "period",
                    List.of(
                            new SeriesSpec("revenue", "Revenue", "emerald"),
                            new SeriesSpec("expenses", "Expenses", "rose")
                    ),
                    List.of(
                            Map.of("period", "Previous Qtr", "revenue", prevRev, "expenses", prevExp),
                            Map.of("period", "Current Qtr", "revenue", rev, "expenses", exp)
                    )
            ));

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

        if (summary.getRevenueData() != null && !summary.getRevenueData().isEmpty()) {
            List<Map<String, Object>> revChartRows = new ArrayList<>();
            for (DashboardSummaryDTO.RevenueDataPoint pt : summary.getRevenueData()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("label", pt.getName() != null ? pt.getName() : pt.getMonth());
                row.put("revenue", BigDecimal.valueOf(pt.getRevenue()).setScale(2, RoundingMode.HALF_UP));
                row.put("expenses", BigDecimal.valueOf(pt.getExpenses()).setScale(2, RoundingMode.HALF_UP));
                revChartRows.add(row);
            }
            charts.add(new AiChartSpecDTO(
                    "summary-" + statsPeriod,
                    "bar",
                    "Revenue vs. Expenses Trend",
                    "Period: " + statsPeriod + " (" + currency + ")",
                    currency,
                    "label",
                    List.of(
                            new SeriesSpec("revenue", "Revenue", "emerald"),
                            new SeriesSpec("expenses", "Expenses", "rose")
                    ),
                    revChartRows
            ));
        }

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
            List<AiEvidenceItem> evidence,
            List<AiChartSpecDTO> charts
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
        List<Map<String, Object>> chartRows = new ArrayList<>();
        for (Object[] row : rows) {
            String cat = String.valueOf(row[0]);
            BigDecimal amount = row[2] instanceof BigDecimal bd ? bd : BigDecimal.ZERO;
            BigDecimal sharePct = total.compareTo(BigDecimal.ZERO) > 0
                    ? amount.multiply(BigDecimal.valueOf(100)).divide(total, 1, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            items.add(Map.of("category", cat, "amount", amount, "sharePercent", sharePct));
            if (chartRows.size() < 7 && amount.compareTo(BigDecimal.ZERO) > 0) {
                Map<String, Object> pt = new LinkedHashMap<>();
                pt.put("name", cat);
                pt.put("value", amount.setScale(2, RoundingMode.HALF_UP));
                chartRows.add(pt);
            }
        }

        if (!chartRows.isEmpty()) {
            charts.add(new AiChartSpecDTO(
                    "cat-" + type.toLowerCase(Locale.ROOT) + "-" + from,
                    "donut",
                    ("EXPENSE".equals(type) ? "Expense" : "Income") + " Breakdown",
                    from + " → " + to + " (" + currency + ")",
                    currency,
                    "name",
                    List.of(new SeriesSpec("value", "Amount", "EXPENSE".equals(type) ? "rose" : "emerald")),
                    chartRows
            ));
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

    private Map<String, Object> runGetBudgetsStatus(
            Business business,
            List<AiEvidenceItem> evidence,
            List<AiChartSpecDTO> charts
    ) {
        BudgetSummaryDTO summary = budgetService.buildSummaryForBusiness(business, LocalDate.now());
        List<Map<String, Object>> items = new ArrayList<>();
        List<Map<String, Object>> chartRows = new ArrayList<>();
        String currency = summary != null ? summary.currency() : resolveCurrency(business);
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

                if (chartRows.size() < 8) {
                    Map<String, Object> cp = new LinkedHashMap<>();
                    cp.put("name", b.name().length() > 18 ? b.name().substring(0, 15) + "..." : b.name());
                    cp.put("limit", b.budgetAmount().setScale(2, RoundingMode.HALF_UP));
                    cp.put("spent", b.actualSpending().setScale(2, RoundingMode.HALF_UP));
                    chartRows.add(cp);
                }

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
        if (!chartRows.isEmpty()) {
            charts.add(new AiChartSpecDTO(
                    "budgets-" + LocalDate.now(),
                    "bar",
                    "Budget Utilization",
                    "Actual Spending vs. Limit (" + currency + ")",
                    currency,
                    "name",
                    List.of(
                            new SeriesSpec("limit", "Limit", "sky"),
                            new SeriesSpec("spent", "Spent", "primary")
                    ),
                    chartRows
            ));
        }
        return Map.of(
                "currency", currency,
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

    private Map<String, Object> runSimulateCashflow(
            Business business,
            Map<String, Object> args,
            List<AiEvidenceItem> evidence,
            List<AiChartSpecDTO> charts
    ) {
        if (cashflowSimulatorService == null) {
            return Map.of("error", "Cashflow simulator service is unavailable.");
        }
        AiCashflowSimulatorService.SimulationResult sim = cashflowSimulatorService.simulate(business, args);
        if (sim.chart() != null) charts.add(sim.chart());
        if (sim.evidence() != null) evidence.add(sim.evidence());
        return sim.payload();
    }

    private Map<String, Object> runGetFinancialPulse(
            Business business,
            List<AiEvidenceItem> evidence
    ) {
        if (pulseService == null) {
            return Map.of("error", "Financial pulse service is unavailable.");
        }
        AiPulseDTO pulse = pulseService.buildPulseForBusiness(business);
        evidence.add(new AiEvidenceItem(
                "REPORT",
                "pulse-" + LocalDate.now(),
                "AFAB Pulse (" + pulse.highCount() + " high, " + pulse.mediumCount() + " medium alerts)",
                "Net month profit & anomaly scan",
                pulse.monthNetProfit(),
                pulse.currency(),
                LocalDate.now().toString(),
                "/dashboard"
        ));
        return Map.of(
                "currency", pulse.currency(),
                "monthRevenue", pulse.monthRevenue(),
                "monthExpenses", pulse.monthExpenses(),
                "monthNetProfit", pulse.monthNetProfit(),
                "overdueCount", pulse.overdueCount(),
                "overdueTotal", pulse.overdueTotal(),
                "missingReceiptCount", pulse.missingReceiptCount(),
                "alerts", pulse.alerts()
        );
    }

    private Map<String, Object> runProposeTransactionDraft(
            Business business,
            Map<String, Object> args,
            UUID stagedReceiptAttachmentId,
            List<AiActionDraftDTO> drafts
    ) {
        String type = stringArg(args, "type", "EXPENSE").toUpperCase(Locale.ROOT);
        if (!"EXPENSE".equals(type) && !"INCOME".equals(type)) {
            type = "EXPENSE";
        }
        BigDecimal amount = decimalArg(args, "amount");
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Proposed transaction amount must be greater than zero.");
        }
        String description = trimOrNull(stringArg(args, "description", null));
        if (description == null) {
            description = "EXPENSE".equals(type) ? "Recorded Expense" : "Recorded Income";
        }
        String currency = trimOrNull(stringArg(args, "currency", null));
        if (currency == null || currency.length() != 3) {
            currency = resolveCurrency(business);
        } else {
            currency = currency.toUpperCase(Locale.ROOT);
        }
        LocalDate txDate = resolveFlexibleDate(stringArg(args, "transactionDate", null), LocalDate.now());
        String paymentMethod = normalizePaymentMethod(stringArg(args, "paymentMethod", "BANK_TRANSFER"));
        Category matchedCategory = matchCategory(business.getId(), type, stringArg(args, "categoryName", null));
        String notes = trimOrNull(stringArg(args, "notes", null));
        String ocrText = trimOrNull(stringArg(args, "extractedOcrText", null));

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("type", type);
        payload.put("amount", amount.setScale(2, RoundingMode.HALF_UP));
        payload.put("currency", currency);
        payload.put("baseCurrency", resolveCurrency(business));
        payload.put("description", description);
        payload.put("transactionDate", txDate.toString());
        payload.put("categoryId", matchedCategory != null ? matchedCategory.getId().toString() : null);
        payload.put("categoryName", matchedCategory != null ? matchedCategory.getName() : "Uncategorized");
        payload.put("paymentMethod", paymentMethod);
        payload.put("status", "COMPLETED");
        payload.put("notes", notes != null ? notes : "");
        if (ocrText != null) {
            payload.put("extractedOcrText", ocrText);
        }

        String draftId = "tx-draft-" + UUID.randomUUID().toString().substring(0, 8);
        String title = ("EXPENSE".equals(type) ? "Expense Draft: " : "Income Draft: ") + description;
        String summary = amount.setScale(2, RoundingMode.HALF_UP).toPlainString() + " " + currency
                + " • " + (matchedCategory != null ? matchedCategory.getName() : "Uncategorized")
                + " • " + txDate;

        drafts.add(new AiActionDraftDTO(
                draftId, "CREATE_TRANSACTION", "PENDING", title, summary, payload,
                stagedReceiptAttachmentId, null, null
        ));

        return Map.of(
                "status", "DRAFT_CREATED_PENDING_USER_APPROVAL",
                "savedToDatabase", false,
                "draftId", draftId,
                "draft", payload,
                "receiptAttached", stagedReceiptAttachmentId != null
        );
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> runProposeInvoiceDraft(
            Business business,
            Map<String, Object> args,
            List<AiActionDraftDTO> drafts
    ) {
        String customerNameArg = trimOrNull(stringArg(args, "customerName", null));
        Customer matchedCustomer = matchCustomer(business.getId(), customerNameArg);
        LocalDate issueDate = resolveFlexibleDate(stringArg(args, "issueDate", null), LocalDate.now());
        LocalDate dueDate = resolveFlexibleDate(stringArg(args, "dueDate", null), issueDate.plusDays(30));
        if (dueDate.isBefore(issueDate)) {
            dueDate = issueDate.plusDays(14);
        }
        String currency = trimOrNull(stringArg(args, "currency", null));
        currency = (currency != null && currency.length() == 3) ? currency.toUpperCase(Locale.ROOT) : resolveCurrency(business);
        BigDecimal discount = safe(decimalArg(args, "discountAmount")).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
        String notes = trimOrNull(stringArg(args, "notes", null));

        Object rawItemsObj = args.get("items");
        List<Map<String, Object>> normalizedItems = new ArrayList<>();
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal taxTotal = BigDecimal.ZERO;

        if (rawItemsObj instanceof List<?> rawList) {
            for (Object entryObj : rawList) {
                if (!(entryObj instanceof Map<?, ?> rawMap)) continue;
                Map<String, Object> itemMap = (Map<String, Object>) rawMap;
                String desc = trimOrNull(stringArg(itemMap, "description", "Services"));
                if (desc == null) desc = "Services";
                BigDecimal qty = safe(decimalArg(itemMap, "quantity")).max(new BigDecimal("0.01"));
                BigDecimal unitPrice = safe(decimalArg(itemMap, "unitPrice")).max(BigDecimal.ZERO);
                BigDecimal taxRate = safe(decimalArg(itemMap, "taxRate")).max(BigDecimal.ZERO).min(new BigDecimal("100"));

                BigDecimal lineSub = qty.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);
                BigDecimal lineTax = lineSub.multiply(taxRate).divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
                subtotal = subtotal.add(lineSub);
                taxTotal = taxTotal.add(lineTax);

                Map<String, Object> itemOut = new LinkedHashMap<>();
                itemOut.put("description", desc);
                itemOut.put("quantity", qty);
                itemOut.put("unitPrice", unitPrice.setScale(2, RoundingMode.HALF_UP));
                itemOut.put("taxRate", taxRate.setScale(2, RoundingMode.HALF_UP));
                normalizedItems.add(itemOut);
            }
        }
        if (normalizedItems.isEmpty()) {
            throw new IllegalArgumentException("Invoice draft requires at least one line item.");
        }

        BigDecimal totalAmount = subtotal.add(taxTotal).subtract(discount).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("customerId", matchedCustomer != null ? matchedCustomer.getId().toString() : null);
        payload.put("customerName", matchedCustomer != null ? matchedCustomer.getName() : (customerNameArg != null ? customerNameArg : "Walk-in / Select Customer"));
        payload.put("issueDate", issueDate.toString());
        payload.put("dueDate", dueDate.toString());
        payload.put("currency", currency);
        payload.put("discountAmount", discount);
        payload.put("subtotal", subtotal);
        payload.put("taxAmount", taxTotal);
        payload.put("totalAmount", totalAmount);
        payload.put("notes", notes != null ? notes : "");
        payload.put("items", normalizedItems);

        String draftId = "inv-draft-" + UUID.randomUUID().toString().substring(0, 8);
        String custLabel = matchedCustomer != null ? matchedCustomer.getName() : (customerNameArg != null ? customerNameArg : "New Invoice");
        drafts.add(new AiActionDraftDTO(
                draftId, "CREATE_INVOICE", "PENDING",
                "Invoice Draft: " + custLabel,
                totalAmount.toPlainString() + " " + currency + " • Due " + dueDate,
                payload, null, null, null
        ));

        return Map.of(
                "status", "DRAFT_CREATED_PENDING_USER_APPROVAL",
                "savedToDatabase", false,
                "draftId", draftId,
                "draft", payload
        );
    }

    private Map<String, Object> runProposeBudgetDraft(
            Business business,
            Map<String, Object> args,
            List<AiActionDraftDTO> drafts
    ) {
        String name = trimOrNull(stringArg(args, "name", null));
        BigDecimal amount = decimalArg(args, "amount");
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Budget amount must be positive.");
        }
        String categoryNameArg = trimOrNull(stringArg(args, "categoryName", null));
        Category cat = categoryNameArg != null ? matchCategory(business.getId(), "EXPENSE", categoryNameArg) : null;
        String periodType = stringArg(args, "periodType", "MONTHLY").toUpperCase(Locale.ROOT);
        if (!Set.of("MONTHLY", "QUARTERLY", "YEARLY", "CUSTOM").contains(periodType)) {
            periodType = "MONTHLY";
        }
        int alertThreshold = intArg(args, "alertThresholdPercent", 80, 10, 100);
        if (name == null) {
            name = (cat != null ? cat.getName() : "Monthly") + " Budget";
        }
        String currency = resolveCurrency(business);

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("name", name);
        payload.put("amount", amount.setScale(2, RoundingMode.HALF_UP));
        payload.put("currency", currency);
        payload.put("categoryId", cat != null ? cat.getId().toString() : null);
        payload.put("categoryName", cat != null ? cat.getName() : "Overall Business Expenses");
        payload.put("periodType", periodType);
        payload.put("alertThresholdPercent", alertThreshold);

        String draftId = "budget-draft-" + UUID.randomUUID().toString().substring(0, 8);
        drafts.add(new AiActionDraftDTO(
                draftId, "CREATE_BUDGET", "PENDING",
                "Budget Draft: " + name,
                amount.setScale(2, RoundingMode.HALF_UP).toPlainString() + " " + currency + " (" + periodType + ")",
                payload, null, null, null
        ));

        return Map.of(
                "status", "DRAFT_CREATED_PENDING_USER_APPROVAL",
                "savedToDatabase", false,
                "draftId", draftId,
                "draft", payload
        );
    }

    private Map<String, Object> runProposePaymentReminder(
            Business business,
            Map<String, Object> args,
            AiLanguage lang,
            List<AiEvidenceItem> evidence,
            List<AiActionDraftDTO> drafts
    ) {
        LocalDate today = LocalDate.now();
        String invNumberArg = trimOrNull(stringArg(args, "invoiceNumber", null));
        String customerNameArg = trimOrNull(stringArg(args, "customerName", null));
        String tone = stringArg(args, "tone", "FRIENDLY").toUpperCase(Locale.ROOT);

        List<Invoice> all = invoiceRepository.findAllByBusinessIdWithCustomer(business.getId());
        Invoice target = null;
        for (Invoice inv : all) {
            InvoiceStatus eff = inv.computeEffectiveStatus(today);
            if (eff == InvoiceStatus.CANCELLED || eff == InvoiceStatus.DRAFT || eff == InvoiceStatus.PAID) continue;
            if (invNumberArg != null && inv.getInvoiceNumber() != null
                    && inv.getInvoiceNumber().equalsIgnoreCase(invNumberArg)) {
                target = inv;
                break;
            }
            if (customerNameArg != null && inv.getCustomer() != null && inv.getCustomer().getName() != null
                    && inv.getCustomer().getName().toLowerCase(Locale.ROOT).contains(customerNameArg.toLowerCase(Locale.ROOT))) {
                target = inv;
                break;
            }
            if (target == null && eff == InvoiceStatus.OVERDUE) {
                target = inv;
            } else if (target == null && invNumberArg == null && customerNameArg == null) {
                target = inv;
            }
        }

        if (target == null) {
            return Map.of("found", false, "message", "No unpaid or overdue invoice matched.");
        }

        String custName = target.getCustomer() != null ? target.getCustomer().getName() : "Client";
        String custEmail = target.getCustomer() != null && target.getCustomer().getEmail() != null ? target.getCustomer().getEmail() : "";
        String custPhone = target.getCustomer() != null && target.getCustomer().getPhone() != null ? target.getCustomer().getPhone() : "";
        BigDecimal balance = safe(target.getOutstandingBalance()).setScale(2, RoundingMode.HALF_UP);
        long daysOverdue = target.getDueDate() != null && target.getDueDate().isBefore(today)
                ? ChronoUnit.DAYS.between(target.getDueDate(), today) : 0;

        Map<String, String> copy = buildLocalizedReminderCopy(
                lang, business.getName(), custName, target.getInvoiceNumber(),
                balance.toPlainString(), target.getCurrency(),
                target.getDueDate() != null ? target.getDueDate().toString() : "",
                daysOverdue, tone
        );

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("invoiceId", target.getId().toString());
        payload.put("invoiceNumber", target.getInvoiceNumber());
        payload.put("customerName", custName);
        payload.put("customerEmail", custEmail);
        payload.put("customerPhone", custPhone);
        payload.put("dueDate", target.getDueDate() != null ? target.getDueDate().toString() : "");
        payload.put("daysOverdue", daysOverdue);
        payload.put("outstandingBalance", balance);
        payload.put("currency", target.getCurrency());
        payload.put("emailSubject", copy.get("emailSubject"));
        payload.put("emailBody", copy.get("emailBody"));
        payload.put("whatsappBody", copy.get("whatsappBody"));
        payload.put("language", lang.name());

        String draftId = "reminder-" + UUID.randomUUID().toString().substring(0, 8);
        drafts.add(new AiActionDraftDTO(
                draftId, "PAYMENT_REMINDER", "PENDING",
                "Reminder: " + target.getInvoiceNumber() + " (" + custName + ")",
                balance.toPlainString() + " " + target.getCurrency() + (daysOverdue > 0 ? " • " + daysOverdue + "d overdue" : ""),
                payload, null, target.getId(), "/dashboard/invoices"
        ));

        evidence.add(new AiEvidenceItem(
                "INVOICE", target.getId().toString(),
                "Invoice " + target.getInvoiceNumber() + " (" + custName + ")",
                daysOverdue > 0 ? daysOverdue + "d overdue" : "Unpaid",
                balance, target.getCurrency(),
                target.getDueDate() != null ? target.getDueDate().toString() : "",
                "/dashboard/invoices"
        ));

        return Map.of("found", true, "draftId", draftId, "reminder", payload);
    }

    private Map<String, Object> runProposeBusinessMemory(
            Map<String, Object> args,
            List<AiActionDraftDTO> drafts
    ) {
        String rawType = stringArg(args, "memoryType", "TRANSACTION_CONTEXT").trim().toUpperCase(Locale.ROOT);
        if (!BusinessMemoryService.ALLOWED_MEMORY_TYPES.contains(rawType)) {
            rawType = "TRANSACTION_CONTEXT";
        }
        String title = trimOrNull(stringArg(args, "title", null));
        String content = trimOrNull(stringArg(args, "content", null));
        if (title == null || content == null) {
            throw new IllegalArgumentException("Memory proposal requires both title and content.");
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("memoryType", rawType);
        payload.put("title", title.length() > 160 ? title.substring(0, 160) : title);
        payload.put("content", content.length() > 2000 ? content.substring(0, 2000) : content);

        String draftId = "mem-draft-" + UUID.randomUUID().toString().substring(0, 8);
        drafts.add(new AiActionDraftDTO(
                draftId, "SAVE_MEMORY", "PENDING",
                "Save to Business Memory?",
                title,
                payload, null, null, "/dashboard/ai"
        ));

        return Map.of("status", "MEMORY_PROPOSED_PENDING_USER_APPROVAL", "draftId", draftId, "proposal", payload);
    }

    private Map<String, String> buildLocalizedReminderCopy(
            AiLanguage lang, String businessName, String customerName, String invoiceNumber,
            String balance, String currency, String dueDate, long daysOverdue, String tone
    ) {
        String overdueNoteEn = daysOverdue > 0 ? " (currently " + daysOverdue + " days past due)" : "";
        return switch (lang) {
            case FR -> Map.of(
                    "emailSubject", "Rappel de paiement — Facture " + invoiceNumber + " (" + businessName + ")",
                    "emailBody", "Bonjour " + customerName + ",\n\nSauf erreur de notre part, le solde de " + balance + " " + currency
                            + " pour la facture " + invoiceNumber + " (échéance : " + dueDate + ") reste en attente.\n"
                            + "Merci de bien vouloir procéder au règlement ou de nous confirmer la date de paiement.\n\nCordialement,\n" + businessName,
                    "whatsappBody", "Bonjour " + customerName + " 👋 Petit rappel de " + businessName + " concernant la facture "
                            + invoiceNumber + " d'un montant restant de " + balance + " " + currency + " (échéance " + dueDate + "). Merci !"
            );
            case AR_MSA -> Map.of(
                    "emailSubject", "تذكير بالدفع — الفاتورة " + invoiceNumber + " (" + businessName + ")",
                    "emailBody", "مرحباً " + customerName + "،\n\nنود تذكيركم بلطف بأن الفاتورة رقم " + invoiceNumber
                            + " بمبلغ متبقٍ قدره " + balance + " " + currency + " (تاريخ الاستحقاق: " + dueDate + ") لا تزال غير مسددة.\n"
                            + "يرجى التفضل بالسداد أو موافاتنا بموعد التحويل المتوقع.\n\nمع التحية،\n" + businessName,
                    "whatsappBody", "مرحباً " + customerName + "، تذكير لطيف من " + businessName + " بخصوص الفاتورة رقم "
                            + invoiceNumber + " بمبلغ متبقٍ " + balance + " " + currency + " (تاريخ الاستحقاق " + dueDate + "). شكراً لتعاونكم."
            );
            case AR_DERJA_SCRIPT -> Map.of(
                    "emailSubject", "تذكير بالخلاص — الفاتورة " + invoiceNumber + " (" + businessName + ")",
                    "emailBody", "عسلامة " + customerName + "،\n\nحبينا نذكروكم بلطف في الفاتورة رقم " + invoiceNumber
                            + " اللي مازال فيها " + balance + " " + currency + " (تاريخ الخلاص: " + dueDate + ").\n"
                            + "يعيشكم أبعثولنا وقتاش تنجمو تخلصوها.\n\nيعطيكم الصحة،\n" + businessName,
                    "whatsappBody", "عسلامة " + customerName + " 👋 تذكير صغير من " + businessName + " على الفاتورة "
                            + invoiceNumber + " بقيمة " + balance + " " + currency + " (آخر أجل " + dueDate + "). يعيشك أعلمنا وقتاش تخلصها."
            );
            case AR_DERJA_ARABIZI -> Map.of(
                    "emailSubject", "Tadhkir b khalas fatoura " + invoiceNumber + " (" + businessName + ")",
                    "emailBody", "Aslema " + customerName + ",\n\nHabbina ndhakroukom b'lotf fi fatoura " + invoiceNumber
                            + " elli mazel fiha " + balance + " " + currency + " (echeance: " + dueDate + ").\n"
                            + "Aaychek aamelna mise a jour waqtech tnajjem t5allasha.\n\nMerci,\n" + businessName,
                    "whatsappBody", "Aslema " + customerName + " 👋 tadhkir sghir men " + businessName + " aala fatoura "
                            + invoiceNumber + " b'montant " + balance + " " + currency + " (due " + dueDate + "). Aaychek t5alliha fi belek!"
            );
            case EN -> Map.of(
                    "emailSubject", "Payment Reminder — Invoice " + invoiceNumber + " (" + businessName + ")",
                    "emailBody", "Hi " + customerName + ",\n\nThis is a " + ("FIRM".equals(tone) || "FINAL".equals(tone) ? "courtesy" : "friendly")
                            + " reminder that invoice " + invoiceNumber + " has an outstanding balance of " + balance + " " + currency
                            + " with a due date of " + dueDate + overdueNoteEn + ".\nPlease let us know once payment has been scheduled.\n\nBest regards,\n" + businessName,
                    "whatsappBody", "Hi " + customerName + " 👋 Friendly reminder from " + businessName + ": invoice "
                            + invoiceNumber + " has a balance of " + balance + " " + currency + " (due " + dueDate + "). Let us know if you need anything!"
            );
        };
    }

    private Category matchCategory(UUID businessId, String txType, String query) {
        if (categoryRepository == null) return null;
        List<Category> cats = categoryRepository.findAllForBusiness(businessId).stream()
                .filter(c -> txType.equalsIgnoreCase(c.getType()))
                .toList();
        if (cats.isEmpty()) return null;
        if (query != null && !query.isBlank()) {
            String q = query.trim().toLowerCase(Locale.ROOT);
            for (Category c : cats) {
                if (c.getName() != null && c.getName().trim().toLowerCase(Locale.ROOT).equals(q)) {
                    return c;
                }
            }
            for (Category c : cats) {
                if (c.getName() != null && (c.getName().toLowerCase(Locale.ROOT).contains(q) || q.contains(c.getName().toLowerCase(Locale.ROOT)))) {
                    return c;
                }
            }
        }
        return cats.get(0);
    }

    private Customer matchCustomer(UUID businessId, String query) {
        if (query == null || query.isBlank()) return null;
        String q = query.trim().toLowerCase(Locale.ROOT);
        List<Customer> customers = customerRepository.findAllActiveByBusinessId(businessId);
        for (Customer c : customers) {
            if (c.getName() != null && c.getName().trim().toLowerCase(Locale.ROOT).equals(q)) return c;
        }
        for (Customer c : customers) {
            if ((c.getName() != null && c.getName().toLowerCase(Locale.ROOT).contains(q))
                    || (c.getCompanyName() != null && c.getCompanyName().toLowerCase(Locale.ROOT).contains(q))) {
                return c;
            }
        }
        return null;
    }

    private LocalDate resolveFlexibleDate(String raw, LocalDate fallback) {
        if (raw == null || raw.isBlank()) return fallback;
        String lower = raw.trim().toLowerCase(Locale.ROOT);
        LocalDate today = LocalDate.now();
        if (lower.equals("today") || lower.equals("aujourd'hui") || lower.equals("lyoum") || lower.equals("اليوم")) {
            return today;
        }
        if (lower.equals("yesterday") || lower.equals("hier") || lower.equals("lbereh") || lower.equals("البارح") || lower.equals("أمس")) {
            return today.minusDays(1);
        }
        try {
            return LocalDate.parse(raw.trim());
        } catch (Exception e) {
            return fallback;
        }
    }

    private String normalizePaymentMethod(String raw) {
        if (raw == null || raw.isBlank()) return "BANK_TRANSFER";
        String up = raw.trim().toUpperCase(Locale.ROOT);
        if (up.contains("CASH") || up.contains("ESPECE")) return "CASH";
        if (up.contains("CARD") || up.contains("CARTE")) return "CARD";
        if (up.contains("BANK") || up.contains("VIREMENT") || up.contains("TRANSFER")) return "BANK_TRANSFER";
        return Set.of("BANK_TRANSFER", "CARD", "CREDIT_CARD", "CASH", "OTHER").contains(up) ? up : "OTHER";
    }

    private BigDecimal decimalArg(Map<String, Object> args, String key) {
        if (args == null) return null;
        Object val = args.get(key);
        if (val == null) return null;
        try {
            return new BigDecimal(String.valueOf(val).trim());
        } catch (Exception e) {
            return null;
        }
    }

    private void recordAudit(
            User user,
            Business business,
            UUID conversationId,
            String toolName,
            Map<String, Object> args,
            String resultStatus,
            String approvalStatus,
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
            audit.setApprovalStatus(approvalStatus != null ? approvalStatus : "AUTO_READ_ONLY");
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
