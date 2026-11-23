package com.afab.budgets;

import com.afab.budgets.domain.Budget;
import com.afab.budgets.domain.BudgetPeriodType;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetRequest;
import com.afab.budgets.repository.BudgetRepository;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.domain.Category;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BudgetServiceTest {

    @Mock private BudgetRepository budgetRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private AuditService auditService;

    private BudgetService budgetService;
    private Business business;
    private User user;

    @BeforeEach
    void setUp() {
        budgetService = new BudgetService(
                budgetRepository, categoryRepository, transactionRepository, currentBusinessService, auditService
        );
        user = new User();
        user.setId(UUID.randomUUID());
        user.setEmail("owner@afab.test");

        business = new Business();
        business.setId(UUID.randomUUID());
        business.setName("Tunis Digital");
        business.setCurrency("TND");
    }

    @Test
    void computesApproachingAlertWhenSpendingReaches85Percent() {
        Category marketing = new Category();
        marketing.setId(UUID.randomUUID());
        marketing.setName("Marketing");
        marketing.setType("EXPENSE");
        marketing.setColor("#8b5cf6");

        Budget budget = new Budget();
        budget.setId(UUID.randomUUID());
        budget.setBusiness(business);
        budget.setName("Marketing Q1");
        budget.setAmount(new BigDecimal("1000.0000"));
        budget.setCurrency("TND");
        budget.setCategory(marketing);
        budget.setPeriodType(BudgetPeriodType.MONTHLY);
        budget.setStartDate(LocalDate.of(2026, 3, 1));
        budget.setEndDate(LocalDate.of(2026, 3, 31));
        budget.setAlertThresholdPercent(80);

        when(transactionRepository.sumCompletedExpenseByBusinessAndCategoryAndDateRange(
                business.getId(), marketing.getId(), LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31)))
                .thenReturn(new BigDecimal("850.0000"));

        BudgetDTO evaluated = budgetService.evaluateBudget(budget);

        assertThat(evaluated.budgetAmount()).isEqualByComparingTo("1000.0000");
        assertThat(evaluated.actualSpending()).isEqualByComparingTo("850.0000");
        assertThat(evaluated.remainingAmount()).isEqualByComparingTo("150.0000");
        assertThat(evaluated.overBudgetAmount()).isEqualByComparingTo("0.0000");
        assertThat(evaluated.percentageConsumed()).isEqualByComparingTo("85.00");
        assertThat(evaluated.alertLevel()).isEqualTo("APPROACHING");
    }

    @Test
    void computesOverBudgetAlertWhenSpendingExceedsLimit() {
        Budget overall = new Budget();
        overall.setId(UUID.randomUUID());
        overall.setBusiness(business);
        overall.setName("Monthly OpEx");
        overall.setAmount(new BigDecimal("1000.0000"));
        overall.setCurrency("TND");
        overall.setCategory(null); // overall business expense budget
        overall.setPeriodType(BudgetPeriodType.MONTHLY);
        overall.setStartDate(LocalDate.of(2026, 3, 1));
        overall.setEndDate(LocalDate.of(2026, 3, 31));
        overall.setAlertThresholdPercent(80);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                business.getId(), "EXPENSE", LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31)))
                .thenReturn(new BigDecimal("1200.0000"));

        BudgetDTO evaluated = budgetService.evaluateBudget(overall);

        assertThat(evaluated.remainingAmount()).isEqualByComparingTo("0.0000");
        assertThat(evaluated.overBudgetAmount()).isEqualByComparingTo("200.0000");
        assertThat(evaluated.percentageConsumed()).isEqualByComparingTo("120.00");
        assertThat(evaluated.alertLevel()).isEqualTo("OVER_BUDGET");
    }

    @Test
    void rejectsMismatchedBudgetCurrencyAndIncomeCategories() {
        when(currentBusinessService.getCurrentUser("owner@afab.test")).thenReturn(user);
        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(business);

        BudgetRequest wrongCurrency = new BudgetRequest();
        wrongCurrency.setName("Bad Currency");
        wrongCurrency.setAmount(new BigDecimal("500"));
        wrongCurrency.setCurrency("EUR"); // business base is TND
        wrongCurrency.setPeriodType("MONTHLY");

        assertThatThrownBy(() -> budgetService.create("owner@afab.test", wrongCurrency))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("must match business base currency");

        Category incomeCat = new Category();
        incomeCat.setId(UUID.randomUUID());
        incomeCat.setType("INCOME");
        when(categoryRepository.findById(incomeCat.getId())).thenReturn(Optional.of(incomeCat));

        BudgetRequest incomeCatReq = new BudgetRequest();
        incomeCatReq.setName("Sales Budget");
        incomeCatReq.setAmount(new BigDecimal("500"));
        incomeCatReq.setCategoryId(incomeCat.getId());
        incomeCatReq.setPeriodType("MONTHLY");

        assertThatThrownBy(() -> budgetService.create("owner@afab.test", incomeCatReq))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("EXPENSE categories");
    }

    @Test
    void rejectsCrossTenantBudgetAccess() {
        Business otherBiz = new Business();
        otherBiz.setId(UUID.randomUUID());

        Budget foreignBudget = new Budget();
        foreignBudget.setId(UUID.randomUUID());
        foreignBudget.setBusiness(otherBiz);

        when(currentBusinessService.getCurrentBusiness("owner@afab.test")).thenReturn(business);
        when(budgetRepository.findActiveById(foreignBudget.getId())).thenReturn(Optional.of(foreignBudget));

        assertThatThrownBy(() -> budgetService.getById("owner@afab.test", foreignBudget.getId()))
                .isInstanceOf(ForbiddenException.class);
    }
}
