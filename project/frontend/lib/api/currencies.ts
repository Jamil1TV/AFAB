import { fetchClient } from "./client";

export interface CurrencyPair {
  symbol: string;
  base: string;
  target: string;
  rate: number;
  change24h: number;
  high24h: number;
  low24h: number;
  sparkline: number[];
}

export interface HistoricalRatePoint {
  date: string;
  rate: number;
}

export interface CurrencyConversionResult {
  from: string;
  to: string;
  amount: number;
  exchangeRate: number;
  convertedAmount: number;
}

export interface CurrencyChangePreview {
  oldCurrency: string;
  newCurrency: string;
  exchangeRate: number;
  transactionsCount: number;
  currentNetBalance: number;
  projectedNetBalance: number;
}

export interface CurrencyChangeResult {
  oldCurrency: string;
  newCurrency: string;
  exchangeRate: number;
  convertedTransactionsCount: number;
  success: boolean;
}

export class CurrencyService {
  static async getMarketRates(base?: string): Promise<CurrencyPair[]> {
    const query = base ? `?base=${encodeURIComponent(base)}` : "";
    return await fetchClient(`/currencies/rates${query}`);
  }

  static async getHistoricalRates(from: string, to: string, timeframe: string = "1M"): Promise<HistoricalRatePoint[]> {
    return await fetchClient(
      `/currencies/history?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&timeframe=${encodeURIComponent(timeframe)}`
    );
  }

  static async convert(from: string, to: string, amount: number): Promise<CurrencyConversionResult> {
    return await fetchClient(
      `/currencies/convert?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}&amount=${amount}`
    );
  }

  static async previewChange(newCurrency: string): Promise<CurrencyChangePreview> {
    return await fetchClient(
      `/currencies/business/preview?newCurrency=${encodeURIComponent(newCurrency)}`
    );
  }

  static async changeBusinessCurrency(newCurrency: string, convertExistingTransactions: boolean): Promise<CurrencyChangeResult> {
    return await fetchClient(`/currencies/business/change`, {
      method: "POST",
      body: JSON.stringify({
        newCurrency,
        convertExistingTransactions,
      }),
    });
  }
}
