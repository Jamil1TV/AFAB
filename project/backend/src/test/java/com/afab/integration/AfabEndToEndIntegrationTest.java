package com.afab.integration;

import com.afab.auth.AuthService;
import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetRequest;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.BusinessController;
import com.afab.business.BusinessMember;
import com.afab.business.BusinessMemberRepository;
import com.afab.business.BusinessRepository;
import com.afab.business.dto.TransferOwnershipRequest;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.customers.dto.CreateCustomerRequest;
import com.afab.customers.dto.CustomerDTO;
import com.afab.customers.service.CustomerService;
import com.afab.finance.currency.CurrencyConversionService;
import com.afab.finance.dto.CreateTransactionRequest;
import com.afab.finance.dto.TransactionDTO;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.TransactionService;
import com.afab.invoices.dto.CreateInvoiceRequest;
import com.afab.invoices.dto.InvoiceDTO;
import com.afab.invoices.dto.RecordPaymentRequest;
import com.afab.invoices.repository.PaymentRepository;
import com.afab.invoices.service.InvoiceService;
import com.afab.receipts.dto.ReceiptDTO;
import com.afab.receipts.service.ReceiptService;
import com.afab.recurring.dto.RecurringTransactionDTO;
import com.afab.recurring.dto.RecurringTransactionRequest;
import com.afab.recurring.repository.RecurringTransactionExecutionRepository;
import com.afab.recurring.service.RecurringTransactionService;
import com.afab.security.DistributedRateLimiter;
import com.afab.security.DistributedRateLimiter.Endpoint;
import com.afab.security.DistributedRateLimiter.RateLimitResult;
import com.afab.security.RateLimitProperties;
import com.afab.user.User;
import com.afab.user.UserAccountService;
import com.afab.user.UserRepository;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Full-stack integration verification against real PostgreSQL 16 (Flyway V1..V23),
 * Redis 7, and MinIO S3-compatible private object storage.
 * Enabled when RUN_INTEGRATION_TESTS=true.
 */
@SpringBootTest
@ActiveProfiles("integration")
@EnabledIfEnvironmentVariable(named = "RUN_INTEGRATION_TESTS", matches = "true")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AfabEndToEndIntegrationTest {

    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private UserRepository userRepository;
    @Autowired private BusinessRepository businessRepository;
    @Autowired private BusinessMemberRepository businessMemberRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private PaymentRepository paymentRepository;
    @Autowired private RecurringTransactionExecutionRepository recurringExecutionRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private AuthService authService;
    @Autowired private UserAccountService userAccountService;
    @Autowired private BusinessController businessController;
    @Autowired private TransactionService transactionService;
    @Autowired private CurrencyConversionService currencyConversionService;
    @Autowired private CustomerService customerService;
    @Autowired private InvoiceService invoiceService;
    @Autowired private RecurringTransactionService recurringService;
    @Autowired private BudgetService budgetService;
    @Autowired private ReceiptService receiptService;
    @Autowired private StringRedisTemplate stringRedisTemplate;
    @Autowired private RateLimitProperties rateLimitProperties;

    private User createVerifiedUserWithBusiness(String email, String bizName, String currency) {
        User u = new User("Test", "Owner", email, passwordEncoder.encode("StrongPass!2026"));
        u.setEmailVerifiedAt(Instant.now());
        u.setStatus("ACTIVE");
        u = userRepository.save(u);

        Business b = new Business(u, bizName, currency);
        b.setTimezone("UTC");
        b.setCountry("TN");
        b.setStatus("ACTIVE");
        b = businessRepository.save(b);

        BusinessMember member = new BusinessMember(b, u, "OWNER", "ACTIVE");
        businessMemberRepository.save(member);

        u.setActiveBusinessId(b.getId());
        return userRepository.save(u);
    }

    @Test
    @Order(1)
    void flywayMigrationsV1ThroughV26AppliedCleanly() {
        Integer appliedCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM flyway_schema_history WHERE success = true", Integer.class);
        assertThat(appliedCount).isNotNull().isGreaterThanOrEqualTo(26);

        String latestVersion = jdbcTemplate.queryForObject(
                "SELECT version FROM flyway_schema_history WHERE success = true ORDER BY installed_rank DESC LIMIT 1",
                String.class);
        assertThat(latestVersion).isEqualTo("26");
    }

    @Test
    @Order(2)
    void authRefreshTokenHashingRotationReuseDetectionAndRedisRateLimiting() {
        String email = "auth-" + UUID.randomUUID() + "@afab.test";
        createVerifiedUserWithBusiness(email, "Auth Test Biz", "TND");

        LoginRequest loginReq = new LoginRequest();
        loginReq.setEmail(email);
        loginReq.setPassword("StrongPass!2026");

        AuthResponse loginRes = authService.login(loginReq, "127.0.0.1", "JUnit-IT");
        String rawRefresh1 = loginRes.getRefreshToken();
        assertThat(rawRefresh1).isNotBlank();

        // Confirm plaintext refresh token is NOT stored in DB (only SHA-256 hash in token_hash)
        Integer plaintextRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM refresh_tokens WHERE token_hash = ?", Integer.class, rawRefresh1);
        assertThat(plaintextRows).isZero();
        Integer hashedRows = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM refresh_tokens WHERE token_hash = ?", Integer.class, AuthService.hashToken(rawRefresh1));
        assertThat(hashedRows).isEqualTo(1);

        // Rotate refresh token once
        AuthResponse rotated = authService.refreshToken(rawRefresh1, "127.0.0.1", "JUnit-IT");
        String rawRefresh2 = rotated.getRefreshToken();
        assertThat(rawRefresh2).isNotBlank().isNotEqualTo(rawRefresh1);

        // Replay OLD refresh token -> reuse detection revokes entire token family!
        assertThatThrownBy(() -> authService.refreshToken(rawRefresh1, "127.0.0.1", "JUnit-IT"))
                .isInstanceOf(AuthService.RefreshTokenReuseException.class);

        // Even the newer refresh token from the compromised family is now revoked!
        assertThatThrownBy(() -> authService.refreshToken(rawRefresh2, "127.0.0.1", "JUnit-IT"))
                .isInstanceOf(AuthService.RefreshTokenReuseException.class);

        // Real Redis Distributed Rate Limiting across two separate limiter instances
        DistributedRateLimiter instanceA = new DistributedRateLimiter(stringRedisTemplate, rateLimitProperties);
        DistributedRateLimiter instanceB = new DistributedRateLimiter(stringRedisTemplate, rateLimitProperties);
        String testIp = "198.51.100." + (int) (Math.random() * 200 + 1);
        String testEmail = "ratelimit-" + UUID.randomUUID() + "@afab.test";

        // Limit is 3 per minute in application-integration.yml; alternate across instanceA & instanceB
        assertThat(instanceA.check(Endpoint.LOGIN, testIp, testEmail).allowed()).isTrue();
        assertThat(instanceB.check(Endpoint.LOGIN, testIp, testEmail).allowed()).isTrue();
        assertThat(instanceA.check(Endpoint.LOGIN, testIp, testEmail).allowed()).isTrue();

        RateLimitResult fourth = instanceB.check(Endpoint.LOGIN, testIp, testEmail);
        assertThat(fourth.allowed()).isFalse();
        assertThat(fourth.serviceUnavailable()).isFalse();
        assertThat(fourth.retryAfterSeconds()).isGreaterThan(0L);
    }

    @Test
    @Order(3)
    void transactionFxSnapshotRemainsImmutableWhenBusinessCurrencyChanges() {
        String email = "fx-" + UUID.randomUUID() + "@afab.test";
        User user = createVerifiedUserWithBusiness(email, "FX Integrity Biz", "TND");

        CreateTransactionRequest req = new CreateTransactionRequest();
        req.setType("EXPENSE");
        req.setAmount(new BigDecimal("100.00"));
        req.setOriginalCurrency("EUR");
        req.setExchangeRate(new BigDecimal("3.350000"));
        req.setDescription("SaaS Annual License");
        req.setTransactionDate(LocalDate.now());
        req.setPaymentMethod("CARD");
        req.setStatus("COMPLETED");

        TransactionDTO created = transactionService.createTransaction(email, req);
        assertThat(created.getOriginalAmount()).isEqualByComparingTo("100.0000");
        assertThat(created.getOriginalCurrency()).isEqualTo("EUR");
        assertThat(created.getBaseCurrency()).isEqualTo("TND");
        assertThat(created.getExchangeRate()).isEqualByComparingTo("3.350000");
        assertThat(created.getConvertedAmount()).isEqualByComparingTo("335.0000");

        // Change business base currency TND -> USD (even if caller asks to convert existing, historical rows MUST stay untouched)
        Business biz = businessRepository.findById(user.getActiveBusinessId()).orElseThrow();
        var migration = currencyConversionService.changeBusinessCurrency(user, biz, "USD", true);
        assertThat(migration.convertedTransactionsCount()).isZero();
        assertThat(migration.preservedHistoricalTransactionsCount()).isEqualTo(1);

        // Historical transaction MUST remain untouched at 335.0000 TND @ 3.350000
        TransactionDTO afterChange = transactionService.getTransactionById(email, created.getId());
        assertThat(afterChange.getConvertedAmount()).isEqualByComparingTo("335.0000");
        assertThat(afterChange.getBaseCurrency()).isEqualTo("TND");
        assertThat(afterChange.getExchangeRate()).isEqualByComparingTo("3.350000");
    }

    @Test
    @Order(4)
    void safeAccountDeletionBlocksSoleOwnerEnforcesDbRestrictAndSupportsOwnershipTransfer() {
        String owner1Email = "owner1-" + UUID.randomUUID() + "@afab.test";
        String owner2Email = "owner2-" + UUID.randomUUID() + "@afab.test";
        User owner1 = createVerifiedUserWithBusiness(owner1Email, "Protected Co", "USD");

        // Create a second user and add them as active ADMIN in Protected Co
        User owner2 = createVerifiedUserWithBusiness(owner2Email, "Owner2 Separate Co", "USD");
        Business protectedBiz = businessRepository.findById(owner1.getActiveBusinessId()).orElseThrow();
        businessMemberRepository.save(new BusinessMember(protectedBiz, owner2, "ADMIN", "ACTIVE"));

        // Record a financial transaction in Protected Co
        CreateTransactionRequest txReq = new CreateTransactionRequest();
        txReq.setType("INCOME");
        txReq.setAmount(new BigDecimal("500.00"));
        txReq.setDescription("Important Sale");
        txReq.setTransactionDate(LocalDate.now());
        TransactionDTO savedTx = transactionService.createTransaction(owner1Email, txReq);

        // 1. Sole active owner CANNOT delete account -> 409 Conflict
        assertThatThrownBy(() -> userAccountService.deleteUserAccount(
                owner1Email, "delete " + owner1Email, "127.0.0.1", "JUnit-IT"))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("Protected Co");

        // 2. DB-level ON DELETE RESTRICT blocks hard-deleting user owning a business
        assertThatThrownBy(() -> jdbcTemplate.update("DELETE FROM users WHERE id = ?", owner1.getId()))
                .isInstanceOf(DataIntegrityViolationException.class);

        // 3. Transfer ownership to owner2, then delete owner1 safely
        var auth = new UsernamePasswordAuthenticationToken(owner1Email, null, List.of());
        businessController.transferOwnership(protectedBiz.getId(), new TransferOwnershipRequest(owner2.getId()), auth);

        userAccountService.deleteUserAccount(owner1Email, "delete " + owner1Email, "127.0.0.1", "JUnit-IT");

        // Business & its financial transaction MUST survive completely intact!
        Business survivingBiz = businessRepository.findById(protectedBiz.getId()).orElseThrow();
        assertThat(survivingBiz.getArchivedAt()).isNull();
        assertThat(survivingBiz.getUser().getId()).isEqualTo(owner2.getId());
        assertThat(transactionRepository.findActiveById(savedTx.getId())).isPresent();
    }

    @Test
    @Order(5)
    void invoiceLifecycleAtomicConcurrentNumberingPaymentIdempotencyAndZeroPrematureIncome() throws Exception {
        String email = "inv-" + UUID.randomUUID() + "@afab.test";
        User user = createVerifiedUserWithBusiness(email, "Invoicing Pro LLC", "USD");
        UUID businessId = user.getActiveBusinessId();

        CreateCustomerRequest custReq = new CreateCustomerRequest();
        custReq.setName("Atlas Retail");
        custReq.setEmail("billing@atlas.test");
        CustomerDTO customer = customerService.createCustomer(email, custReq);

        // 1. Concurrent atomic invoice numbering across 8 threads -> 8 strictly unique numbers
        int threads = 8;
        ExecutorService pool = Executors.newFixedThreadPool(threads);
        List<Callable<String>> tasks = new ArrayList<>();
        for (int i = 0; i < threads; i++) {
            final int idx = i;
            tasks.add(() -> {
                CreateInvoiceRequest invReq = new CreateInvoiceRequest();
                invReq.setCustomerId(customer.id());
                invReq.setIssueDate(LocalDate.now());
                invReq.setDueDate(LocalDate.now().plusDays(15));
                CreateInvoiceRequest.InvoiceItemRequest item = new CreateInvoiceRequest.InvoiceItemRequest();
                item.setDescription("Service #" + idx);
                item.setQuantity(BigDecimal.ONE);
                item.setUnitPrice(new BigDecimal("100.00"));
                invReq.setItems(List.of(item));
                return invoiceService.createInvoice(email, invReq).invoiceNumber();
            });
        }
        List<Future<String>> futures = pool.invokeAll(tasks);
        pool.shutdown();

        Set<String> generatedNumbers = new HashSet<>();
        for (Future<String> f : futures) {
            generatedNumbers.add(f.get());
        }
        assertThat(generatedNumbers).hasSize(threads);

        // 2. Draft + Issue must create ZERO Income Transactions
        assertThat(transactionRepository.countByBusinessIdAndDeletedAtIsNull(businessId)).isZero();

        CreateInvoiceRequest mainInvReq = new CreateInvoiceRequest();
        mainInvReq.setCustomerId(customer.id());
        mainInvReq.setIssueDate(LocalDate.now());
        mainInvReq.setDueDate(LocalDate.now().plusDays(30));
        CreateInvoiceRequest.InvoiceItemRequest line = new CreateInvoiceRequest.InvoiceItemRequest();
        line.setDescription("ERP Consulting");
        line.setQuantity(new BigDecimal("2"));
        line.setUnitPrice(new BigDecimal("500.00"));
        mainInvReq.setItems(List.of(line));

        InvoiceDTO draft = invoiceService.createInvoice(email, mainInvReq);
        InvoiceDTO issued = invoiceService.issueInvoice(email, draft.id(), false);
        assertThat(issued.status()).isEqualTo("UNPAID");
        assertThat(transactionRepository.countByBusinessIdAndDeletedAtIsNull(businessId)).isZero();

        // 3. Partial payment + Idempotency-Key replay creates ONLY ONE Payment & ONE Income Transaction
        RecordPaymentRequest pay1 = new RecordPaymentRequest();
        pay1.setAmount(new BigDecimal("400.00"));
        pay1.setPaymentDate(LocalDate.now());
        pay1.setPaymentMethod("BANK_TRANSFER");

        var payDto1 = invoiceService.recordPayment(email, issued.id(), pay1, "idem-key-001");
        var payDtoReplay = invoiceService.recordPayment(email, issued.id(), pay1, "idem-key-001");
        assertThat(payDtoReplay.id()).isEqualTo(payDto1.id());
        assertThat(payDtoReplay.incomeTransactionId()).isEqualTo(payDto1.incomeTransactionId());

        InvoiceDTO afterPay1 = invoiceService.getInvoiceById(email, issued.id());
        assertThat(afterPay1.status()).isEqualTo("PARTIALLY_PAID");
        assertThat(afterPay1.paidAmount()).isEqualByComparingTo("400.0000");
        assertThat(afterPay1.outstandingBalance()).isEqualByComparingTo("600.0000");
        assertThat(paymentRepository.findByBusinessIdAndInvoiceId(businessId, issued.id())).hasSize(1);
        assertThat(transactionRepository.countByBusinessIdAndDeletedAtIsNull(businessId)).isEqualTo(1);

        // 4. Final payment completes invoice -> PAID, 2 Income Transactions total
        RecordPaymentRequest pay2 = new RecordPaymentRequest();
        pay2.setAmount(new BigDecimal("600.00"));
        pay2.setPaymentDate(LocalDate.now());
        pay2.setPaymentMethod("BANK_TRANSFER");

        invoiceService.recordPayment(email, issued.id(), pay2, "idem-key-002");
        InvoiceDTO paid = invoiceService.getInvoiceById(email, issued.id());
        assertThat(paid.status()).isEqualTo("PAID");
        assertThat(paid.outstandingBalance()).isEqualByComparingTo("0.0000");
        assertThat(transactionRepository.countByBusinessIdAndDeletedAtIsNull(businessId)).isEqualTo(2);
    }

    @Test
    @Order(6)
    void recurringIdempotencyBudgetCalculationsMinioPrivateReceiptsAndCrossTenantIsolation() {
        String emailA = "tenantA-" + UUID.randomUUID() + "@afab.test";
        String emailB = "tenantB-" + UUID.randomUUID() + "@afab.test";
        createVerifiedUserWithBusiness(emailA, "Tenant Alpha", "TND");
        createVerifiedUserWithBusiness(emailB, "Tenant Beta", "TND");

        // 1. Recurring rule executed twice on same date -> strictly 1 Transaction generated (DB UNIQUE idempotency)
        RecurringTransactionRequest recReq = new RecurringTransactionRequest();
        recReq.setType("EXPENSE");
        recReq.setDescription("Monthly Cloud Server");
        recReq.setAmount(new BigDecimal("850.00"));
        recReq.setCurrency("TND");
        recReq.setFrequency("MONTHLY");
        recReq.setStartDate(LocalDate.now());
        RecurringTransactionDTO rule = recurringService.create(emailA, recReq);

        var run1 = recurringService.runDueForRule(emailA, rule.id());
        var run2 = recurringService.runDueForRule(emailA, rule.id());
        assertThat(run1.generatedCount()).isEqualTo(1);
        assertThat(run2.generatedCount()).isZero();
        assertThat(recurringExecutionRepository.findByRecurringTransactionIdOrderByScheduledDateDesc(rule.id())).hasSize(1);
        UUID generatedTxId = run1.transactionIds().get(0);

        // 2. Budget calculated against real PostgreSQL spending -> 850 / 1000 = 85% APPROACHING
        BudgetRequest budgetReq = new BudgetRequest();
        budgetReq.setName("Monthly Infrastructure Cap");
        budgetReq.setAmount(new BigDecimal("1000.00"));
        budgetReq.setPeriodType("MONTHLY");
        budgetReq.setAlertThresholdPercent(80);
        BudgetDTO budget = budgetService.create(emailA, budgetReq);
        assertThat(budget.actualSpending()).isEqualByComparingTo("850.0000");
        assertThat(budget.remainingAmount()).isEqualByComparingTo("150.0000");
        assertThat(budget.percentageConsumed()).isEqualByComparingTo("85.00");
        assertThat(budget.alertLevel()).isEqualTo("APPROACHING");

        // 3. Real MinIO Private Receipt upload -> download -> presign -> cross-tenant block -> delete
        byte[] pdfBytes = "%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF".getBytes(StandardCharsets.US_ASCII);
        MockMultipartFile pdfFile = new MockMultipartFile("file", "cloud-receipt.pdf", "application/pdf", pdfBytes);
        ReceiptDTO receipt = receiptService.upload(emailA, generatedTxId, pdfFile);
        assertThat(receipt.fileSizeBytes()).isEqualTo(pdfBytes.length);

        var downloaded = receiptService.downloadContent(emailA, receipt.id());
        assertThat(downloaded.data()).isEqualTo(pdfBytes);

        var presigned = receiptService.getDownloadUrl(emailA, receipt.id());
        assertThat(presigned.url()).contains("X-Amz-Signature");

        // 4. Cross-tenant isolation: Tenant B CANNOT access Tenant A's Transaction, Recurring Rule, Budget, or Receipt!
        assertThatThrownBy(() -> transactionService.getTransactionById(emailB, generatedTxId))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> recurringService.getById(emailB, rule.id()))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> budgetService.getById(emailB, budget.id()))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> receiptService.downloadContent(emailB, receipt.id()))
                .isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> receiptService.delete(emailB, receipt.id()))
                .isInstanceOf(ForbiddenException.class);

        // Tenant A deletes receipt cleanly from MinIO + soft-deletes DB row
        receiptService.delete(emailA, receipt.id());
        assertThat(receiptService.listForTransaction(emailA, generatedTxId)).isEmpty();
    }
}
