package com.afab.finance.currency;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Currency Conversion Service — Handles business base-currency migrations and live rate previews.
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

    @Transactional
    public CurrencyChangeResultDTO changeBusinessCurrency(User user, Business business, String newCurrency, boolean convertExistingTransactions) {
        String oldCurrency = (business.getCurrency() != null && !business.getCurrency().isBlank())
                ? business.getCurrency().toUpperCase().trim() : "USD";
        String targetCurrency = (newCurrency != null && !newCurrency.isBlank())
                ? newCurrency.toUpperCase().trim() : "USD";

        BigDecimal rate = exchangeRateService.getRate(oldCurrency, targetCurrency);
        int convertedCount = 0;

        if (convertExistingTransactions && !oldCurrency.equalsIgnoreCase(targetCurrency)) {
            // Find all active transactions for this business
            List<Transaction> transactions = transactionRepository.findAll().stream()
                    .filter(t -> t.getBusiness().getId().equals(business.getId()) && t.getDeletedAt() == null)
                    .toList();

            for (Transaction tx : transactions) {
                BigDecimal oldAmount = tx.getAmount();
                BigDecimal newAmount = oldAmount.multiply(rate).setScale(4, RoundingMode.HALF_UP);
                tx.setAmount(newAmount);
                tx.setCurrency(targetCurrency);
                convertedCount++;
            }

            transactionRepository.saveAll(transactions);
        }

        business.setCurrency(targetCurrency);
        businessRepository.save(business);

        String auditDetails = String.format(
                "{\"oldCurrency\":\"%s\",\"newCurrency\":\"%s\",\"exchangeRate\":%s,\"convertedCount\":%d}",
                oldCurrency, targetCurrency, rate.toPlainString(), convertedCount
        );
        auditService.log(user, "CURRENCY_CHANGE", "Business", business.getId(), auditDetails);

        return new CurrencyChangeResultDTO(
                oldCurrency,
                targetCurrency,
                rate,
                convertedCount,
                true
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
            boolean success
    ) {}
}
