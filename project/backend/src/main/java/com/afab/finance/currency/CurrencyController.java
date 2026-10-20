package com.afab.finance.currency;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.finance.currency.CurrencyConversionService.CurrencyChangePreviewDTO;
import com.afab.finance.currency.CurrencyConversionService.CurrencyChangeResultDTO;
import com.afab.finance.currency.ExchangeRateService.CurrencyPairDTO;
import com.afab.finance.currency.ExchangeRateService.HistoricalRatePointDTO;
import com.afab.user.User;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Currency Controller — Live FX Market Feeds & Business Currency Migration.
 */
@RestController
@RequestMapping("/api/v1/currencies")
public class CurrencyController {

    private final ExchangeRateService exchangeRateService;
    private final CurrencyConversionService currencyConversionService;
    private final CurrentBusinessService currentBusinessService;

    public CurrencyController(ExchangeRateService exchangeRateService,
                              CurrencyConversionService currencyConversionService,
                              CurrentBusinessService currentBusinessService) {
        this.exchangeRateService = exchangeRateService;
        this.currencyConversionService = currencyConversionService;
        this.currentBusinessService = currentBusinessService;
    }

    /**
     * GET /api/v1/currencies/rates?base=USD — Live market pairs with 24h change & sparklines
     */
    @GetMapping("/rates")
    public ResponseEntity<List<CurrencyPairDTO>> getMarketRates(
            Authentication authentication,
            @RequestParam(value = "base", required = false) String base
    ) {
        String baseCurrency = base;
        if (baseCurrency == null || baseCurrency.isBlank()) {
            if (authentication != null && authentication.isAuthenticated()) {
                try {
                    Business business = currentBusinessService.getCurrentBusiness(authentication.getName());
                    baseCurrency = business.getCurrency();
                } catch (Exception ignored) {}
            }
        }
        if (baseCurrency == null || baseCurrency.isBlank()) {
            baseCurrency = "USD";
        }

        List<CurrencyPairDTO> pairs = exchangeRateService.getMarketPairs(baseCurrency);
        return ResponseEntity.ok(pairs);
    }

    /**
     * GET /api/v1/currencies/history?from=EUR&to=USD&timeframe=1M — Historical chart trajectory
     */
    @GetMapping("/history")
    public ResponseEntity<List<HistoricalRatePointDTO>> getHistoricalRates(
            @RequestParam(value = "from", defaultValue = "EUR") String from,
            @RequestParam(value = "to", defaultValue = "USD") String to,
            @RequestParam(value = "timeframe", defaultValue = "1M") String timeframe
    ) {
        List<HistoricalRatePointDTO> history = exchangeRateService.getHistoricalRates(from, to, timeframe);
        return ResponseEntity.ok(history);
    }

    /**
     * GET /api/v1/currencies/convert?from=EUR&to=USD&amount=100 — Real-time converter calculation
     */
    @GetMapping("/convert")
    public ResponseEntity<Map<String, Object>> convertCurrency(
            @RequestParam("from") String from,
            @RequestParam("to") String to,
            @RequestParam("amount") BigDecimal amount
    ) {
        BigDecimal rate = exchangeRateService.getRate(from, to);
        BigDecimal converted = exchangeRateService.convert(amount, from, to);

        return ResponseEntity.ok(Map.of(
                "from", from.toUpperCase(),
                "to", to.toUpperCase(),
                "amount", amount,
                "exchangeRate", rate,
                "convertedAmount", converted
        ));
    }

    /**
     * GET /api/v1/currencies/business/preview?newCurrency=USD — Preview changing business currency
     */
    @GetMapping("/business/preview")
    public ResponseEntity<CurrencyChangePreviewDTO> previewBusinessCurrencyChange(
            Authentication authentication,
            @RequestParam("newCurrency") String newCurrency
    ) {
        Business business = currentBusinessService.getCurrentBusiness(authentication.getName());
        CurrencyChangePreviewDTO preview = currencyConversionService.previewCurrencyChange(business, newCurrency);
        return ResponseEntity.ok(preview);
    }

    /**
     * POST /api/v1/currencies/business/change — Execute business currency change and convert transactions
     */
    @PostMapping("/business/change")
    public ResponseEntity<CurrencyChangeResultDTO> changeBusinessCurrency(
            Authentication authentication,
            @RequestBody ChangeCurrencyRequest request
    ) {
        User user = currentBusinessService.getCurrentUser(authentication.getName());
        Business business = currentBusinessService.getCurrentBusiness(authentication.getName());

        CurrencyChangeResultDTO result = currencyConversionService.changeBusinessCurrency(
                user,
                business,
                request.newCurrency(),
                request.convertExistingTransactions()
        );

        return ResponseEntity.ok(result);
    }

    public record ChangeCurrencyRequest(
            String newCurrency,
            boolean convertExistingTransactions
    ) {}
}
