package com.afab.finance.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Category;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.CreateTransactionRequest;
import com.afab.finance.dto.TransactionDTO;
import com.afab.finance.dto.UpdateTransactionRequest;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CurrentBusinessService currentBusinessService;

    @Mock
    private CategoryService categoryService;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private TransactionService transactionService;

    private Business testBusiness;
    private UUID businessId;
    private final String userEmail = "owner@afab.test";

    @BeforeEach
    void setUp() {
        businessId = UUID.randomUUID();
        testBusiness = new Business();
        testBusiness.setId(businessId);
        testBusiness.setName("AFAB Ventures");
        testBusiness.setCurrency("USD");
    }

    @Test
    @DisplayName("createTransaction: succeeds when valid category and type match")
    void testCreateTransactionSuccess() {
        UUID catId = UUID.randomUUID();
        Category category = new Category();
        category.setId(catId);
        category.setName("Software Subscriptions");
        category.setType("EXPENSE");
        category.setBusiness(testBusiness);

        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE");
        request.setAmount(new BigDecimal("150.0000"));
        request.setDescription("GitHub Enterprise");
        request.setCategoryId(catId);
        request.setTransactionDate(LocalDate.now());
        request.setPaymentMethod("CREDIT_CARD");

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(category));

        when(transactionRepository.save(any(Transaction.class))).thenAnswer(invocation -> {
            Transaction saved = invocation.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        TransactionDTO result = transactionService.createTransaction(userEmail, request);

        assertThat(result).isNotNull();
        assertThat(result.getDescription()).isEqualTo("GitHub Enterprise");
        assertThat(result.getAmount()).isEqualByComparingTo("150.0000");
        assertThat(result.getType()).isEqualTo("EXPENSE");
        assertThat(result.getCategoryName()).isEqualTo("Software Subscriptions");

        verify(transactionRepository, times(1)).save(any(Transaction.class));
    }

    @Test
    @DisplayName("createTransaction: throws ResourceNotFoundException when category does not exist")
    void testCreateTransactionCategoryNotFound() {
        UUID unknownCatId = UUID.randomUUID();
        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE");
        request.setAmount(new BigDecimal("50.00"));
        request.setDescription("Lunch");
        request.setCategoryId(unknownCatId);
        request.setTransactionDate(LocalDate.now());

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(unknownCatId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.createTransaction(userEmail, request))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Category not found with ID");

        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    @DisplayName("createTransaction: Fix F5 - throws ForbiddenException when category belongs to another business")
    void testCreateTransactionCategoryCrossTenantForbidden() {
        UUID crossTenantCatId = UUID.randomUUID();
        Business otherBusiness = new Business();
        otherBusiness.setId(UUID.randomUUID());
        otherBusiness.setName("Competitor Ltd");

        Category foreignCategory = new Category();
        foreignCategory.setId(crossTenantCatId);
        foreignCategory.setName("Private Stash");
        foreignCategory.setType("EXPENSE");
        foreignCategory.setBusiness(otherBusiness);

        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE");
        request.setAmount(new BigDecimal("100.00"));
        request.setDescription("Supplies");
        request.setCategoryId(crossTenantCatId);
        request.setTransactionDate(LocalDate.now());

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(crossTenantCatId)).thenReturn(Optional.of(foreignCategory));

        assertThatThrownBy(() -> transactionService.createTransaction(userEmail, request))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Category belongs to another business");

        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    @DisplayName("createTransaction: Fix F5 - throws IllegalArgumentException when category type mismatches transaction type")
    void testCreateTransactionCategoryTypeMismatch() {
        UUID catId = UUID.randomUUID();
        Category incomeCategory = new Category();
        incomeCategory.setId(catId);
        incomeCategory.setName("Client Invoicing");
        incomeCategory.setType("INCOME");
        incomeCategory.setBusiness(testBusiness);

        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE"); // Mismatched!
        request.setAmount(new BigDecimal("200.00"));
        request.setDescription("Vendor Fee");
        request.setCategoryId(catId);
        request.setTransactionDate(LocalDate.now());

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(categoryRepository.findById(catId)).thenReturn(Optional.of(incomeCategory));

        assertThatThrownBy(() -> transactionService.createTransaction(userEmail, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("does not match transaction type");

        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    @DisplayName("deleteTransaction: Decision D6 - sets deletedAt timestamp (soft delete)")
    void testDeleteTransactionSoftDelete() {
        UUID txId = UUID.randomUUID();
        Transaction activeTx = new Transaction();
        activeTx.setId(txId);
        activeTx.setBusiness(testBusiness);
        activeTx.setDescription("Server cost");
        activeTx.setDeletedAt(null);

        User testUser = new User();
        testUser.setId(UUID.randomUUID());
        testUser.setEmail(userEmail);

        when(currentBusinessService.getCurrentUser(userEmail)).thenReturn(testUser);
        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(transactionRepository.findActiveById(txId)).thenReturn(Optional.of(activeTx));

        transactionService.deleteTransaction(userEmail, txId);

        ArgumentCaptor<Transaction> captor = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository).save(captor.capture());

        Transaction savedTx = captor.getValue();
        assertThat(savedTx.getDeletedAt()).isNotNull();
        verify(transactionRepository, never()).delete(any());
        verify(auditService, times(1)).log(eq(testUser), eq("DELETE"), eq("Transaction"), eq(txId), isNull());
    }

    @Test
    @DisplayName("updateTransaction: updates description and amount correctly")
    void testUpdateTransactionSuccess() {
        UUID txId = UUID.randomUUID();
        Transaction existingTx = new Transaction();
        existingTx.setId(txId);
        existingTx.setBusiness(testBusiness);
        existingTx.setType("EXPENSE");
        existingTx.setAmount(new BigDecimal("100.00"));
        existingTx.setDescription("Old Description");
        existingTx.setTransactionDate(LocalDate.of(2026, 1, 1));
        existingTx.setStatus("PENDING");

        UpdateTransactionRequest updateReq = new UpdateTransactionRequest();
        updateReq.setDescription("Updated Description");
        updateReq.setAmount(new BigDecimal("125.5000"));
        updateReq.setStatus("COMPLETED");

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(transactionRepository.findActiveById(txId)).thenReturn(Optional.of(existingTx));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TransactionDTO updated = transactionService.updateTransaction(userEmail, txId, updateReq);

        assertThat(updated.getDescription()).isEqualTo("Updated Description");
        assertThat(updated.getAmount()).isEqualByComparingTo("125.5000");
        assertThat(updated.getStatus()).isEqualTo("COMPLETED");
    }

    @Test
    @DisplayName("createTransaction: supports taxDeductible and taxRate")
    void testCreateTransactionWithTaxDeductible() {
        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE");
        request.setAmount(new BigDecimal("250.00"));
        request.setDescription("Client Business Dinner");
        request.setTransactionDate(LocalDate.now());
        request.setTaxDeductible(true);
        request.setTaxRate(new BigDecimal("19.00"));

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TransactionDTO result = transactionService.createTransaction(userEmail, request);

        assertThat(result.getTaxDeductible()).isTrue();
        assertThat(result.getTaxRate()).isEqualByComparingTo("19.00");
    }

    @Test
    @DisplayName("createTransaction: validates split items sum equals total amount")
    void testCreateTransactionSplitSumMismatch() {
        CreateTransactionRequest request = new CreateTransactionRequest();
        request.setType("EXPENSE");
        request.setAmount(new BigDecimal("100.00"));
        request.setDescription("Hardware and Software");
        request.setTransactionDate(LocalDate.now());

        com.afab.finance.dto.SplitRequestItem item1 = new com.afab.finance.dto.SplitRequestItem(UUID.randomUUID(), new BigDecimal("60.00"), "Part 1");
        com.afab.finance.dto.SplitRequestItem item2 = new com.afab.finance.dto.SplitRequestItem(UUID.randomUUID(), new BigDecimal("30.00"), "Part 2"); // sum is 90, not 100
        request.setSplitItems(java.util.List.of(item1, item2));

        when(currentBusinessService.getCurrentBusiness(userEmail)).thenReturn(testBusiness);

        assertThatThrownBy(() -> transactionService.createTransaction(userEmail, request))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("must equal total transaction amount");
    }
}
