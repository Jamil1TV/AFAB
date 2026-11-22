"use client";

import React, { useState, useEffect, useCallback } from "react";
import { 
  ArrowUpDown, 
  Check, 
  Copy, 
  ArrowRightLeft, 
  ShieldCheck
} from "lucide-react";
import { CurrencyService } from "@/lib/api/currencies";

interface FxConverterWidgetProps {
  initialFrom?: string;
  initialTo?: string;
  initialAmount?: number;
  businessBalance?: number;
  onPairChange?: (from: string, to: string) => void;
  isArabic?: boolean;
}

const POPULAR_CURRENCIES = [
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
];

export function FxConverterWidget({
  initialFrom = "EUR",
  initialTo = "USD",
  initialAmount = 1000,
  businessBalance = 0,
  onPairChange,
  isArabic = false,
}: FxConverterWidgetProps) {
  const [from, setFrom] = useState(initialFrom);
  const [to, setTo] = useState(initialTo);
  const [sendAmount, setSendAmount] = useState<string>(initialAmount.toString());
  const [receiveAmount, setReceiveAmount] = useState<string>("");
  const [rate, setRate] = useState<number>(1.0825);
  const [loading, setLoading] = useState<boolean>(false);
  const [swapRotating, setSwapRotating] = useState<boolean>(false);
  const [copied, setCopied] = useState<boolean>(false);
  const [lastEdited, setLastEdited] = useState<"send" | "receive">("send");

  // Keep from/to in sync with external clicks (e.g. clicking a pair card)
  useEffect(() => {
    if (initialFrom && initialFrom !== from) setFrom(initialFrom);
    if (initialTo && initialTo !== to) setTo(initialTo);
  }, [initialFrom, initialTo]);

  // Recalculate rate and amounts
  const updateConversion = useCallback(async () => {
    setLoading(true);
    try {
      const numSend = parseFloat(sendAmount) || 0;
      const res = await CurrencyService.convert(from, to, numSend);
      setRate(res.exchangeRate);

      if (lastEdited === "send") {
        setReceiveAmount(
          res.convertedAmount.toFixed(4).replace(/\.?0+$/, "") || "0"
        );
      }
    } catch (err) {
      console.warn("Conversion API fallback:", err);
      // Fallback calculation
      const numSend = parseFloat(sendAmount) || 0;
      setReceiveAmount((numSend * rate).toFixed(4).replace(/\.?0+$/, ""));
    } finally {
      setLoading(false);
    }
  }, [from, to, sendAmount, rate, lastEdited]);

  useEffect(() => {
    updateConversion();
  }, [from, to, sendAmount]);

  // Handle typing in the Send input
  const handleSendChange = (val: string) => {
    setLastEdited("send");
    setSendAmount(val);
    const parsed = parseFloat(val) || 0;
    if (rate > 0) {
      const converted = (parsed * rate).toFixed(4).replace(/\.?0+$/, "");
      setReceiveAmount(converted);
    }
  };

  // Handle typing in the Receive input (Two-Way Binding)
  const handleReceiveChange = (val: string) => {
    setLastEdited("receive");
    setReceiveAmount(val);
    const parsed = parseFloat(val) || 0;
    if (rate > 0) {
      const sendVal = (parsed / rate).toFixed(4).replace(/\.?0+$/, "");
      setSendAmount(sendVal);
    }
  };

  // Swap currencies with 180° rotation micro-animation
  const handleSwap = () => {
    setSwapRotating(true);
    const newFrom = to;
    const newTo = from;
    setFrom(newFrom);
    setTo(newTo);
    // Invert rate immediately for instant UI feedback
    const invRate = rate > 0 ? 1 / rate : 1.0;
    setRate(invRate);
    const numSend = parseFloat(sendAmount) || 0;
    setReceiveAmount((numSend * invRate).toFixed(4).replace(/\.?0+$/, ""));
    if (onPairChange) onPairChange(newFrom, newTo);
    setTimeout(() => setSwapRotating(false), 300);
  };

  // Copy result to clipboard
  const handleCopy = () => {
    if (!receiveAmount) return;
    navigator.clipboard.writeText(`${receiveAmount} ${to}`);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Amount preset chips
  const presets = [100, 500, 1000, 5000];

  // Business balance percentage chips
  const balancePresets = [
    { label: "25%", mult: 0.25 },
    { label: "50%", mult: 0.50 },
    { label: "75%", mult: 0.75 },
    { label: "Max", mult: 1.0 },
  ];

  return (
    <div className="afab-card p-6 flex flex-col justify-between transition-all duration-200">
      {/* Header */}
      <div className="flex items-center justify-between pb-4 border-b border-gray-100 dark:border-gray-800/60">
        <div>
          <h3 className="afab-card-title flex items-center gap-2">
            <ArrowRightLeft className="h-5 w-5 text-[#8b5cf6]" />
            <span>{isArabic ? "محول العملات الفوري المتطور" : "Live Two-Way Converter"}</span>
          </h3>
          <p className="afab-card-subtitle text-xs mt-0.5">
            {isArabic ? "تحويل ثنائي الاتجاه بأسعار بين البنوك لحظة بلحظة" : "Two-way live conversion with interbank rates"}
          </p>
        </div>

        <div className="afab-badge afab-badge-success px-2.5 py-1 rounded-full text-[11px] border border-emerald-500/20">
          <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
          <span>{isArabic ? "مباشر" : "Real-Time"}</span>
        </div>
      </div>

      {/* Converter Body */}
      <div className="py-4 space-y-3 relative">
        {/* FROM (You Send) Input Box */}
        <div className="afab-inset p-4 transition-all focus-within:border-[#8b5cf6] focus-within:ring-1 focus-within:ring-[#8b5cf6]">
          <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 font-semibold mb-1">
            <span>{isArabic ? "المبلغ المرسل / الأساسي" : "You Send"}</span>
            <span className="font-mono text-[11px] text-[#7c3aed] dark:text-[#a78bfa] font-bold">
              {from}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <input
              type="number"
              min="0"
              step="any"
              value={sendAmount}
              onChange={(e) => handleSendChange(e.target.value)}
              placeholder="0.00"
              className="w-full bg-transparent text-2xl font-bold text-gray-900 dark:text-white outline-none font-mono placeholder:text-gray-400"
            />

            <select
              value={from}
              onChange={(e) => {
                setFrom(e.target.value);
                if (onPairChange) onPairChange(e.target.value, to);
              }}
              className="afab-select text-sm font-bold text-gray-900 dark:text-white shrink-0 w-auto cursor-pointer"
            >
              {POPULAR_CURRENCIES.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code} — {c.symbol} ({isArabic ? c.nameAr : c.nameEn})
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Center Circular Swap Button with Spread Badge */}
        <div className="flex items-center justify-between -my-2 relative z-10 px-2">
          <div className="h-px bg-gray-100 dark:bg-gray-800/60 flex-1" />
          
          <button
            type="button"
            onClick={handleSwap}
            title={isArabic ? "تبديل العملتين" : "Swap currencies"}
            className="flex h-10 w-10 mx-3 items-center justify-center rounded-full bg-[#8b5cf6] hover:bg-[#7c3aed] text-white shadow-lg shadow-[#8b5cf6]/25 hover:scale-105 active:scale-95 transition-all duration-200 shrink-0"
          >
            <ArrowUpDown
              className={`h-4 w-4 transition-transform duration-300 ${
                swapRotating ? "rotate-180" : ""
              }`}
            />
          </button>

          <div className="h-px bg-gray-100 dark:bg-gray-800/60 flex-1" />
        </div>

        {/* TO (You Receive) Input Box — Two-Way Editable */}
        <div className="afab-inset p-4 transition-all focus-within:border-[#8b5cf6] focus-within:ring-1 focus-within:ring-[#8b5cf6]">
          <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400 font-semibold mb-1">
            <span>{isArabic ? "المبلغ المستلم (تقديري)" : "You Receive (Editable)"}</span>
            <div className="flex items-center gap-2">
              <span className="font-mono text-[11px] text-[#7c3aed] dark:text-[#a78bfa] font-bold">
                {to}
              </span>
              <button
                type="button"
                onClick={handleCopy}
                title={isArabic ? "نسخ النتيجة" : "Copy converted amount"}
                className="text-gray-400 hover:text-[#7c3aed] dark:hover:text-[#a78bfa] transition-colors"
              >
                {copied ? <Check className="h-3.5 w-3.5 text-emerald-500" /> : <Copy className="h-3.5 w-3.5" />}
              </button>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <input
              type="number"
              min="0"
              step="any"
              value={receiveAmount}
              onChange={(e) => handleReceiveChange(e.target.value)}
              placeholder="0.00"
              className="w-full bg-transparent text-2xl font-bold text-[#7c3aed] dark:text-[#a78bfa] outline-none font-mono placeholder:text-gray-400"
            />

            <select
              value={to}
              onChange={(e) => {
                setTo(e.target.value);
                if (onPairChange) onPairChange(from, e.target.value);
              }}
              className="afab-select text-sm font-bold text-gray-900 dark:text-white shrink-0 w-auto cursor-pointer"
            >
              {POPULAR_CURRENCIES.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code} — {c.symbol} ({isArabic ? c.nameAr : c.nameEn})
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Quick Presets & Business Balance Multipliers */}
        <div className="flex flex-col gap-2 pt-1">
          {/* Quick Amount Presets */}
          <div className="flex items-center gap-1.5 flex-wrap">
            <span className="text-[10px] font-semibold text-gray-400 dark:text-gray-500 uppercase">
              {isArabic ? "مبالغ:" : "Quick:"}
            </span>
            {presets.map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => handleSendChange(val.toString())}
                className={`px-2.5 py-1 text-[11px] font-bold rounded-lg transition-colors ${
                  parseFloat(sendAmount) === val
                    ? "bg-[#8b5cf6] text-white shadow-sm"
                    : "bg-gray-100 dark:bg-[#080c18] border border-gray-200/60 dark:border-gray-800/60 text-gray-600 dark:text-gray-300 hover:bg-gray-200/70 dark:hover:bg-white/[0.05]"
                }`}
              >
                +{val.toLocaleString()}
              </button>
            ))}
          </div>

          {/* Business Portfolio Percentage Presets */}
          {businessBalance > 0 && (
            <div className="flex items-center gap-1.5 flex-wrap pt-0.5">
              <span className="text-[10px] font-semibold text-[#7c3aed] dark:text-[#a78bfa] uppercase">
                {isArabic ? "من رصيدك:" : "Portfolio:"}
              </span>
              {balancePresets.map((bp) => {
                const calculated = Math.round(businessBalance * bp.mult);
                return (
                  <button
                    key={bp.label}
                    type="button"
                    onClick={() => handleSendChange(calculated.toString())}
                    className="px-2 py-0.5 text-[10px] font-bold rounded-md bg-purple-500/10 hover:bg-purple-500/20 text-[#7c3aed] dark:text-[#a78bfa] border border-purple-500/20 transition-colors"
                  >
                    {bp.label} ({calculated.toLocaleString()})
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Live Conversion Rate Summary with Spread & Transparency */}
      <div className="pt-3 border-t border-gray-100 dark:border-gray-800/60 space-y-1.5 text-xs">
        <div className="flex items-center justify-between">
          <span className="text-gray-500 dark:text-gray-400">
            {isArabic ? "سعر الصرف المباشر:" : "Mid-Market Rate:"}
          </span>
          <span className="font-bold text-gray-900 dark:text-white font-mono">
            1 {from} = {rate.toFixed(4)} {to}
          </span>
        </div>

        <div className="flex items-center justify-between text-[11px] text-gray-400 dark:text-gray-500">
          <span className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400 font-medium">
            <ShieldCheck className="h-3.5 w-3.5" />
            0.00% Markup • Zero Hidden Fees
          </span>
          <span>1 {to} = {(rate > 0 ? 1 / rate : 1).toFixed(4)} {from}</span>
        </div>
      </div>
    </div>
  );
}
