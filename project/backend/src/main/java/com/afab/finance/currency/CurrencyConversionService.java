package com.afab.finance.currency;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Currency Conversion Service — Handles business base-currency updates and live rate previews.
 *
 * Financial Integrity Policy (P1.1):
 * Historical transactions are IMMUTABLE. Changing a business's base currency updates the
 * default currency for FUTURE transactions only and NEVER rewrites historical amounts or
 * historical FX snapshots using today's exchange rate.
 */
@Service
public class CurrencyConversionService {

    private final ExchangeRateService exchangeRateService;
    private final TransactionRepository transactionRepository;
    private final BusinessRepository businessRepository;
    private final AuditService auditService;

    public CurrencyConversionService(ExchangeRateService exchangeRateService,
                                     TransactionRepository transactionRepository,
                                     BusinessRepository businessRepository,
                                     AuditService auditService) {
        this.exchangeRateService = exchangeRateService;
        this.transactionRepository = transactionRepository;
        this.businessRepository = businessRepository;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public CurrencyChangePreviewDTO previewCurrencyChange(Business business, String newCurrency) {
        String oldCurrency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency().toUpperCase().trim() : "USD";
        String targetCurrency = (newCurrency != null && !newCurrency.isBlank())
                ? newCurrency.toUpperCase().trim() : "USD";

        BigDecimal rate = exchangeRateService.getRate(oldCurrency, targetCurrency);

        BigDecimal currentInflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "INCOME");
        BigDecimal currentOutflow = transactionRepository.sumAmountByBusinessAndType(business.getId(), "EXPENSE");
        BigDecimal currentNet = currentInflow.subtract(currentOutflow);

        BigDecimal projectedNet = currentNet.multiply(rate).setScale(2, RoundingMode.HALF_UP);
        long txCount = transactionRepository.countByBusinessIdAndDeletedAtIsNull(business.getId());

        return new CurrencyChangePreviewDTO(
                oldCurrency,
                targetCurrency,
                rate,
                txCount,
                currentNet,
                projectedNet
        );
    }

    /**
     * Updates the business base currency for future transactions while preserving all
     * historical transactions and FX snapshots unchanged.
     */
    @Transactional
    public CurrencyChangeResultDTO changeBusinessCurrency(
            User user,
            Business business,
            String newCurrency,
            boolean convertExistingTransactionsRequested
    ) {
        String oldCurrency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency().toUpperCase().trim() : "USD";
        String targetCurrency = (newCurrency != null && !newCurrency.isBlank())
                ? newCurrency.toUpperCase().trim() : "USD";

        if (!targetCurrency.matches("^[A-Z]{3}$")) {
            throw new IllegalArgumentException("Currency must be a valid 3-letter ISO code.");
        }

        BigDecimal rate = exchangeRateService.getRate(oldCurrency, targetCurrency);
        long historicalPreservedCount = transactionRepository.countByBusinessIdAndDeletedAtIsNull(business.getId());

        // NEVER mutate historical transactions using today's exchange rate.
        business.setCurrency(targetCurrency);
        businessRepository.save(business);

        String auditDetails = String.format(
                "{\"oldCurrency\":\"%s\",\"newCurrency\":\"%s\",\"referenceRate\":%s,\"historicalTransactionsPreserved\":%d,\"historicalMutationBlocked\":true}",
                oldCurrency, targetCurrency, rate.toPlainString(), historicalPreservedCount
        );
        auditService.log(user, "CURRENCY_CHANGE", "Business", business.getId(), auditDetails);

        return new CurrencyChangeResultDTO(
                oldCurrency,
                targetCurrency,
                rate,
                0,
                historicalPreservedCount,
                true,
                "Business base currency updated to " + targetCurrency
                        + ". All " + historicalPreservedCount + " historical transaction(s) preserve their original currency and locked FX snapshots."
        );
    }

    public record CurrencyChangePreviewDTO(
            String oldCurrency,
            String newCurrency,
            BigDecimal exchangeRate,
            long transactionsCount,
            BigDecimal currentNetBalance,
            BigDecimal projectedNetBalance
    ) {}

    public record CurrencyChangeResultDTO(
            String oldCurrency,
            String newCurrency,
            BigDecimal exchangeRate,
            int convertedTransactionsCount,
            long preservedHistoricalTransactionsCount,
            boolean success,
            String message
    ) {}
}
