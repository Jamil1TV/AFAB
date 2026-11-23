package com.afab.budgets.service;

import com.afab.budgets.domain.Budget;
import com.afab.budgets.domain.BudgetPeriodType;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetRequest;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.repository.BudgetRepository;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Category;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Business Budgets Service.
 * Computes exact spending, remaining capacity, over-budget amounts, percentage consumed,
 * and deterministic rule-based alerts directly from real COMPLETED EXPENSE transactions.
 */
@Service
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final CurrentBusinessService currentBusinessService;
    private final AuditService auditService;

    public BudgetService(
            BudgetRepository budgetRepository,
            CategoryRepository categoryRepository,
            TransactionRepository transactionRepository,
            CurrentBusinessService currentBusinessService,
            AuditService auditService
    ) {
        this.budgetRepository = budgetRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.currentBusinessService = currentBusinessService;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<BudgetDTO> list(String userEmail, boolean includeArchived) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return budgetRepository.findAllByBusinessId(business.getId(), includeArchived).stream()
                .map(this::evaluateBudget)
                .toList();
    }

    @Transactional(readOnly = true)
    public BudgetDTO getById(String userEmail, UUID id) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Budget budget = loadOwnedBudget(id, business.getId());
        return evaluateBudget(budget);
    }

    @Transactional(readOnly = true)
    public BudgetSummaryDTO getSummary(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return buildSummaryForBusiness(business, LocalDate.now());
    }

    @Transactional(readOnly = true)
    public BudgetSummaryDTO buildSummaryForBusiness(Business business, LocalDate referenceDate) {
        String currency = resolveBusinessCurrency(business);
        List<Budget> activeBudgets = budgetRepository.findCurrentActiveByBusinessId(business.getId(), referenceDate);
        List<BudgetDTO> evaluated = activeBudgets.stream()
                .map(this::evaluateBudget)
                .toList();

        int approaching = 0;
        int overBudget = 0;
        BigDecimal totalBudgeted = BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP);
        BigDecimal totalSpent = BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP);

        for (BudgetDTO b : evaluated) {
            totalBudgeted = totalBudgeted.add(b.budgetAmount());
            totalSpent = totalSpent.add(b.actualSpending());
            if ("OVER_BUDGET".equals(b.alertLevel())) {
                overBudget++;
            } else if ("APPROACHING".equals(b.alertLevel())) {
                approaching++;
            }
        }

        BigDecimal totalRemaining = totalBudgeted.subtract(totalSpent).max(BigDecimal.ZERO).setScale(4, RoundingMode.HALF_UP);
        return new BudgetSummaryDTO(
                currency,
                evaluated.size(),
                approaching,
                overBudget,
                totalBudgeted,
                totalSpent,
                totalRemaining,
                evaluated
        );
    }

    @Transactional
    public BudgetDTO create(String userEmail, BudgetRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        String businessCurrency = resolveBusinessCurrency(business);
        String requestedCurrency = (request.getCurrency() != null && !request.getCurrency().isBlank())
                ? request.getCurrency().toUpperCase(Locale.ROOT).trim()
                : businessCurrency;

        if (!requestedCurrency.equalsIgnoreCase(businessCurrency)) {
            throw new IllegalArgumentException(
                    "Budget currency (" + requestedCurrency + ") must match business base currency (" + businessCurrency + ") for accurate spending comparison.");
        }

        Category category = resolveExpenseCategory(request.getCategoryId(), business.getId());
        BudgetPeriodType periodType = parsePeriodType(request.getPeriodType());
        DateWindow window = resolveDateWindow(periodType, request.getStartDate(), request.getEndDate());

        Budget budget = new Budget();
        budget.setBusiness(business);
        budget.setName(request.getName().trim());
        budget.setAmount(request.getAmount().setScale(4, RoundingMode.HALF_UP));
        budget.setCurrency(businessCurrency);
        budget.setCategory(category);
        budget.setPeriodType(periodType);
        budget.setStartDate(window.start());
        budget.setEndDate(window.end());
        budget.setAlertThresholdPercent(request.getAlertThresholdPercent() != null ? request.getAlertThresholdPercent() : 80);
        budget.setDescription(request.getDescription() != null && !request.getDescription().isBlank() ? request.getDescription().trim() : null);
        budget.setStatus("ACTIVE");

        budget = budgetRepository.save(budget);
        auditService.log(user, "CREATE", "Budget", budget.getId(), null);
        return evaluateBudget(budget);
    }

    @Transactional
    public BudgetDTO update(String userEmail, UUID id, BudgetRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Budget budget = loadOwnedBudget(id, business.getId());

        String businessCurrency = resolveBusinessCurrency(business);
        if (request.getCurrency() != null && !request.getCurrency().isBlank()
                && !request.getCurrency().trim().equalsIgnoreCase(budget.getCurrency())) {
            throw new IllegalArgumentException("Budget currency cannot diverge from business base currency (" + businessCurrency + ").");
        }

        Category category = resolveExpenseCategory(request.getCategoryId(), business.getId());
        BudgetPeriodType periodType = parsePeriodType(request.getPeriodType());
        DateWindow window = resolveDateWindow(
                periodType,
                request.getStartDate() != null ? request.getStartDate() : budget.getStartDate(),
                request.getEndDate() != null ? request.getEndDate() : budget.getEndDate()
        );

        budget.setName(request.getName().trim());
        budget.setAmount(request.getAmount().setScale(4, RoundingMode.HALF_UP));
        budget.setCategory(category);
        budget.setPeriodType(periodType);
        budget.setStartDate(window.start());
        budget.setEndDate(window.end());
        if (request.getAlertThresholdPercent() != null) {
            budget.setAlertThresholdPercent(request.getAlertThresholdPercent());
        }
        budget.setDescription(request.getDescription() != null && !request.getDescription().isBlank() ? request.getDescription().trim() : null);

        budget = budgetRepository.save(budget);
        auditService.log(user, "UPDATE", "Budget", budget.getId(), null);
        return evaluateBudget(budget);
    }

    @Transactional
    public void archive(String userEmail, UUID id) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Budget budget = loadOwnedBudget(id, business.getId());

        budget.setStatus("ARCHIVED");
        budget.setArchivedAt(Instant.now());
        budgetRepository.save(budget);
        auditService.log(user, "ARCHIVE", "Budget", budget.getId(), null);
    }

    public BudgetDTO evaluateBudget(Budget budget) {
        UUID businessId = budget.getBusiness().getId();
        BigDecimal actualSpending;
        if (budget.getCategory() != null) {
            actualSpending = transactionRepository.sumCompletedExpenseByBusinessAndCategoryAndDateRange(
                    businessId,
                    budget.getCategory().getId(),
                    budget.getStartDate(),
                    budget.getEndDate()
            );
        } else {
            actualSpending = transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                    businessId,
                    "EXPENSE",
                    budget.getStartDate(),
                    budget.getEndDate()
            );
        }
        if (actualSpending == null) {
            actualSpending = BigDecimal.ZERO;
        }

        BigDecimal limit = budget.getAmount().setScale(4, RoundingMode.HALF_UP);
        BigDecimal spent = actualSpending.setScale(4, RoundingMode.HALF_UP);
        BigDecimal remaining = limit.subtract(spent).max(BigDecimal.ZERO).setScale(4, RoundingMode.HALF_UP);
        BigDecimal overBudget = spent.subtract(limit).max(BigDecimal.ZERO).setScale(4, RoundingMode.HALF_UP);

        BigDecimal pctConsumed = limit.compareTo(BigDecimal.ZERO) > 0
                ? spent.multiply(BigDecimal.valueOf(100)).divide(limit, 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);

        String alertLevel;
        if (spent.compareTo(limit) > 0) {
            alertLevel = "OVER_BUDGET";
        } else if (pctConsumed.compareTo(BigDecimal.valueOf(budget.getAlertThresholdPercent())) >= 0) {
            alertLevel = "APPROACHING";
        } else {
            alertLevel = "OK";
        }

        Category cat = budget.getCategory();
        return new BudgetDTO(
                budget.getId(),
                businessId,
                budget.getName(),
                limit,
                budget.getCurrency(),
                cat != null ? cat.getId() : null,
                cat != null ? cat.getName() : "All Expenses",
                cat != null && cat.getColor() != null ? cat.getColor() : "#8b5cf6",
                budget.getPeriodType() != null ? budget.getPeriodType().name() : BudgetPeriodType.MONTHLY.name(),
                budget.getStartDate(),
                budget.getEndDate(),
                budget.getAlertThresholdPercent(),
                budget.getDescription(),
                budget.getStatus(),
                spent,
                remaining,
                overBudget,
                pctConsumed,
                alertLevel,
                budget.getCreatedAt(),
                budget.getUpdatedAt()
        );
    }

    private Budget loadOwnedBudget(UUID id, UUID businessId) {
        Budget budget = budgetRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Budget not found: " + id));
        if (budget.getBusiness() == null || !budget.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Budget belongs to another business.");
        }
        return budget;
    }

    private Category resolveExpenseCategory(UUID categoryId, UUID businessId) {
        if (categoryId == null) {
            return null;
        }
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + categoryId));
        if (category.getBusiness() != null && !category.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Category belongs to another business.");
        }
        if (!"EXPENSE".equalsIgnoreCase(category.getType())) {
            throw new IllegalArgumentException("Budgets can only be scoped to EXPENSE categories.");
        }
        return category;
    }

    private BudgetPeriodType parsePeriodType(String raw) {
        if (raw == null || raw.isBlank()) {
            return BudgetPeriodType.MONTHLY;
        }
        return BudgetPeriodType.valueOf(raw.toUpperCase(Locale.ROOT).trim());
    }

    private DateWindow resolveDateWindow(BudgetPeriodType periodType, LocalDate start, LocalDate end) {
        LocalDate today = LocalDate.now();
        if (start != null && end != null) {
            if (end.isBefore(start)) {
                throw new IllegalArgumentException("Budget end date cannot be earlier than start date.");
            }
            return new DateWindow(start, end);
        }
        return switch (periodType) {
            case MONTHLY -> {
                YearMonth ym = start != null ? YearMonth.from(start) : YearMonth.from(today);
                yield new DateWindow(ym.atDay(1), ym.atEndOfMonth());
            }
            case QUARTERLY -> {
                LocalDate base = start != null ? start : today;
                int qStartMonth = ((base.getMonthValue() - 1) / 3) * 3 + 1;
                LocalDate qStart = LocalDate.of(base.getYear(), qStartMonth, 1);
                LocalDate qEnd = qStart.plusMonths(3).minusDays(1);
                yield new DateWindow(qStart, qEnd);
            }
            case YEARLY -> {
                int year = start != null ? start.getYear() : today.getYear();
                yield new DateWindow(LocalDate.of(year, 1, 1), LocalDate.of(year, 12, 31));
            }
            case CUSTOM -> throw new IllegalArgumentException("Both startDate and endDate are required for CUSTOM budget periods.");
        };
    }

    private String resolveBusinessCurrency(Business business) {
        return (business != null && business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency().toUpperCase(Locale.ROOT).trim()
                : "USD";
    }

    private record DateWindow(LocalDate start, LocalDate end) {}
}
