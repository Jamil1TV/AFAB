package com.afab.security;

import com.afab.business.*;
import com.afab.business.dto.UpdateBusinessRequest;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.currency.CurrencyController;
import com.afab.finance.currency.CurrencyConversionService;
import com.afab.finance.currency.ExchangeRateService;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.UpdateCategoryRequest;
import com.afab.finance.dto.UpdateTransactionRequest;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.CategoryService;
import com.afab.finance.service.TransactionService;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TenantIsolationTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private CategoryService categoryServiceMock;
    @Mock private AuditService auditService;
    @Mock private FinanceStatsService financeStatsService;
    @Mock private BusinessRepository businessRepository;
    @Mock private BusinessMemberRepository businessMemberRepository;
    @Mock private UserRepository userRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private CurrencyConversionService currencyConversionService;

    private TransactionService transactionService;
    private CategoryService categoryService;
    private BusinessController businessController;
    private CurrencyController currencyController;

    private User userA;
    private Business businessA;
    private Business businessB;
    private Transaction txInBusinessB;
    private Category categoryInBusinessB;

    @BeforeEach
    void setUp() {
        transactionService = new TransactionService(
                transactionRepository, categoryRepository, currentBusinessService,
                categoryServiceMock, auditService, financeStatsService, exchangeRateService
        );
        categoryService = new CategoryService(categoryRepository, currentBusinessService);
        businessController = new BusinessController(
                businessRepository, businessMemberRepository, userRepository, currentBusinessService, auditService
        );
        currencyController = new CurrencyController(
                exchangeRateService, currencyConversionService, currentBusinessService
        );

        userA = new User("Alice", "A", "alice@biz-a.com", "hash");
        userA.setId(UUID.randomUUID());
        userA.setStatus("ACTIVE");

        businessA = new Business(userA, "Business A", "USD");
        businessA.setId(UUID.randomUUID());

        businessB = new Business(new User("Bob", "B", "bob@biz-b.com", "hash"), "Business B", "EUR");
        businessB.setId(UUID.randomUUID());

        txInBusinessB = new Transaction();
        txInBusinessB.setId(UUID.randomUUID());
        txInBusinessB.setBusiness(businessB);
        txInBusinessB.setType("EXPENSE");
        txInBusinessB.setAmount(new BigDecimal("500.00"));
        txInBusinessB.setCurrency("EUR");
        txInBusinessB.setDescription("Secret Biz B Expense");
        txInBusinessB.setTransactionDate(LocalDate.now());

        categoryInBusinessB = new Category();
        categoryInBusinessB.setId(UUID.randomUUID());
        categoryInBusinessB.setBusiness(businessB);
        categoryInBusinessB.setName("Secret Biz B Cat");
        categoryInBusinessB.setType("EXPENSE");
    }

    @Test
    @DisplayName("Business A cannot read, update, or delete Business B's transactions")
    void businessACannotAccessBusinessBTransactions() {
        when(currentBusinessService.getCurrentBusiness("alice@biz-a.com")).thenReturn(businessA);
        when(currentBusinessService.getCurrentUser("alice@biz-a.com")).thenReturn(userA);
        when(transactionRepository.findActiveById(txInBusinessB.getId())).thenReturn(Optional.of(txInBusinessB));

        assertThatThrownBy(() -> transactionService.getTransactionById("alice@biz-a.com", txInBusinessB.getId()))
                .isInstanceOf(ForbiddenException.class);

        UpdateTransactionRequest updateReq = new UpdateTransactionRequest();
        updateReq.setDescription("Tampered");
        assertThatThrownBy(() -> transactionService.updateTransaction("alice@biz-a.com", txInBusinessB.getId(), updateReq))
                .isInstanceOf(ForbiddenException.class);

        assertThatThrownBy(() -> transactionService.deleteTransaction("alice@biz-a.com", txInBusinessB.getId()))
                .isInstanceOf(ForbiddenException.class);

        verify(transactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Business A cannot modify or delete Business B's custom categories")
    void businessACannotMutateBusinessBCategories() {
        when(currentBusinessService.getCurrentBusiness("alice@biz-a.com")).thenReturn(businessA);
        when(categoryRepository.findById(categoryInBusinessB.getId())).thenReturn(Optional.of(categoryInBusinessB));

        UpdateCategoryRequest req = new UpdateCategoryRequest();
        req.setName("Hijacked");
        assertThatThrownBy(() -> categoryService.updateCategory("alice@biz-a.com", categoryInBusinessB.getId(), req))
                .isInstanceOf(ForbiddenException.class);

        assertThatThrownBy(() -> categoryService.deleteCategory("alice@biz-a.com", categoryInBusinessB.getId()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("Business A cannot access Business B settings or member list; removed member is also blocked")
    void businessACannotAccessBusinessBSettingsOrMembers() {
        Authentication auth = mock(Authentication.class);
        when(auth.getName()).thenReturn("alice@biz-a.com");
        when(currentBusinessService.getCurrentUser("alice@biz-a.com")).thenReturn(userA);
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(businessB.getId(), userA.getId()))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> businessController.getBusiness(businessB.getId(), auth))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> businessController.listMembers(businessB.getId(), auth))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> businessController.updateBusiness(businessB.getId(), new UpdateBusinessRequest(), auth))
                .isInstanceOf(ForbiddenException.class);

        // Removed member of Business A is also rejected
        BusinessMember removedMember = new BusinessMember(businessA, userA, "ADMIN", "REMOVED");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(businessA.getId(), userA.getId()))
                .thenReturn(Optional.of(removedMember));
        assertThatThrownBy(() -> businessController.getBusiness(businessA.getId(), auth))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("Non-admin MEMBER cannot change business base currency")
    void nonAdminCannotChangeBusinessCurrency() {
        Authentication auth = mock(Authentication.class);
        when(auth.getName()).thenReturn("alice@biz-a.com");
        when(currentBusinessService.getCurrentUser("alice@biz-a.com")).thenReturn(userA);
        when(currentBusinessService.requireAdminOrOwnerBusiness("alice@biz-a.com"))
                .thenThrow(new ForbiddenException("Only business owners and admins can perform this action."));

        assertThatThrownBy(() -> currencyController.changeBusinessCurrency(
                auth, new CurrencyController.ChangeCurrencyRequest("EUR", false)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("Legitimate Business A member can read their own transaction")
    void legitimateMemberCanReadOwnTransaction() {
        Transaction ownTx = new Transaction();
        ownTx.setId(UUID.randomUUID());
        ownTx.setBusiness(businessA);
        ownTx.setType("INCOME");
        ownTx.setAmount(new BigDecimal("250.00"));
        ownTx.setCurrency("USD");
        ownTx.setDescription("Client Payment");
        ownTx.setTransactionDate(LocalDate.now());

        when(currentBusinessService.getCurrentBusiness("alice@biz-a.com")).thenReturn(businessA);
        when(transactionRepository.findActiveById(ownTx.getId())).thenReturn(Optional.of(ownTx));

        var dto = transactionService.getTransactionById("alice@biz-a.com", ownTx.getId());
        assertThat(dto.getId()).isEqualTo(ownTx.getId());
        assertThat(dto.getDescription()).isEqualTo("Client Payment");
    }
}
