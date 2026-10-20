"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useTranslations, useLocale } from "next-intl";
import { 
  Coins, 
  RefreshCw, 
  Search, 
  ArrowRightLeft, 
  TrendingUp, 
  TrendingDown, 
  Globe, 
  Sparkles, 
  SlidersHorizontal,
  ChevronRight,
  ShieldCheck,
  Building2,
  Wallet,
  Calculator,
  Bell,
  Layers,
  ArrowUpRight,
  Zap,
} from "lucide-react";
import { CurrencyService, CurrencyPair, HistoricalRatePoint } from "@/lib/api/currencies";
import { DashboardService } from "@/lib/api/dashboard";
import { LiveMarketTicker } from "@/components/currencies/LiveMarketTicker";
import { FeaturedPairCard } from "@/components/currencies/FeaturedPairCard";
import { FxTrajectoryChart } from "@/components/currencies/FxTrajectoryChart";
import { FxConverterWidget } from "@/components/currencies/FxConverterWidget";
import { BusinessPortfolioImpactCard } from "@/components/currencies/BusinessPortfolioImpactCard";
import { BinanceLiveChart } from "@/components/currencies/BinanceLiveChart";
import { FxInvoiceRiskSimulator } from "@/components/currencies/FxInvoiceRiskSimulator";
import { FxRateAlerts } from "@/components/currencies/FxRateAlerts";
import { CurrencyMigrationModal } from "@/components/settings/CurrencyMigrationModal";

interface CurrencyInfo {
  code: string;
  nameEn: string;
  nameAr: string;
  symbol: string;
}

const ALL_CURRENCIES: CurrencyInfo[] = [
  { code: "USD", nameEn: "US Dollar", nameAr: "دولار أمريكي", symbol: "$" },
  { code: "EUR", nameEn: "Euro", nameAr: "يورو", symbol: "€" },
  { code: "TND", nameEn: "Tunisian Dinar", nameAr: "دينار تونسي", symbol: "DT" },
  { code: "QAR", nameEn: "Qatari Riyal", nameAr: "ريال قطري", symbol: "QAR" },
  { code: "GBP", nameEn: "British Pound", nameAr: "جنيه إسترليني", symbol: "£" },
  { code: "AED", nameEn: "UAE Dirham", nameAr: "درهم إماراتي", symbol: "AED" },
  { code: "SAR", nameEn: "Saudi Riyal", nameAr: "ريال سعودي", symbol: "SAR" },
  { code: "CAD", nameEn: "Canadian Dollar", nameAr: "دولار كندي", symbol: "C$" },
  { code: "JPY", nameEn: "Japanese Yen", nameAr: "ين ياباني", symbol: "¥" },
  { code: "CHF", nameEn: "Swiss Franc", nameAr: "فرنك سويسري", symbol: "CHF" },
  { code: "KWD", nameEn: "Kuwaiti Dinar", nameAr: "دينار كويتي", symbol: "KWD" },
  { code: "MAD", nameEn: "Moroccan Dirham", nameAr: "درهم مغربي", symbol: "MAD" },
  { code: "TRY", nameEn: "Turkish Lira", nameAr: "ليرة تركية", symbol: "₺" },
  { code: "EGP", nameEn: "Egyptian Pound", nameAr: "جنيه مصري", symbol: "E£" },
  { code: "AUD", nameEn: "Australian Dollar", nameAr: "دولار أسترالي", symbol: "A$" },
  { code: "CNY", nameEn: "Chinese Yuan", nameAr: "يوان صيني", symbol: "¥" },
];

export default function CurrenciesPage() {
  const t = useTranslations("Currencies");
  const locale = useLocale();
  const isArabic = locale === "ar";

  const [marketPairs, setMarketPairs] = useState<CurrencyPair[]>([]);
  const [selectedPair, setSelectedPair] = useState<CurrencyPair | null>(null);
  const [chartHistory, setChartHistory] = useState<HistoricalRatePoint[]>([]);
  const [timeframe, setTimeframe] = useState<string>("1M");
  const [chartLoading, setChartLoading] = useState<boolean>(false);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);

  // Business profile & view state
  const [businessName, setBusinessName] = useState<string>("My Business");
  const [baseCurrency, setBaseCurrency] = useState<string>("USD");
  const [viewBaseCurrency, setViewBaseCurrency] = useState<string>("USD");
  const [netBalance, setNetBalance] = useState<number>(24500);

  // Active sub-view tab
  const [activeTab, setActiveTab] = useState<"markets" | "binance" | "risk" | "alerts" | "directory">("markets");
  const [chartMode, setChartMode] = useState<"binance" | "macro">("binance");

  // Search filter for table
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Migration modal state
  const [migrationModalOpen, setMigrationModalOpen] = useState<boolean>(false);
  const [pendingCurrency, setPendingCurrency] = useState<string | null>(null);

  // Initial load: Fetch rates and business context
  const loadInitialData = useCallback(async () => {
    setIsRefreshing(true);
    try {
      // 1. Fetch business summary
      try {
        const summary = await DashboardService.getSummary();
        if (summary) {
          if (summary.businessName) setBusinessName(summary.businessName);
          if (summary.currency) {
            setBaseCurrency(summary.currency);
            setViewBaseCurrency(summary.currency);
          }
          const rawProfit = summary.kpiData?.profit?.rawValue;
          const rawCash = summary.kpiData?.cashFlow?.rawValue;
          if (rawProfit !== undefined && rawProfit !== 0) {
            setNetBalance(rawProfit);
          } else if (rawCash !== undefined && rawCash !== 0) {
            setNetBalance(rawCash);
          }
        }
      } catch (err) {
        console.warn("Could not load dashboard summary for business info:", err);
      }

      // 2. Fetch live market pairs based on active view base currency
      const pairs = await CurrencyService.getMarketRates(viewBaseCurrency);
      setMarketPairs(pairs);

      // Default selected pair: first pair matching viewBase or EUR/USD
      const defaultPair = pairs.find((p) => p.base === viewBaseCurrency) || pairs[0];
      if (defaultPair) {
        setSelectedPair(defaultPair);
      }
    } catch (err) {
      console.error("Failed to load FX market data:", err);
    } finally {
      setIsRefreshing(false);
    }
  }, [viewBaseCurrency]);

  useEffect(() => {
    loadInitialData();
  }, [loadInitialData]);

  // Load chart history whenever selectedPair or timeframe changes
  useEffect(() => {
    if (!selectedPair) return;

    let isMounted = true;
    setChartLoading(true);

    CurrencyService.getHistoricalRates(selectedPair.base, selectedPair.target, timeframe)
      .then((history) => {
        if (isMounted) {
          setChartHistory(history);
          setChartLoading(false);
        }
      })
      .catch((err) => {
        if (isMounted) {
          console.error("Failed to fetch historical rates:", err);
          setChartLoading(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [selectedPair, timeframe]);

  // Handle pair selection from featured cards, ticker, or table
  const handleSelectPair = (pair: CurrencyPair) => {
    setSelectedPair(pair);
  };

  // Handle switching chart from converter widget
  const handleConverterPairChange = (from: string, to: string) => {
    const symbol = `${from}/${to}`;
    const existing = marketPairs.find((p) => p.symbol === symbol);
    if (existing) {
      setSelectedPair(existing);
    } else {
      setSelectedPair({
        symbol,
        base: from,
        target: to,
        rate: 1.0,
        change24h: 0.15,
        high24h: 1.02,
        low24h: 0.98,
        sparkline: [1.0, 1.01, 1.0],
      });
    }
  };

  // Filtered currency table data
  const filteredCurrencies = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    return ALL_CURRENCIES.filter((c) => {
      if (!q) return true;
      return (
        c.code.toLowerCase().includes(q) ||
        c.nameEn.toLowerCase().includes(q) ||
        c.nameAr.includes(q)
      );
    });
  }, [searchQuery]);

  // Featured 4 spotlight pairs matching viewBaseCurrency
  const featuredPairs = useMemo(() => {
    if (marketPairs.length === 0) return [];
    // Prioritize pairs starting with viewBaseCurrency
    const directPairs = marketPairs.filter((p) => p.base === viewBaseCurrency);
    if (directPairs.length >= 4) return directPairs.slice(0, 4);

    const remaining = marketPairs.filter((p) => !directPairs.includes(p));
    return [...directPairs, ...remaining].slice(0, 4);
  }, [marketPairs, viewBaseCurrency]);

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8 space-y-8 animate-in fade-in duration-500">
      {/* 1. Header Bar with Controls */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div className="shrink min-w-0">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-gradient-to-br from-[#6c4cf5] to-[#8b5cf6] text-white shadow-lg shadow-purple-500/25">
              <Coins className="h-6 w-6" />
            </div>
            <div>
              <h1 className="text-2xl sm:text-3xl font-black text-gray-900 dark:text-white tracking-tight">
                {t("title")}
              </h1>
              <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 mt-0.5">
                {t("subtitle")}
              </p>
            </div>
          </div>
        </div>

        {/* Action Controls: Live Status Pill, Base Currency View Switcher, Migration Button, Refresh Button — Strictly Single Line */}
        <div className="flex items-center gap-2 flex-nowrap shrink-0 overflow-x-auto scrollbar-none py-1">
          {/* Live Status Pill */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 text-xs font-bold border border-emerald-500/20 shrink-0 whitespace-nowrap">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>{t("liveStatus")}</span>
          </div>

          {/* View Base Currency Switcher Dropdown */}
          <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 shadow-2xs shrink-0 whitespace-nowrap">
            <Globe className="h-3.5 w-3.5 text-gray-400 shrink-0" />
            <span className="text-[11px] font-semibold text-gray-400">View:</span>
            <select
              value={viewBaseCurrency}
              onChange={(e) => setViewBaseCurrency(e.target.value)}
              className="bg-transparent text-xs font-bold text-gray-900 dark:text-white outline-none cursor-pointer"
            >
              {ALL_CURRENCIES.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code}
                </option>
              ))}
            </select>
          </div>

          {/* Change Accounting Currency trigger */}
          <button
            type="button"
            onClick={() => {
              setPendingCurrency(baseCurrency === "USD" ? "EUR" : "USD");
              setMigrationModalOpen(true);
            }}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-purple-200 dark:border-purple-800/60 bg-purple-50/50 dark:bg-purple-950/20 text-xs font-bold text-purple-700 dark:text-purple-300 hover:border-purple-400 transition-colors shadow-2xs shrink-0 whitespace-nowrap"
          >
            <Wallet className="h-3.5 w-3.5 text-purple-600 dark:text-purple-400 shrink-0" />
            <span>Base: {baseCurrency}</span>
          </button>

          {/* Manual Refresh Button */}
          <button
            type="button"
            onClick={loadInitialData}
            disabled={isRefreshing}
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold shadow-md shadow-purple-500/20 transition-all duration-150 active:scale-95 disabled:opacity-50 shrink-0 whitespace-nowrap"
          >
            <RefreshCw className={`h-3.5 w-3.5 shrink-0 ${isRefreshing ? "animate-spin" : ""}`} />
            <span>{t("refresh")}</span>
          </button>
        </div>
      </div>

      {/* 2. Top Live Market Ticker Marquee / Strip */}
      {marketPairs.length > 0 && (
        <LiveMarketTicker
          pairs={marketPairs}
          activePairSymbol={selectedPair?.symbol}
          onSelectPair={handleSelectPair}
          isArabic={isArabic}
        />
      )}

      {/* 3. Section Navigation Tabs (All-in-One vs Segmented) */}
      <div className="flex items-center gap-2 border-b border-gray-200 dark:border-gray-800 pb-2 overflow-x-auto scrollbar-none">
        <button
          type="button"
          onClick={() => setActiveTab("markets")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
            activeTab === "markets"
              ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
              : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
          }`}
        >
          <Sparkles className="h-4 w-4" />
          <span>{isArabic ? "الأسواق والمحول المباشر" : "Markets & Converter"}</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("binance")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
            activeTab === "binance"
              ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
              : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
          }`}
        >
          <Zap className="h-4 w-4 text-amber-400 fill-amber-400" />
          <span>{isArabic ? "مخطط بينانس اللحظي (ثانية بثانية)" : "Live Binance Ticker (1s)"}</span>
          <span className="h-2 w-2 rounded-full bg-emerald-400 animate-pulse" />
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("risk")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
            activeTab === "risk"
              ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
              : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
          }`}
        >
          <Calculator className="h-4 w-4" />
          <span>{isArabic ? "حاسبة مخاطر الفواتير" : "Invoice Risk Simulator"}</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("alerts")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
            activeTab === "alerts"
              ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
              : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
          }`}
        >
          <Bell className="h-4 w-4" />
          <span>{isArabic ? "تنبيهات الأسعار المستهدفة" : "Price Alerts"}</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab("directory")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all shrink-0 ${
            activeTab === "directory"
              ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
              : "text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800"
          }`}
        >
          <Layers className="h-4 w-4" />
          <span>{isArabic ? "دليل جميع العملات" : "Rates Directory"}</span>
        </button>
      </div>

      {/* Tab 1: Markets & Live Interactive Converter */}
      {activeTab === "markets" && (
        <div className="space-y-6 animate-in fade-in">
          {/* Featured 4 Spotlight Currency Pairs */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Sparkles className="h-4 w-4 text-[#8b5cf6]" />
                <span>{t("featuredPairs")} ({viewBaseCurrency})</span>
              </h2>
              <span className="text-xs text-gray-400 dark:text-gray-500">
                {isArabic ? "انقر على أي بطاقة لعرض تفاصيلها" : "Click any card to analyze & trade"}
              </span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {featuredPairs.map((pair) => (
                <FeaturedPairCard
                  key={pair.symbol}
                  pair={pair}
                  isSelected={selectedPair?.symbol === pair.symbol}
                  onSelect={handleSelectPair}
                  isArabic={isArabic}
                />
              ))}
            </div>
          </div>

          {/* Interactive Trailing Chart & Live Converter (2-Column Grid) */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
            {/* Left Column: Interactive Trailing Rate Chart (7 cols) */}
            <div className="lg:col-span-7 flex flex-col space-y-3">
              {/* Chart Mode Switcher Bar */}
              <div className="flex items-center justify-between bg-white dark:bg-gray-900/70 p-2 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-2xs">
                <div className="flex items-center gap-1.5">
                  <button
                    type="button"
                    onClick={() => setChartMode("binance")}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                      chartMode === "binance"
                        ? "bg-[#6c4cf5] text-white shadow-sm shadow-purple-500/30"
                        : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800"
                    }`}
                  >
                    <Zap className="h-3.5 w-3.5 text-amber-400 fill-amber-400" />
                    <span>{isArabic ? "بينانس اللحظي (ثانية بثانية)" : "Binance Live (1s Ticks)"}</span>
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-ping" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setChartMode("macro")}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                      chartMode === "macro"
                        ? "bg-[#6c4cf5] text-white shadow-sm shadow-purple-500/30"
                        : "text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800"
                    }`}
                  >
                    <TrendingUp className="h-3.5 w-3.5 text-purple-400" />
                    <span>{isArabic ? "المسار التاريخي (1M - 1Y)" : "Historical Trajectory"}</span>
                  </button>
                </div>
                {selectedPair && (
                  <span className="text-xs font-mono font-bold text-gray-500 dark:text-gray-400 px-2">
                    {selectedPair.symbol}: {selectedPair.rate.toFixed(4)}
                  </span>
                )}
              </div>

              {selectedPair && chartMode === "binance" && (
                <BinanceLiveChart
                  symbol={selectedPair.symbol}
                  baseRate={selectedPair.rate}
                  isArabic={isArabic}
                />
              )}

              {selectedPair && chartMode === "macro" && (
                <FxTrajectoryChart
                  fromCurrency={selectedPair.base}
                  toCurrency={selectedPair.target}
                  data={chartHistory}
                  timeframe={timeframe}
                  onTimeframeChange={setTimeframe}
                  isLoading={chartLoading}
                  isArabic={isArabic}
                />
              )}
            </div>

            {/* Right Column: Two-Way Live Currency Converter Widget (5 cols) */}
            <div className="lg:col-span-5 flex flex-col">
              {selectedPair && (
                <FxConverterWidget
                  initialFrom={selectedPair.base}
                  initialTo={selectedPair.target}
                  initialAmount={1000}
                  businessBalance={netBalance}
                  onPairChange={handleConverterPairChange}
                  isArabic={isArabic}
                />
              )}
            </div>
          </div>

          {/* Business Portfolio Impact Card */}
          <BusinessPortfolioImpactCard
            businessName={businessName}
            baseCurrency={baseCurrency}
            netBalance={netBalance}
            marketPairs={marketPairs}
            isArabic={isArabic}
          />
        </div>
      )}

      {/* Tab: Full-Width Binance Live Candlestick & Ticker Station */}
      {activeTab === "binance" && selectedPair && (
        <div className="space-y-6 animate-in fade-in">
          {/* Pair quick selector pills */}
          <div className="bg-white dark:bg-gray-900 p-4 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-2xs space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider flex items-center gap-1.5">
                <Zap className="h-3.5 w-3.5 text-amber-400 fill-amber-400" />
                <span>{isArabic ? "اختر زوج التداول المباشر:" : "Select Live Ticker Pair:"}</span>
              </span>
              <span className="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold flex items-center gap-1">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                {isArabic ? "محرك الأسعار الحية نشط" : "Live WebStream Active"}
              </span>
            </div>
            <div className="flex items-center gap-2 overflow-x-auto scrollbar-none pb-1">
              {marketPairs.slice(0, 10).map((pair) => (
                <button
                  key={pair.symbol}
                  type="button"
                  onClick={() => setSelectedPair(pair)}
                  className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-mono font-bold transition-all shrink-0 ${
                    selectedPair.symbol === pair.symbol
                      ? "bg-[#6c4cf5] text-white shadow-md shadow-purple-500/25"
                      : "bg-gray-50 dark:bg-gray-800/80 border border-gray-200 dark:border-gray-700/60 text-gray-700 dark:text-gray-300 hover:border-purple-400"
                  }`}
                >
                  <span>{pair.symbol}</span>
                  <span className={pair.change24h >= 0 ? "text-emerald-400 font-bold" : "text-rose-400 font-bold"}>
                    {pair.rate.toFixed(4)}
                  </span>
                </button>
              ))}
            </div>
          </div>

          <BinanceLiveChart
            symbol={selectedPair.symbol}
            baseRate={selectedPair.rate}
            isArabic={isArabic}
          />
        </div>
      )}

      {/* Tab 2: Invoice FX Risk & Sensitivity Simulator */}
      {activeTab === "risk" && (
        <div className="animate-in fade-in space-y-6">
          <FxInvoiceRiskSimulator
            baseCurrency={baseCurrency}
            marketPairs={marketPairs}
            isArabic={isArabic}
          />
        </div>
      )}

      {/* Tab 3: Target Rate Alerts */}
      {activeTab === "alerts" && (
        <div className="animate-in fade-in space-y-6">
          <FxRateAlerts
            pairs={marketPairs}
            baseCurrency={baseCurrency}
            isArabic={isArabic}
          />
        </div>
      )}

      {/* Tab 4: All Rates Reference Directory Table */}
      {activeTab === "directory" && (
        <div className="rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 overflow-hidden shadow-xs animate-in fade-in">
          <div className="p-5 border-b border-gray-100 dark:border-gray-800 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                {t("table.title")}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                {isArabic 
                  ? `قائمة أسعار الصرف الحية المقومة بـ (${viewBaseCurrency})`
                  : `Live exchange rates indexed against (${viewBaseCurrency})`}
              </p>
            </div>

            {/* Search filter input */}
            <div className="relative w-full sm:w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={t("searchPlaceholder")}
                className="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/70 dark:bg-gray-800/70 text-gray-900 dark:text-white outline-none focus:border-purple-500 transition-colors"
              />
            </div>
          </div>

          {/* Table Content */}
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-gray-50/70 dark:bg-gray-800/50 text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider text-[10px] border-b border-gray-100 dark:border-gray-800">
                <tr>
                  <th className="py-3.5 px-6">{t("table.currency")}</th>
                  <th className="py-3.5 px-4">{t("table.code")}</th>
                  <th className="py-3.5 px-4 font-mono">{t("table.rateAgainstBase", { base: viewBaseCurrency })}</th>
                  <th className="py-3.5 px-4">{t("table.change")}</th>
                  <th className="py-3.5 px-6 text-right">{t("table.action")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {filteredCurrencies.map((c) => {
                  const directPair = marketPairs.find((p) => p.base === viewBaseCurrency && p.target === c.code);
                  const inversePair = marketPairs.find((p) => p.base === c.code && p.target === viewBaseCurrency);

                  let rate = 1.0;
                  let change = 0.25;

                  if (c.code === viewBaseCurrency) {
                    rate = 1.0;
                    change = 0.0;
                  } else if (directPair) {
                    rate = directPair.rate;
                    change = directPair.change24h;
                  } else if (inversePair && inversePair.rate > 0) {
                    rate = 1 / inversePair.rate;
                    change = -inversePair.change24h;
                  } else {
                    rate = c.code === "EUR" ? 0.92 : c.code === "TND" ? 2.99 : c.code === "GBP" ? 0.79 : 1.15;
                  }

                  const isPositive = change >= 0;

                  return (
                    <tr
                      key={c.code}
                      className="hover:bg-gray-50/60 dark:hover:bg-gray-800/40 transition-colors"
                    >
                      <td className="py-3.5 px-6">
                        <div className="flex items-center gap-3">
                          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gray-100 dark:bg-gray-800 font-bold text-gray-700 dark:text-gray-300 font-mono text-xs shadow-2xs">
                            {c.symbol}
                          </div>
                          <div>
                            <span className="font-bold text-gray-900 dark:text-white block">
                              {isArabic ? c.nameAr : c.nameEn}
                            </span>
                            <span className="text-[10px] text-gray-400">
                              {c.code}
                            </span>
                          </div>
                        </div>
                      </td>

                      <td className="py-3.5 px-4 font-mono font-bold text-gray-800 dark:text-gray-200">
                        {c.code}
                      </td>

                      <td className="py-3.5 px-4 font-mono font-black text-gray-900 dark:text-white">
                        {rate.toFixed(4)}
                      </td>

                      <td className="py-3.5 px-4">
                        <div
                          className={`inline-flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full ${
                            isPositive
                              ? "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400"
                              : "bg-rose-500/10 text-rose-600 dark:text-rose-400"
                          }`}
                        >
                          {isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
                          <span>{change >= 0 ? "+" : ""}{change.toFixed(2)}%</span>
                        </div>
                      </td>

                      <td className="py-3.5 px-6 text-right">
                        <button
                          type="button"
                          onClick={() => {
                            handleConverterPairChange(viewBaseCurrency, c.code);
                            setActiveTab("markets");
                            window.scrollTo({ top: 380, behavior: "smooth" });
                          }}
                          className="px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-700 hover:border-purple-500 text-xs font-bold text-gray-700 dark:text-gray-300 hover:text-purple-600 dark:hover:text-purple-400 transition-colors"
                        >
                          {t("table.useInConverter")}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Real-Time Currency Migration Modal */}
      {pendingCurrency && (
        <CurrencyMigrationModal
          isOpen={migrationModalOpen}
          oldCurrency={baseCurrency}
          newCurrency={pendingCurrency}
          onClose={() => {
            setMigrationModalOpen(false);
            setPendingCurrency(null);
          }}
          onSuccess={(newCurr) => {
            setBaseCurrency(newCurr);
            setViewBaseCurrency(newCurr);
            loadInitialData();
          }}
        />
      )}
    </div>
  );
}
