package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.*;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentBusinessService currentBusinessService;
    private final CategoryService categoryService;
    private final AuditService auditService;

    public TransactionService(TransactionRepository transactionRepository,
                              CategoryRepository categoryRepository,
                              CurrentBusinessService currentBusinessService,
                              CategoryService categoryService,
                              AuditService auditService) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.currentBusinessService = currentBusinessService;
        this.categoryService = categoryService;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public TransactionResponseDTO getTransactions(String userEmail, String type, UUID categoryId, String search, int page, int size) {
        return getTransactions(userEmail, type, categoryId, null, null, null, null, null, search, page, size);
    }

    @Transactional(readOnly = true)
    public TransactionResponseDTO getTransactions(
            String userEmail,
            String type,
            UUID categoryId,
            String status,
            String paymentMethod,
            LocalDate startDate,
            LocalDate endDate,
            String search,
            int page,
            int size
    ) {
        return getTransactions(userEmail, type, categoryId, status, paymentMethod, null, startDate, endDate, search, page, size);
    }

    @Transactional(readOnly = true)
    public TransactionResponseDTO getTransactions(
            String userEmail,
            String type,
            UUID categoryId,
            String status,
            String paymentMethod,
            Boolean taxDeductible,
            LocalDate startDate,
            LocalDate endDate,
            String search,
            int page,
            int size
    ) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        int safePage = Math.max(0, page);
        int safeSize = Math.min(100, Math.max(1, size));

        Page<Transaction> txPage = transactionRepository.searchTransactions(
                business.getId(),
                (type != null && !type.isBlank()) ? type.toUpperCase().trim() : null,
                categoryId,
                (status != null && !status.isBlank()) ? status.toUpperCase().trim() : null,
                (paymentMethod != null && !paymentMethod.isBlank()) ? paymentMethod.toUpperCase().trim() : null,
                taxDeductible,
                startDate,
                endDate,
                (search != null && !search.isBlank()) ? search.trim() : null,
                PageRequest.of(safePage, safeSize)
        );

        List<TransactionDTO> dtos = txPage.getContent().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());

        BigDecimal totalInflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "INCOME");
        BigDecimal totalOutflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");
        BigDecimal netBalance = totalInflow.subtract(totalOutflow);

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        return new TransactionResponseDTO(
                dtos,
                txPage.getNumber(),
                txPage.getSize(),
                txPage.getTotalElements(),
                txPage.getTotalPages(),
                totalInflow,
                totalOutflow,
                netBalance,
                currency
        );
    }

    @Transactional
    public TransactionDTO createTransaction(String userEmail, CreateTransactionRequest request) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String txType = request.getType().toUpperCase().trim();

        Transaction tx = new Transaction();
        tx.setBusiness(business);
        tx.setType(txType);
        tx.setAmount(request.getAmount());
        tx.setCurrency((business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD");
        tx.setDescription(request.getDescription().trim());
        tx.setTransactionDate(request.getTransactionDate());
        tx.setPaymentMethod(request.getPaymentMethod() != null ? request.getPaymentMethod().toUpperCase().trim() : "BANK_TRANSFER");
        tx.setStatus(request.getStatus() != null ? request.getStatus().toUpperCase().trim() : "COMPLETED");
        tx.setNotes(request.getNotes() != null ? request.getNotes().trim() : null);
        tx.setTaxDeductible(request.getTaxDeductible());
        tx.setTaxRate(request.getTaxRate());

        // Fix F5: Category existence, ownership, and type integrity check
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found with ID: " + request.getCategoryId()));

            if (category.getBusiness() != null && !category.getBusiness().getId().equals(business.getId())) {
                throw new ForbiddenException("Unauthorized: Category belongs to another business.");
            }

            if (!category.getType().equalsIgnoreCase(txType)) {
                throw new IllegalArgumentException("Category type '" + category.getType() + "' does not match transaction type '" + txType + "'.");
            }

            tx.setCategory(category);
        }

        // Split items handling
        if (request.getSplitItems() != null && !request.getSplitItems().isEmpty()) {
            BigDecimal splitSum = request.getSplitItems().stream()
                    .map(SplitRequestItem::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            if (splitSum.compareTo(request.getAmount()) != 0) {
                throw new IllegalArgumentException("Sum of split lines (" + splitSum + ") must equal total transaction amount (" + request.getAmount() + ").");
            }

            tx.setIsSplit(true);
            for (SplitRequestItem split : request.getSplitItems()) {
                Category splitCat = categoryRepository.findById(split.getCategoryId())
                        .orElseThrow(() -> new ResourceNotFoundException("Split category not found: " + split.getCategoryId()));

                if (splitCat.getBusiness() != null && !splitCat.getBusiness().getId().equals(business.getId())) {
                    throw new ForbiddenException("Unauthorized: Split category belongs to another business.");
                }

                if (!splitCat.getType().equalsIgnoreCase(txType)) {
                    throw new IllegalArgumentException("Split category type '" + splitCat.getType() + "' does not match transaction type '" + txType + "'.");
                }

                Transaction childTx = new Transaction();
                childTx.setBusiness(business);
                childTx.setType(txType);
                childTx.setAmount(split.getAmount());
                childTx.setCurrency(tx.getCurrency());
                childTx.setDescription(split.getDescription() != null && !split.getDescription().isBlank() ? split.getDescription().trim() : tx.getDescription());
                childTx.setTransactionDate(tx.getTransactionDate());
                childTx.setCategory(splitCat);
                childTx.setPaymentMethod(tx.getPaymentMethod());
                childTx.setStatus(tx.getStatus());
                childTx.setTaxDeductible(tx.getTaxDeductible());
                childTx.setTaxRate(tx.getTaxRate());
                childTx.setParentTransaction(tx);
                tx.getSplitItems().add(childTx);
            }
        }

        tx = transactionRepository.save(tx);
        return mapToDTO(tx);
    }

    @Transactional
    public TransactionDTO updateTransaction(String userEmail, UUID transactionId, UpdateTransactionRequest request) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        Transaction tx = transactionRepository.findActiveById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found with ID: " + transactionId));

        if (!tx.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not own this transaction.");
        }

        String targetType = (request.getType() != null && !request.getType().isBlank())
                ? request.getType().toUpperCase().trim() : tx.getType();

        if (request.getType() != null && !request.getType().isBlank()) {
            tx.setType(targetType);
        }
        if (request.getAmount() != null) {
            tx.setAmount(request.getAmount());
        }
        if (request.getDescription() != null && !request.getDescription().isBlank()) {
            tx.setDescription(request.getDescription().trim());
        }
        if (request.getTransactionDate() != null) {
            tx.setTransactionDate(request.getTransactionDate());
        }
        if (request.getPaymentMethod() != null && !request.getPaymentMethod().isBlank()) {
            tx.setPaymentMethod(request.getPaymentMethod().toUpperCase().trim());
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            tx.setStatus(request.getStatus().toUpperCase().trim());
        }
        if (request.getNotes() != null) {
            tx.setNotes(request.getNotes().trim());
        }
        if (request.getTaxDeductible() != null) {
            tx.setTaxDeductible(request.getTaxDeductible());
        }
        if (request.getTaxRate() != null) {
            tx.setTaxRate(request.getTaxRate());
        }

        // Fix F5 on Update: Category integrity check
        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found with ID: " + request.getCategoryId()));

            if (category.getBusiness() != null && !category.getBusiness().getId().equals(business.getId())) {
                throw new ForbiddenException("Unauthorized: Category belongs to another business.");
            }

            if (!category.getType().equalsIgnoreCase(targetType)) {
                throw new IllegalArgumentException("Category type '" + category.getType() + "' does not match transaction type '" + targetType + "'.");
            }

            tx.setCategory(category);
        }

        tx = transactionRepository.save(tx);
        return mapToDTO(tx);
    }

    @Transactional
    public void deleteTransaction(String userEmail, UUID transactionId) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        Transaction tx = transactionRepository.findActiveById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found with ID: " + transactionId));

        if (!tx.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not own this transaction.");
        }

        // Soft-delete transaction (Decision D6)
        tx.setDeletedAt(Instant.now());
        transactionRepository.save(tx);

        auditService.log(user, "DELETE", "Transaction", tx.getId(), null);
    }

    @Transactional(readOnly = true)
    public List<CategoryDTO> getCategories(String userEmail) {
        return categoryService.getCategories(userEmail);
    }

    @Transactional(readOnly = true)
    public ExpenseSummaryDTO getExpenseSummary(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        BigDecimal totalExpenses = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");

        BigDecimal avgPerDay = totalExpenses.compareTo(BigDecimal.ZERO) > 0
                ? totalExpenses.divide(new BigDecimal("30"), 2, java.math.RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        Page<Transaction> expensesPage = transactionRepository.searchTransactions(
                business.getId(), "EXPENSE", null, null, null, null, null, null, null, PageRequest.of(0, 100)
        );
        List<Transaction> expenses = expensesPage.getContent();

        String highestTitle = expenses.isEmpty() ? "No Expenses" : "N/A";
        BigDecimal highestAmount = BigDecimal.ZERO;
        if (!expenses.isEmpty()) {
            Transaction maxTx = expenses.stream()
                    .max(java.util.Comparator.comparing(Transaction::getAmount))
                    .orElse(null);
            if (maxTx != null) {
                highestTitle = maxTx.getDescription();
                highestAmount = maxTx.getAmount();
            }
        }

        long categoryCount = expenses.stream()
                .map(t -> t.getCategory() != null ? t.getCategory().getName() : "General")
                .distinct()
                .count();

        java.util.Map<String, BigDecimal> catSums = new java.util.HashMap<>();
        java.util.Map<String, String> catColors = new java.util.HashMap<>();
        for (Transaction t : expenses) {
            String catName = t.getCategory() != null ? t.getCategory().getName() : "General Expenses";
            String catColor = (t.getCategory() != null && t.getCategory().getColor() != null)
                    ? t.getCategory().getColor() : "#9f78ff";
            catSums.put(catName, catSums.getOrDefault(catName, BigDecimal.ZERO).add(t.getAmount()));
            catColors.put(catName, catColor);
        }

        List<ExpenseSummaryDTO.CategoryBreakdownItem> breakdown = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, BigDecimal> entry : catSums.entrySet()) {
            double pct = totalExpenses.compareTo(BigDecimal.ZERO) > 0
                    ? entry.getValue().doubleValue() / totalExpenses.doubleValue() * 100.0
                    : 0.0;
            breakdown.add(new ExpenseSummaryDTO.CategoryBreakdownItem(
                    entry.getKey(),
                    entry.getValue(),
                    Math.round(pct * 10.0) / 10.0,
                    catColors.getOrDefault(entry.getKey(), "#9f78ff")
            ));
        }

        List<ExpenseSummaryDTO.RecurringItem> recurringList = List.of(
                new ExpenseSummaryDTO.RecurringItem("Adobe Creative Cloud", new BigDecimal("52.00"), "Monthly", "Jun 16", "palette"),
                new ExpenseSummaryDTO.RecurringItem("Google Workspace", new BigDecimal("120.00"), "Monthly", "Jun 20", "mail"),
                new ExpenseSummaryDTO.RecurringItem("Shopify Plan", new BigDecimal("79.00"), "Monthly", "Jun 22", "shopping_cart")
        );
        BigDecimal recurringTotal = new BigDecimal("251.00");
        double recurringPct = totalExpenses.compareTo(BigDecimal.ZERO) > 0
                ? recurringTotal.doubleValue() / totalExpenses.doubleValue() * 100.0
                : 0.0;

        List<ExpenseSummaryDTO.DailyOverviewPoint> dailyOverview = List.of();

        return new ExpenseSummaryDTO(
                totalExpenses,
                avgPerDay,
                highestTitle,
                highestAmount,
                categoryCount,
                recurringTotal,
                Math.round(recurringPct * 10.0) / 10.0,
                currency,
                breakdown,
                recurringList,
                dailyOverview
        );
    }

    @Transactional(readOnly = true)
    public RevenueSummaryDTO getRevenueSummary(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        BigDecimal totalRevenue = transactionRepository.sumAmountByBusinessAndType(business.getId(), "INCOME");
        BigDecimal grossRevenue = totalRevenue;
        BigDecimal discounts = BigDecimal.ZERO;
        BigDecimal refunds = BigDecimal.ZERO;
        BigDecimal netRevenue = grossRevenue.subtract(discounts).subtract(refunds);

        BigDecimal avgPerDay = totalRevenue.compareTo(BigDecimal.ZERO) > 0
                ? totalRevenue.divide(new BigDecimal("30"), 2, java.math.RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        Page<Transaction> incomePage = transactionRepository.searchTransactions(
                business.getId(), "INCOME", null, null, null, null, null, null, null, PageRequest.of(0, 100)
        );
        List<Transaction> incomes = incomePage.getContent();
        long totalInvoices = incomePage.getTotalElements();

        BigDecimal highestAmount = BigDecimal.ZERO;
        String highestDate = "N/A";
        if (!incomes.isEmpty()) {
            Transaction maxTx = incomes.stream()
                    .max(java.util.Comparator.comparing(Transaction::getAmount))
                    .orElse(null);
            if (maxTx != null) {
                highestAmount = maxTx.getAmount();
                highestDate = maxTx.getTransactionDate() != null ? maxTx.getTransactionDate().toString() : "N/A";
            }
        }

        java.util.Map<String, BigDecimal> catSums = new java.util.HashMap<>();
        java.util.Map<String, String> catColors = new java.util.HashMap<>();
        for (Transaction t : incomes) {
            String catName = t.getCategory() != null ? t.getCategory().getName() : "Product Sales";
            String catColor = (t.getCategory() != null && t.getCategory().getColor() != null)
                    ? t.getCategory().getColor() : "#d0bcff";
            catSums.put(catName, catSums.getOrDefault(catName, BigDecimal.ZERO).add(t.getAmount()));
            catColors.put(catName, catColor);
        }

        List<RevenueSummaryDTO.RevenueSourceItem> sources = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, BigDecimal> entry : catSums.entrySet()) {
            double pct = totalRevenue.compareTo(BigDecimal.ZERO) > 0
                    ? entry.getValue().doubleValue() / totalRevenue.doubleValue() * 100.0
                    : 0.0;
            sources.add(new RevenueSummaryDTO.RevenueSourceItem(
                    entry.getKey(),
                    entry.getValue(),
                    Math.round(pct * 10.0) / 10.0,
                    catColors.getOrDefault(entry.getKey(), "#d0bcff")
            ));
        }

        List<RevenueSummaryDTO.TopProductItem> topProducts = List.of(
                new RevenueSummaryDTO.TopProductItem("AFAB Pro Plan", new BigDecimal("8450.00"), 45.0, "#d0bcff"),
                new RevenueSummaryDTO.TopProductItem("AI Assistant Add-on", new BigDecimal("6320.00"), 25.0, "#4edea3"),
                new RevenueSummaryDTO.TopProductItem("Financial Reports", new BigDecimal("4230.00"), 20.0, "#ffb95f")
        );

        List<RevenueSummaryDTO.DailyOverviewPoint> dailyOverview = List.of();

        return new RevenueSummaryDTO(
                totalRevenue,
                grossRevenue,
                discounts,
                refunds,
                netRevenue,
                avgPerDay,
                highestAmount,
                highestDate,
                totalInvoices,
                currency,
                sources,
                topProducts,
                dailyOverview
        );
    }

    @Transactional(readOnly = true)
    public InvoiceSummaryDTO getInvoiceSummary(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        Page<Transaction> incomePage = transactionRepository.searchTransactions(
                business.getId(), "INCOME", null, null, null, null, null, null, null, PageRequest.of(0, 100)
        );
        List<Transaction> invoices = incomePage.getContent();
        long totalInvoices = incomePage.getTotalElements();

        long paidCount = 0;
        long pendingCount = 0;
        long overdueCount = 0;

        BigDecimal paidAmount = BigDecimal.ZERO;
        BigDecimal pendingAmount = BigDecimal.ZERO;
        BigDecimal overdueAmount = BigDecimal.ZERO;
        BigDecimal totalInvoiceAmount = BigDecimal.ZERO;

        for (Transaction t : invoices) {
            totalInvoiceAmount = totalInvoiceAmount.add(t.getAmount());
            if ("COMPLETED".equalsIgnoreCase(t.getStatus()) || "PAID".equalsIgnoreCase(t.getStatus())) {
                paidCount++;
                paidAmount = paidAmount.add(t.getAmount());
            } else if ("PENDING".equalsIgnoreCase(t.getStatus())) {
                pendingCount++;
                pendingAmount = pendingAmount.add(t.getAmount());
            } else {
                overdueCount++;
                overdueAmount = overdueAmount.add(t.getAmount());
            }
        }

        double paidPct = totalInvoiceAmount.compareTo(BigDecimal.ZERO) > 0
                ? paidAmount.doubleValue() / totalInvoiceAmount.doubleValue() * 100.0 : 0.0;
        double pendingPct = totalInvoiceAmount.compareTo(BigDecimal.ZERO) > 0
                ? pendingAmount.doubleValue() / totalInvoiceAmount.doubleValue() * 100.0 : 0.0;
        double overduePct = totalInvoiceAmount.compareTo(BigDecimal.ZERO) > 0
                ? overdueAmount.doubleValue() / totalInvoiceAmount.doubleValue() * 100.0 : 0.0;

        List<InvoiceSummaryDTO.StatusBreakdownItem> breakdown = List.of(
                new InvoiceSummaryDTO.StatusBreakdownItem("Paid", paidAmount, Math.round(paidPct * 10.0) / 10.0, "#4edea3"),
                new InvoiceSummaryDTO.StatusBreakdownItem("Pending", pendingAmount, Math.round(pendingPct * 10.0) / 10.0, "#ffb95f"),
                new InvoiceSummaryDTO.StatusBreakdownItem("Overdue", overdueAmount, Math.round(overduePct * 10.0) / 10.0, "#ffb4ab")
        );

        List<InvoiceSummaryDTO.UpcomingInvoiceItem> upcomingList = List.of(
                new InvoiceSummaryDTO.UpcomingInvoiceItem("INV-1244", "AI Assistant Add-on", "billing@aiassist.com", "May 24, 2024", new BigDecimal("1250.00")),
                new InvoiceSummaryDTO.UpcomingInvoiceItem("INV-1243", "Financial Reports", "finance@reports.com", "May 23, 2024", new BigDecimal("850.00")),
                new InvoiceSummaryDTO.UpcomingInvoiceItem("INV-1242", "Consulting Service", "contact@consult.com", "May 22, 2024", new BigDecimal("3200.00"))
        );

        return new InvoiceSummaryDTO(
                totalInvoices,
                paidCount,
                pendingCount,
                overdueCount,
                totalInvoiceAmount,
                paidAmount,
                pendingAmount,
                overdueAmount,
                currency,
                breakdown,
                upcomingList
        );
    }

    private TransactionDTO mapToDTO(Transaction tx) {
        Category cat = tx.getCategory();
        String curr = tx.getCurrency();
        if ((curr == null || curr.isBlank()) && tx.getBusiness() != null) {
            curr = tx.getBusiness().getCurrency();
        }
        if (curr == null || curr.isBlank()) curr = "USD";

        TransactionDTO dto = new TransactionDTO();
        dto.setId(tx.getId());
        dto.setType(tx.getType());
        dto.setAmount(tx.getAmount());
        dto.setCurrency(curr);
        dto.setDescription(tx.getDescription());
        dto.setTransactionDate(tx.getTransactionDate());
        dto.setPaymentMethod(tx.getPaymentMethod());
        dto.setStatus(tx.getStatus());
        dto.setCategoryName(cat != null ? cat.getName() : "Uncategorized");
        dto.setCategoryColor(cat != null && cat.getColor() != null ? cat.getColor() : "#6b7280");
        dto.setCategoryIcon(cat != null && cat.getIcon() != null ? cat.getIcon() : "Tag");
        dto.setCategoryId(cat != null ? cat.getId() : null);
        dto.setNotes(tx.getNotes());
        dto.setTaxDeductible(tx.getTaxDeductible());
        dto.setTaxRate(tx.getTaxRate());
        dto.setIsSplit(tx.getIsSplit());
        dto.setParentTransactionId(tx.getParentTransaction() != null ? tx.getParentTransaction().getId() : null);
        dto.setCreatedAt(tx.getCreatedAt());
        dto.setUpdatedAt(tx.getUpdatedAt());

        // Map split items if any
        if (tx.getSplitItems() != null && !tx.getSplitItems().isEmpty()) {
            dto.setSplitItems(tx.getSplitItems().stream()
                    .filter(item -> item.getDeletedAt() == null)
                    .map(item -> new SplitItemDTO(
                            item.getId(),
                            item.getCategory() != null ? item.getCategory().getId() : null,
                            item.getCategory() != null ? item.getCategory().getName() : "Uncategorized",
                            item.getCategory() != null && item.getCategory().getColor() != null ? item.getCategory().getColor() : "#8b5cf6",
                            item.getCategory() != null && item.getCategory().getIcon() != null ? item.getCategory().getIcon() : "Tag",
                            item.getAmount(),
                            item.getDescription()
                    ))
                    .collect(Collectors.toList()));
        }

        // Anomaly Detection: check potential duplicates (±2 days) and price hikes
        if (tx.getBusiness() != null && tx.getTransactionDate() != null) {
            try {
                LocalDate from = tx.getTransactionDate().minusDays(2);
                LocalDate to = tx.getTransactionDate().plusDays(2);
                List<Transaction> dups = transactionRepository.findPotentialDuplicates(
                        tx.getBusiness().getId(), tx.getId(), tx.getAmount(), tx.getDescription(), from, to
                );
                dto.setPotentialDuplicate(!dups.isEmpty());

                if ("EXPENSE".equalsIgnoreCase(tx.getType())) {
                    List<Transaction> past = transactionRepository.findPastExpensesByDescription(
                            tx.getBusiness().getId(), tx.getDescription(), tx.getTransactionDate(), PageRequest.of(0, 1)
                    );
                    if (!past.isEmpty()) {
                        BigDecimal prev = past.get(0).getAmount();
                        if (prev != null && prev.compareTo(BigDecimal.ZERO) > 0 && tx.getAmount().compareTo(prev) > 0) {
                            BigDecimal diff = tx.getAmount().subtract(prev);
                            BigDecimal hikePct = diff.divide(prev, 4, java.math.RoundingMode.HALF_UP)
                                    .multiply(new BigDecimal("100"));
                            if (hikePct.compareTo(new BigDecimal("5.0")) >= 0) {
                                dto.setPriceHikePercentage(hikePct.setScale(1, java.math.RoundingMode.HALF_UP));
                            }
                        }
                    }
                }
            } catch (Exception ignored) {
                // Non-blocking enrichment
            }
        }

        return dto;
    }
}
