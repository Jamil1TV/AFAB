package com.afab.finance.currency;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.business.CurrentBusinessService;
import com.afab.finance.currency.ExchangeRateService.FxQuote;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.CreateTransactionRequest;
import com.afab.finance.dto.TransactionDTO;
import com.afab.finance.dto.UpdateTransactionRequest;
import com.afab.finance.repository.CategoryRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.CategoryService;
import com.afab.finance.service.TransactionService;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TransactionFxIntegrityTest {

    @Mock private TransactionRepository transactionRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private CategoryService categoryService;
    @Mock private AuditService auditService;
    @Mock private FinanceStatsService financeStatsService;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private BusinessRepository businessRepository;

    private TransactionService transactionService;
    private CurrencyConversionService currencyConversionService;

    private Business tndBusiness;
    private User owner;

    @BeforeEach
    void setUp() {
        transactionService = new TransactionService(
                transactionRepository, categoryRepository, currentBusinessService,
                categoryService, auditService, financeStatsService, exchangeRateService
        );
        currencyConversionService = new CurrencyConversionService(
                exchangeRateService, transactionRepository, businessRepository, auditService
        );

        owner = new User("Nadia", "Owner", "nadia@tunis.tn", "hash");
        owner.setId(UUID.randomUUID());

        tndBusiness = new Business(owner, "Carthage Consulting", "TND");
        tndBusiness.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Transaction in base currency records IDENTITY rate = 1.000000 with zero conversion drift")
    void baseCurrencyTransactionIdentitySnapshot() {
        when(currentBusinessService.getCurrentBusiness("nadia@tunis.tn")).thenReturn(tndBusiness);
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            t.setId(UUID.randomUUID());
            return t;
        });

        CreateTransactionRequest req = new CreateTransactionRequest();
        req.setType("EXPENSE");
        req.setAmount(new BigDecimal("450.250"));
        req.setOriginalCurrency("TND");
        req.setDescription("Office rent");
        req.setTransactionDate(LocalDate.of(2026, 11, 1));

        TransactionDTO dto = transactionService.createTransaction("nadia@tunis.tn", req);

        assertThat(dto.getOriginalAmount()).isEqualByComparingTo("450.2500");
        assertThat(dto.getOriginalCurrency()).isEqualTo("TND");
        assertThat(dto.getBaseCurrency()).isEqualTo("TND");
        assertThat(dto.getExchangeRate()).isEqualByComparingTo("1.000000");
        assertThat(dto.getConvertedAmount()).isEqualByComparingTo("450.2500");
        assertThat(dto.getAmount()).isEqualByComparingTo("450.2500");
        assertThat(dto.getFxRateSource()).isEqualTo("IDENTITY");
        assertThat(dto.isLegacyFx()).isFalse();
        verifyNoInteractions(exchangeRateService);
    }

    @Test
    @DisplayName("Foreign currency transaction (1,000 EUR -> 3,400 TND @ 3.400000) preserves exact FX snapshot")
    void foreignCurrencyTransactionSnapshotAndRounding() {
        Instant snapshotTime = Instant.parse("2026-11-10T10:00:00Z");
        when(currentBusinessService.getCurrentBusiness("nadia@tunis.tn")).thenReturn(tndBusiness);
        when(exchangeRateService.getRateQuote("EUR", "TND"))
                .thenReturn(new FxQuote("EUR", "TND", new BigDecimal("3.400000"), "LIVE_FEED", snapshotTime));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            t.setId(UUID.randomUUID());
            return t;
        });

        CreateTransactionRequest req = new CreateTransactionRequest();
        req.setType("INCOME");
        req.setAmount(new BigDecimal("1000.00"));
        req.setOriginalCurrency("EUR");
        req.setDescription("European client retainer");
        req.setTransactionDate(LocalDate.of(2026, 11, 10));

        TransactionDTO dto = transactionService.createTransaction("nadia@tunis.tn", req);

        assertThat(dto.getOriginalAmount()).isEqualByComparingTo("1000.0000");
        assertThat(dto.getOriginalCurrency()).isEqualTo("EUR");
        assertThat(dto.getBaseCurrency()).isEqualTo("TND");
        assertThat(dto.getExchangeRate()).isEqualByComparingTo("3.400000");
        assertThat(dto.getConvertedAmount()).isEqualByComparingTo("3400.0000");
        assertThat(dto.getAmount()).isEqualByComparingTo("3400.0000");
        assertThat(dto.getCurrency()).isEqualTo("TND");
        assertThat(dto.getFxRateSource()).isEqualTo("LIVE_FEED");
        assertThat(dto.getFxRateTimestamp()).isEqualTo(snapshotTime);
    }

    @Test
    @DisplayName("FX rounding uses precise BigDecimal HALF_UP to 4 decimal places")
    void fxRoundingPrecision() {
        when(currentBusinessService.getCurrentBusiness("nadia@tunis.tn")).thenReturn(tndBusiness);
        when(exchangeRateService.getRateQuote("USD", "TND"))
                .thenReturn(new FxQuote("USD", "TND", new BigDecimal("3.123456"), "LIVE_FEED", Instant.now()));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> {
            Transaction t = inv.getArgument(0);
            t.setId(UUID.randomUUID());
            return t;
        });

        CreateTransactionRequest req = new CreateTransactionRequest();
        req.setType("EXPENSE");
        req.setAmount(new BigDecimal("33.33"));
        req.setOriginalCurrency("USD");
        req.setDescription("Cloud hosting");
        req.setTransactionDate(LocalDate.of(2026, 11, 10));

        TransactionDTO dto = transactionService.createTransaction("nadia@tunis.tn", req);
        // 33.33 * 3.123456 = 104.10478848 -> HALF_UP(4) = 104.1048
        assertThat(dto.getConvertedAmount()).isEqualByComparingTo("104.1048");
    }

    @Test
    @DisplayName("Editing an existing foreign-currency transaction preserves historical rate and rejects currency change")
    void editingPreservesHistoricalRateAndBlocksCurrencyMutation() {
        UUID txId = UUID.randomUUID();
        Transaction historicalTx = new Transaction();
        historicalTx.setId(txId);
        historicalTx.setBusiness(tndBusiness);
        historicalTx.setType("INCOME");
        historicalTx.setOriginalAmount(new BigDecimal("1000.0000"));
        historicalTx.setOriginalCurrency("EUR");
        historicalTx.setBaseCurrency("TND");
        historicalTx.setExchangeRate(new BigDecimal("3.400000"));
        historicalTx.setConvertedAmount(new BigDecimal("3400.0000"));
        historicalTx.setAmount(new BigDecimal("3400.0000"));
        historicalTx.setCurrency("TND");
        historicalTx.setFxRateSource("LIVE_FEED");
        historicalTx.setDescription("Retainer");
        historicalTx.setTransactionDate(LocalDate.of(2026, 10, 1));

        when(currentBusinessService.getCurrentBusiness("nadia@tunis.tn")).thenReturn(tndBusiness);
        when(transactionRepository.findActiveById(txId)).thenReturn(Optional.of(historicalTx));
        when(transactionRepository.save(any(Transaction.class))).thenAnswer(inv -> inv.getArgument(0));

        // 1. Attempt to mutate originalCurrency is rejected
        UpdateTransactionRequest badReq = new UpdateTransactionRequest();
        badReq.setOriginalCurrency("USD");
        assertThatThrownBy(() -> transactionService.updateTransaction("nadia@tunis.tn", txId, badReq))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("locked FX snapshot");

        // 2. Updating original amount recalculates using ORIGINAL 3.400000 rate (NOT live exchangeRateService)
        UpdateTransactionRequest editAmountReq = new UpdateTransactionRequest();
        editAmountReq.setAmount(new BigDecimal("2000.00"));
        TransactionDTO updated = transactionService.updateTransaction("nadia@tunis.tn", txId, editAmountReq);

        assertThat(updated.getOriginalAmount()).isEqualByComparingTo("2000.0000");
        assertThat(updated.getExchangeRate()).isEqualByComparingTo("3.400000");
        assertThat(updated.getConvertedAmount()).isEqualByComparingTo("6800.0000");
        verifyNoInteractions(exchangeRateService);
    }

    @Test
    @DisplayName("Changing business base currency NEVER overwrites or recalculates historical transactions")
    void changingBusinessCurrencyPreservesHistoricalTransactions() {
        when(exchangeRateService.getRate("TND", "EUR")).thenReturn(new BigDecimal("0.294118"));
        when(transactionRepository.countByBusinessIdAndDeletedAtIsNull(tndBusiness.getId())).thenReturn(42L);
        when(businessRepository.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));

        var result = currencyConversionService.changeBusinessCurrency(owner, tndBusiness, "EUR", true);

        assertThat(tndBusiness.getCurrency()).isEqualTo("EUR");
        assertThat(result.convertedTransactionsCount()).isEqualTo(0);
        assertThat(result.preservedHistoricalTransactionsCount()).isEqualTo(42L);
        verify(transactionRepository, never()).findAll();
        verify(transactionRepository, never()).saveAll(any());
        verify(transactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Legacy transaction with LEGACY_UNKNOWN provenance exposes legacyFx=true without fabricating rate")
    void legacyTransactionReportsUnknownProvenanceHonestly() {
        UUID txId = UUID.randomUUID();
        Transaction legacyTx = new Transaction();
        legacyTx.setId(txId);
        legacyTx.setBusiness(tndBusiness);
        legacyTx.setType("EXPENSE");
        legacyTx.setAmount(new BigDecimal("250.0000"));
        legacyTx.setConvertedAmount(new BigDecimal("250.0000"));
        legacyTx.setOriginalAmount(new BigDecimal("250.0000"));
        legacyTx.setCurrency("TND");
        legacyTx.setBaseCurrency("TND");
        legacyTx.setOriginalCurrency(null);
        legacyTx.setExchangeRate(null);
        legacyTx.setFxRateSource("LEGACY_UNKNOWN");
        legacyTx.setDescription("Pre-FX migration expense");
        legacyTx.setTransactionDate(LocalDate.of(2026, 1, 15));

        when(currentBusinessService.getCurrentBusiness("nadia@tunis.tn")).thenReturn(tndBusiness);
        when(transactionRepository.findActiveById(txId)).thenReturn(Optional.of(legacyTx));

        TransactionDTO dto = transactionService.getTransactionById("nadia@tunis.tn", txId);

        assertThat(dto.isLegacyFx()).isTrue();
        assertThat(dto.getOriginalCurrency()).isNull();
        assertThat(dto.getExchangeRate()).isNull();
        assertThat(dto.getConvertedAmount()).isEqualByComparingTo("250.0000");
        assertThat(dto.getBaseCurrency()).isEqualTo("TND");
    }
}
