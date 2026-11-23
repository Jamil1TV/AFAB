package com.afab.business;

import com.afab.business.dto.UpdateBusinessRequest;
import com.afab.finance.currency.CurrencyConversionService;
import com.afab.finance.currency.ExchangeRateService;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.*;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.CategoryService;
import com.afab.finance.service.TransactionService;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.security.AuditService;
import com.afab.subscription.EntitlementService;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReadOnlyBusinessEnforcementTest {

    @Mock
    private TransactionRepository transactionRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private CurrentBusinessService currentBusinessService;
    @Mock
    private AuditService auditService;
    @Mock
    private FinanceStatsService financeStatsService;
    @Mock
    private ExchangeRateService exchangeRateService;
    @Mock
    private BusinessRepository businessRepository;
    @Mock
    private BusinessMemberRepository businessMemberRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private EntitlementService entitlementService;
    @Mock
    private Authentication authentication;

    private CategoryService categoryService;
    private TransactionService transactionService;
    private CurrencyConversionService currencyConversionService;
    private BusinessController businessController;

    private User testUser;
    private Business readOnlyBusiness;
    private final String userEmail = "owner@afab.test";

    @BeforeEach
    void setUp() {
        categoryService = new CategoryService(categoryRepository, currentBusinessService);
        transactionService = new TransactionService(
                transactionRepository,
                categoryRepository,
                currentBusinessService,
                categoryService,
                auditService,
                financeStatsService
        );
        currencyConversionService = new CurrencyConversionService(
                exchangeRateService,
                transactionRepository,
                businessRepository,
                auditService
        );
        businessController = new BusinessController(
                businessRepository,
                businessMemberRepository,
                userRepository,
                currentBusinessService,
                entitlementService
        );

        testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);

        readOnlyBusiness = new Business(testUser, "Archived Venture (Read-Only)", "USD");
        readOnlyBusiness.setId(UUID.randomUUID());
        readOnlyBusiness.setAccessMode("READ_ONLY");

        lenient().when(authentication.getName()).thenReturn(userEmail);
        lenient().when(currentBusinessService.getCurrentUser(userEmail)).thenReturn(testUser);
        lenient().when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(readOnlyBusiness);
    }

    @Test
    @DisplayName("Scenario 9: Rejects transaction create, update, and delete on READ_ONLY business with BUSINESS_READ_ONLY (403)")
    void testTransactionWritesBlockedOnReadOnlyBusiness() {
        CreateTransactionRequest createReq = new CreateTransactionRequest();
        createReq.setType("EXPENSE");
        createReq.setAmount(new BigDecimal("250.00"));
        createReq.setDescription("Server hosting");
        createReq.setTransactionDate(LocalDate.now());

        assertThatThrownBy(() -> transactionService.createTransaction(userEmail, createReq))
                .isInstanceOf(BusinessReadOnlyException.class)
                .hasMessageContaining("read-only mode");

        UpdateTransactionRequest updateReq = new UpdateTransactionRequest();
        updateReq.setDescription("Modified description");
        assertThatThrownBy(() -> transactionService.updateTransaction(userEmail, UUID.randomUUID(), updateReq))
                .isInstanceOf(BusinessReadOnlyException.class);

        assertThatThrownBy(() -> transactionService.deleteTransaction(userEmail, UUID.randomUUID()))
                .isInstanceOf(BusinessReadOnlyException.class);

        verify(transactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Scenario 9: Rejects category create, update, and delete on READ_ONLY business")
    void testCategoryWritesBlockedOnReadOnlyBusiness() {
        CreateCategoryRequest createCat = new CreateCategoryRequest();
        createCat.setName("Marketing");
        createCat.setType("EXPENSE");

        assertThatThrownBy(() -> categoryService.createCategory(userEmail, createCat))
                .isInstanceOf(BusinessReadOnlyException.class);

        UpdateCategoryRequest updateCat = new UpdateCategoryRequest();
        updateCat.setName("Updated Marketing");
        assertThatThrownBy(() -> categoryService.updateCategory(userEmail, UUID.randomUUID(), updateCat))
                .isInstanceOf(BusinessReadOnlyException.class);

        assertThatThrownBy(() -> categoryService.deleteCategory(userEmail, UUID.randomUUID()))
                .isInstanceOf(BusinessReadOnlyException.class);

        verify(categoryRepository, never()).save(any());
        verify(categoryRepository, never()).delete(any());
    }

    @Test
    @DisplayName("Scenario 9: Rejects business settings update, archive, and currency migration on READ_ONLY business")
    void testBusinessSettingsAndCurrencyMigrationBlockedOnReadOnlyBusiness() {
        BusinessMember ownerMember = new BusinessMember(readOnlyBusiness, testUser, "OWNER", "ACTIVE");
        when(businessMemberRepository.findWithBusinessByBusinessIdAndUserId(readOnlyBusiness.getId(), testUser.getId()))
                .thenReturn(Optional.of(ownerMember));

        UpdateBusinessRequest updateBiz = new UpdateBusinessRequest();
        updateBiz.setName("Attempted Rename");

        assertThatThrownBy(() -> businessController.updateBusiness(readOnlyBusiness.getId(), updateBiz, authentication))
                .isInstanceOf(BusinessReadOnlyException.class);

        assertThatThrownBy(() -> businessController.archiveBusiness(readOnlyBusiness.getId(), authentication))
                .isInstanceOf(BusinessReadOnlyException.class);

        assertThatThrownBy(() -> currencyConversionService.changeBusinessCurrency(
                testUser, readOnlyBusiness, "EUR", true))
                .isInstanceOf(BusinessReadOnlyException.class);

        verify(businessRepository, never()).save(any());
    }

    @Test
    @DisplayName("Scenario 8 & 17: Read-only business still allows reading historical transactions, categories, and summaries with all data intact")
    void testReadOnlyBusinessAllowsReadingHistoricalFinancialRecords() {
        Transaction historicalTx = new Transaction();
        historicalTx.setId(UUID.randomUUID());
        historicalTx.setBusiness(readOnlyBusiness);
        historicalTx.setType("INCOME");
        historicalTx.setAmount(new BigDecimal("4800.00"));
        historicalTx.setCurrency("USD");
        historicalTx.setDescription("Enterprise Invoice #104");
        historicalTx.setTransactionDate(LocalDate.now().minusDays(15));
        historicalTx.setStatus("COMPLETED");

        when(transactionRepository.searchTransactions(
                eq(readOnlyBusiness.getId()), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(historicalTx)));
        when(transactionRepository.sumAmountByBusinessAndType(readOnlyBusiness.getId(), "INCOME"))
                .thenReturn(new BigDecimal("4800.00"));
        when(transactionRepository.sumAmountByBusinessAndType(readOnlyBusiness.getId(), "EXPENSE"))
                .thenReturn(BigDecimal.ZERO);

        Category existingCat = new Category();
        existingCat.setId(UUID.randomUUID());
        existingCat.setBusiness(readOnlyBusiness);
        existingCat.setName("Consulting Revenue");
        existingCat.setType("INCOME");
        when(categoryRepository.findAllForBusiness(readOnlyBusiness.getId())).thenReturn(List.of(existingCat));

        TransactionResponseDTO txResponse = transactionService.getTransactions(userEmail, null, null, null, 0, 20);
        List<CategoryDTO> categories = categoryService.getCategories(userEmail);

        assertThat(txResponse.getContent()).hasSize(1);
        assertThat(txResponse.getContent().get(0).getDescription()).isEqualTo("Enterprise Invoice #104");
        assertThat(txResponse.getTotalInflow()).isEqualByComparingTo("4800.00");
        assertThat(categories).hasSize(1);
        assertThat(categories.get(0).getName()).isEqualTo("Consulting Revenue");
    }
}
