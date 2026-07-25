package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.*;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;

    public TransactionService(TransactionRepository transactionRepository,
                              CategoryRepository categoryRepository,
                              UserRepository userRepository,
                              BusinessRepository businessRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public TransactionResponseDTO getTransactions(String userEmail, String type, UUID categoryId, String search, int page, int size) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Page<Transaction> txPage = transactionRepository.searchTransactions(
                business.getId(),
                (type != null && !type.isBlank()) ? type.toUpperCase() : null,
                categoryId,
                (search != null && !search.isBlank()) ? search.trim() : null,
                PageRequest.of(page, size)
        );

        List<TransactionDTO> dtos = txPage.getContent().stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());

        BigDecimal totalInflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "INCOME");
        BigDecimal totalOutflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");
        BigDecimal netBalance = totalInflow.subtract(totalOutflow);

        return new TransactionResponseDTO(
                dtos,
                txPage.getNumber(),
                txPage.getSize(),
                txPage.getTotalElements(),
                txPage.getTotalPages(),
                totalInflow,
                totalOutflow,
                netBalance,
                (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD"
        );
    }

    @Transactional
    public TransactionDTO createTransaction(String userEmail, CreateTransactionRequest request) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Transaction tx = new Transaction();
        tx.setBusiness(business);
        tx.setType(request.getType().toUpperCase());
        tx.setAmount(request.getAmount());
        tx.setCurrency((business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD");
        tx.setDescription(request.getDescription());
        tx.setTransactionDate(request.getTransactionDate());
        tx.setPaymentMethod(request.getPaymentMethod() != null ? request.getPaymentMethod() : "BANK_TRANSFER");
        tx.setStatus(request.getStatus() != null ? request.getStatus() : "COMPLETED");
        tx.setNotes(request.getNotes());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId()).orElse(null);
            tx.setCategory(category);
        }

        tx = transactionRepository.save(tx);
        return mapToDTO(tx);
    }

    @Transactional
    public void deleteTransaction(String userEmail, UUID transactionId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found"));

        if (!tx.getBusiness().getId().equals(business.getId())) {
            throw new IllegalArgumentException("Unauthorized transaction access");
        }

        transactionRepository.delete(tx);
    }

    @Transactional(readOnly = true)
    public List<CategoryDTO> getCategories(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        return categoryRepository.findAllForBusiness(business.getId()).stream()
                .map(c -> new CategoryDTO(c.getId(), c.getName(), c.getType(), c.getIcon(), c.getColor()))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ExpenseSummaryDTO getExpenseSummary(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        BigDecimal totalExpenses = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");

        BigDecimal avgPerDay = totalExpenses.compareTo(BigDecimal.ZERO) > 0
                ? totalExpenses.divide(new BigDecimal("30"), 2, java.math.RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        Page<Transaction> expensesPage = transactionRepository.searchTransactions(
                business.getId(), "EXPENSE", null, null, PageRequest.of(0, 100)
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
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

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
                business.getId(), "INCOME", null, null, PageRequest.of(0, 100)
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
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Business not found"));

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency() : "USD";

        Page<Transaction> incomePage = transactionRepository.searchTransactions(
                business.getId(), "INCOME", null, null, PageRequest.of(0, 100)
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

        return new TransactionDTO(
                tx.getId(),
                tx.getType(),
                tx.getAmount(),
                curr,
                tx.getDescription(),
                tx.getTransactionDate(),
                tx.getPaymentMethod(),
                tx.getStatus(),
                cat != null ? cat.getName() : "Uncategorized",
                cat != null && cat.getColor() != null ? cat.getColor() : "#6b7280",
                cat != null && cat.getIcon() != null ? cat.getIcon() : "Tag",
                cat != null ? cat.getId() : null
        );
    }
}
