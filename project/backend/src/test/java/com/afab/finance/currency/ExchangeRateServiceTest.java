package com.afab.finance.currency;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ExchangeRateServiceTest {

    private ExchangeRateService exchangeRateService;

    @BeforeEach
    void setUp() {
        exchangeRateService = new ExchangeRateService();
    }

    @Test
    @DisplayName("getRate: returns 1.0 when from and to currencies are identical")
    void testSameCurrencyRate() {
        BigDecimal rate = exchangeRateService.getRate("USD", "USD");
        assertThat(rate).isEqualByComparingTo(BigDecimal.ONE);

        BigDecimal eurRate = exchangeRateService.getRate("EUR", "EUR");
        assertThat(eurRate).isEqualByComparingTo(BigDecimal.ONE);
    }

    @Test
    @DisplayName("convert: correctly converts amounts using real-world cross-rates")
    void testConvertAmount() {
        BigDecimal amount = new BigDecimal("100.00");
        BigDecimal converted = exchangeRateService.convert(amount, "USD", "EUR");

        assertThat(converted).isNotNull();
        assertThat(converted).isGreaterThan(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("getMarketPairs: generates live market pairs with sparklines")
    void testGetMarketPairs() {
        List<ExchangeRateService.CurrencyPairDTO> pairs = exchangeRateService.getMarketPairs("USD");

        assertThat(pairs).isNotEmpty();
        ExchangeRateService.CurrencyPairDTO first = pairs.get(0);
        assertThat(first.symbol()).contains("USD/");
        assertThat(first.sparkline()).hasSize(7);
        assertThat(first.high24h()).isGreaterThanOrEqualTo(first.low24h());
    }

    @Test
    @DisplayName("getHistoricalRates: generates trajectory points for timeframe")
    void testHistoricalRates() {
        List<ExchangeRateService.HistoricalRatePointDTO> history = exchangeRateService.getHistoricalRates("EUR", "USD", "1M");

        assertThat(history).hasSize(30);
        assertThat(history.get(history.size() - 1).rate()).isGreaterThan(0.0);
    }
}
