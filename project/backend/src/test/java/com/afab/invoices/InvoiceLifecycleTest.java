package com.afab.invoices;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.finance.currency.ExchangeRateService;
import com.afab.finance.currency.ExchangeRateService.FxQuote;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.CategoryService;
import com.afab.finance.service.TransactionService;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.invoices.domain.*;
import com.afab.invoices.dto.CreateInvoiceRequest;
import com.afab.invoices.dto.InvoiceDTO;
import com.afab.invoices.dto.RecordPaymentRequest;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.invoices.repository.PaymentRepository;
import com.afab.invoices.service.InvoiceNumberGenerator;
import com.afab.invoices.service.InvoiceService;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InvoiceLifecycleTest {

    @Mock private InvoiceRepository invoiceRepository;
    @Mock private PaymentRepository paymentRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private CategoryService categoryService;
    @Mock private FinanceStatsService financeStatsService;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private InvoiceNumberGenerator invoiceNumberGenerator;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private AuditService auditService;

    private TransactionService transactionService;
    private InvoiceService invoiceService;

    private User ownerA;
    private Business bizTnd;
    private Business bizOther;
    private Customer customerA;

    @BeforeEach
    void setUp() {
        transactionService = new TransactionService(
                transactionRepository, categoryRepository, currentBusinessService,
                categoryService, auditService, financeStatsService, exchangeRateService
        );
        invoiceService = new InvoiceService(
                invoiceRepository, paymentRepository, customerRepository,
                transactionRepository, transactionService, invoiceNumberGenerator,
                currentBusinessService, auditService
        );

        ownerA = new User("Lina", "Founder", "lina@biz.tn", "hash");
        ownerA.setId(UUID.randomUUID());

        bizTnd = new Business(ownerA, "Tunis Studio", "TND");
        bizTnd.setId(UUID.randomUUID());

        bizOther = new Business(new User("Other", "User", "other@biz.fr", "hash"), "Other Co", "EUR");
        bizOther.setId(UUID.randomUUID());

        customerA = new Customer();
        customerA.setId(UUID.randomUUID());
        customerA.setBusiness(bizTnd);
        customerA.setName("Euro Client SAS");
        customerA.setEmail("ap@euroclient.eu");
    }

    @Test
    @DisplayName("Creating and issuing an unpaid invoice NEVER creates an Income Transaction")
    void creatingAndIssuingUnpaidInvoiceDoesNotAffectIncome() {
        when(currentBusinessService.getCurrentUser("lina@biz.tn")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("lina@biz.tn")).thenReturn(bizTnd);
        when(customerRepository.findActiveById(customerA.getId())).thenReturn(Optional.of(customerA));
        when(invoiceNumberGenerator.nextInvoiceNumber(bizTnd.getId(), 2026)).thenReturn("INV-2026-0001");
        when(invoiceRepository.save(any(Invoice.class))).thenAnswer(inv -> {
            Invoice i = inv.getArgument(0);
            if (i.getId() == null) i.setId(UUID.randomUUID());
            return i;
        });

        CreateInvoiceRequest.InvoiceItemRequest line = new CreateInvoiceRequest.InvoiceItemRequest();
        line.setDescription("Design Sprint");
        line.setQuantity(new BigDecimal("2"));
        line.setUnitPrice(new BigDecimal("500.00"));
        line.setTaxRate(new BigDecimal("19.00"));

        CreateInvoiceRequest req = new CreateInvoiceRequest();
        req.setCustomerId(customerA.getId());
        req.setIssueDate(LocalDate.of(2026, 11, 1));
        req.setDueDate(LocalDate.of(2026, 11, 30));
        req.setCurrency("EUR");
        req.setDiscountAmount(new BigDecimal("50.00"));
        req.setItems(List.of(line));

        InvoiceDTO draft = invoiceService.createInvoice("lina@biz.tn", req);
        assertThat(draft.status()).isEqualTo("DRAFT");
        assertThat(draft.subtotal()).isEqualByComparingTo("1000.0000");
        assertThat(draft.taxAmount()).isEqualByComparingTo("190.0000");
        assertThat(draft.totalAmount()).isEqualByComparingTo("1140.0000");
        assertThat(draft.outstandingBalance()).isEqualByComparingTo("1140.0000");

        // Issue invoice -> UNPAID
        Invoice storedDraft = new Invoice();
        storedDraft.setId(draft.id());
        storedDraft.setBusiness(bizTnd);
        storedDraft.setCustomer(customerA);
        storedDraft.setInvoiceNumber("INV-2026-0001");
        storedDraft.setStatus(InvoiceStatus.DRAFT);
        storedDraft.setIssueDate(req.getIssueDate());
        storedDraft.setDueDate(req.getDueDate());
        storedDraft.setCurrency("EUR");
        storedDraft.setTotalAmount(new BigDecimal("1140.0000"));
        storedDraft.setPaidAmount(BigDecimal.ZERO);
        storedDraft.setOutstandingBalance(new BigDecimal("1140.0000"));

        when(invoiceRepository.findWithDetailsById(draft.id())).thenReturn(Optional.of(storedDraft));

        InvoiceDTO issued = invoiceService.issueInvoice("lina@biz.tn", draft.id(), false);
        assertThat(issued.status()).isEqualTo("UNPAID");

        // Critical accounting rule: ZERO income transactions created!
        verify(transactionRepository, never()).save(any());
        verify(paymentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Multiple partial payments transition UNPAID -> PARTIALLY_PAID -> PAID with immutable FX snapshots")
    void partialAndFullPaymentsCreateExactIncomeTransactionsWithFx() {
        UUID invId = UUID.randomUUID();
        Invoice inv = new Invoice();
        inv.setId(invId);
        inv.setBusiness(bizTnd);
        inv.setCustomer(customerA);
        inv.setInvoiceNumber("INV-2026-0002");
        inv.setStatus(InvoiceStatus.UNPAID);
        inv.setIssueDate(LocalDate.of(2026, 11, 1));
        inv.setDueDate(LocalDate.of(2026, 12, 1));
        inv.setCurrency("EUR");
        inv.setTotalAmount(new BigDecimal("1000.0000"));
        inv.setPaidAmount(BigDecimal.ZERO.setScale(4));
        inv.setOutstandingBalance(new BigDecimal("1000.0000"));

        when(currentBusinessService.getCurrentUser("lina@biz.tn")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("lina@biz.tn")).thenReturn(bizTnd);
        when(paymentRepository.findByBusinessIdAndInvoiceIdAndIdempotencyKey(any(), any(), any())).thenReturn(Optional.empty());
        when(invoiceRepository.findByIdForUpdate(invId)).thenReturn(Optional.of(inv));
        when(exchangeRateService.getRateQuote("EUR", "TND"))
                .thenReturn(new FxQuote("EUR", "TND", new BigDecimal("3.400000"), "LIVE_FEED", Instant.now()));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(i -> {
            Transaction t = i.getArgument(0);
            t.setId(UUID.randomUUID());
            return t;
        });
        when(paymentRepository.save(any(Payment.class))).thenAnswer(i -> {
            Payment p = i.getArgument(0);
            p.setId(UUID.randomUUID());
            return p;
        });

        // Payment 1: 400 EUR partial payment -> 1,360 TND
        RecordPaymentRequest p1 = new RecordPaymentRequest();
        p1.setAmount(new BigDecimal("400.00"));
        p1.setPaymentDate(LocalDate.of(2026, 11, 10));
        p1.setPaymentMethod("BANK_TRANSFER");

        var payDto1 = invoiceService.recordPayment("lina@biz.tn", invId, p1, "idem-pay-1");
        assertThat(inv.getStatus()).isEqualTo(InvoiceStatus.PARTIALLY_PAID);
        assertThat(inv.getPaidAmount()).isEqualByComparingTo("400.0000");
        assertThat(inv.getOutstandingBalance()).isEqualByComparingTo("600.0000");
        assertThat(payDto1.convertedBaseAmount()).isEqualByComparingTo("1360.0000");
        assertThat(payDto1.baseCurrency()).isEqualTo("TND");

        // Payment 2: 600 EUR remaining balance -> 2,040 TND -> PAID
        RecordPaymentRequest p2 = new RecordPaymentRequest();
        p2.setAmount(new BigDecimal("600.00"));
        p2.setPaymentDate(LocalDate.of(2026, 11, 15));
        p2.setPaymentMethod("BANK_TRANSFER");

        var payDto2 = invoiceService.recordPayment("lina@biz.tn", invId, p2, "idem-pay-2");
        assertThat(inv.getStatus()).isEqualTo(InvoiceStatus.PAID);
        assertThat(inv.getPaidAmount()).isEqualByComparingTo("1000.0000");
        assertThat(inv.getOutstandingBalance()).isEqualByComparingTo("0.0000");
        assertThat(payDto2.convertedBaseAmount()).isEqualByComparingTo("2040.0000");

        ArgumentCaptor<Transaction> txCaptor = ArgumentCaptor.forClass(Transaction.class);
        verify(transactionRepository, times(2)).save(txCaptor.capture());
        assertThat(txCaptor.getAllValues()).allSatisfy(t -> {
            assertThat(t.getType()).isEqualTo("INCOME");
            assertThat(t.getOriginalCurrency()).isEqualTo("EUR");
            assertThat(t.getBaseCurrency()).isEqualTo("TND");
            assertThat(t.getExchangeRate()).isEqualByComparingTo("3.400000");
        });
    }

    @Test
    @DisplayName("Idempotency key replay returns existing payment without creating duplicate transaction")
    void duplicatePaymentIdempotencyReplay() {
        UUID invId = UUID.randomUUID();
        Invoice inv = new Invoice();
        inv.setId(invId);
        inv.setBusiness(bizTnd);

        Transaction existingTx = new Transaction();
        existingTx.setId(UUID.randomUUID());
        existingTx.setConvertedAmount(new BigDecimal("500.0000"));
        existingTx.setBaseCurrency("TND");
        existingTx.setExchangeRate(BigDecimal.ONE);

        Payment existing = new Payment();
        existing.setId(UUID.randomUUID());
        existing.setInvoice(inv);
        existing.setIncomeTransaction(existingTx);
        existing.setIdempotencyKey("retry-key-1");
        existing.setAmount(new BigDecimal("500.0000"));
        existing.setCurrency("TND");
        existing.setPaymentDate(LocalDate.of(2026, 11, 12));

        when(currentBusinessService.getCurrentUser("lina@biz.tn")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("lina@biz.tn")).thenReturn(bizTnd);
        when(paymentRepository.findByBusinessIdAndInvoiceIdAndIdempotencyKey(bizTnd.getId(), invId, "retry-key-1"))
                .thenReturn(Optional.of(existing));

        RecordPaymentRequest req = new RecordPaymentRequest();
        req.setAmount(new BigDecimal("500.00"));
        req.setPaymentDate(LocalDate.of(2026, 11, 12));

        var dto = invoiceService.recordPayment("lina@biz.tn", invId, req, "retry-key-1");

        assertThat(dto.id()).isEqualTo(existing.getId());
        assertThat(dto.incomeTransactionId()).isEqualTo(existingTx.getId());
        verify(transactionRepository, never()).save(any());
        verify(paymentRepository, never()).save(any());
    }

    @Test
    @DisplayName("Rejects overpayment, payments on DRAFT invoices, and cross-tenant invoice access")
    void rejectsOverpaymentDraftPaymentAndCrossTenant() {
        UUID invId = UUID.randomUUID();
        Invoice unpaid = new Invoice();
        unpaid.setId(invId);
        unpaid.setBusiness(bizTnd);
        unpaid.setStatus(InvoiceStatus.UNPAID);
        unpaid.setCurrency("TND");
        unpaid.setTotalAmount(new BigDecimal("100.0000"));
        unpaid.setPaidAmount(BigDecimal.ZERO);
        unpaid.setOutstandingBalance(new BigDecimal("100.0000"));

        when(currentBusinessService.getCurrentUser("lina@biz.tn")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("lina@biz.tn")).thenReturn(bizTnd);
        when(paymentRepository.findByBusinessIdAndInvoiceIdAndIdempotencyKey(any(), any(), any())).thenReturn(Optional.empty());
        when(invoiceRepository.findByIdForUpdate(invId)).thenReturn(Optional.of(unpaid));

        // Overpayment rejected
        RecordPaymentRequest overpay = new RecordPaymentRequest();
        overpay.setAmount(new BigDecimal("150.00"));
        overpay.setPaymentDate(LocalDate.now());
        assertThatThrownBy(() -> invoiceService.recordPayment("lina@biz.tn", invId, overpay, "overpay-1"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Overpayment");

        // DRAFT payment rejected
        unpaid.setStatus(InvoiceStatus.DRAFT);
        RecordPaymentRequest normal = new RecordPaymentRequest();
        normal.setAmount(new BigDecimal("50.00"));
        normal.setPaymentDate(LocalDate.now());
        assertThatThrownBy(() -> invoiceService.recordPayment("lina@biz.tn", invId, normal, "draft-1"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("DRAFT");

        // Cross-tenant invoice access rejected
        Invoice foreignInvoice = new Invoice();
        foreignInvoice.setId(UUID.randomUUID());
        foreignInvoice.setBusiness(bizOther);
        when(invoiceRepository.findWithDetailsById(foreignInvoice.getId())).thenReturn(Optional.of(foreignInvoice));
        assertThatThrownBy(() -> invoiceService.getInvoiceById("lina@biz.tn", foreignInvoice.getId()))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("OVERDUE status is computed dynamically from dueDate and remaining balance")
    void overdueComputedDynamically() {
        Invoice inv = new Invoice();
        inv.setStatus(InvoiceStatus.UNPAID);
        inv.setDueDate(LocalDate.of(2026, 11, 1));
        inv.setOutstandingBalance(new BigDecimal("250.0000"));

        assertThat(inv.computeEffectiveStatus(LocalDate.of(2026, 11, 20))).isEqualTo(InvoiceStatus.OVERDUE);
        assertThat(inv.computeEffectiveStatus(LocalDate.of(2026, 10, 25))).isEqualTo(InvoiceStatus.UNPAID);

        inv.setStatus(InvoiceStatus.PAID);
        inv.setOutstandingBalance(BigDecimal.ZERO);
        assertThat(inv.computeEffectiveStatus(LocalDate.of(2026, 11, 20))).isEqualTo(InvoiceStatus.PAID);
    }
}
