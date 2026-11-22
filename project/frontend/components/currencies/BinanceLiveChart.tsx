"use client";

import React, { useState, useEffect, useRef, useMemo } from "react";
import { 
  Play, 
  Activity, 
  Flame,
  ArrowUp,
  ArrowDown
} from "lucide-react";

export interface Candle {
  time: string;
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface TradeTick {
  id: string;
  time: string;
  price: number;
  amount: number;
  side: "buy" | "sell";
}

interface BinanceLiveChartProps {
  symbol?: string; // e.g. "EUR/USD" or "USD/TND"
  baseRate?: number; // Initial spot rate e.g. 1.0825
  isArabic?: boolean;
  compact?: boolean;
}

const MAX_VISIBLE_TRADES = 8;

export function BinanceLiveChart({
  symbol = "EUR/USD",
  baseRate = 1.0825,
  isArabic = false,
  compact = false,
}: BinanceLiveChartProps) {
  const [isPlaying, setIsPlaying] = useState<boolean>(true);
  const [chartType, setChartType] = useState<"candles" | "line">("candles");
  const [interval, setInterval] = useState<"1s" | "5s" | "1m" | "15m">("1s");
  const [currentPrice, setCurrentPrice] = useState<number>(baseRate);
  const [priceFlash, setPriceFlash] = useState<"up" | "down" | null>(null);
  const [candles, setCandles] = useState<Candle[]>([]);
  const [recentTrades, setRecentTrades] = useState<TradeTick[]>([]);
  const containerRef = useRef<HTMLDivElement>(null);
  const lastPriceRef = useRef<number>(baseRate);
  const tradeSeqRef = useRef<number>(0);

  // Initialize historical candles deterministically from baseRate (client-only to avoid SSR clock mismatch)
  useEffect(() => {
    const frameId = window.requestAnimationFrame(() => {
      const initialCandles: Candle[] = [];
      let runningPrice = baseRate;
      const now = Date.now();
      const count = 36; // 36 candles for rich visual density
      const pairHash = Math.abs(
        symbol.split("").reduce((acc, ch) => acc * 31 + ch.charCodeAt(0), 7)
      );

      for (let i = count; i >= 1; i--) {
        const timeMs = now - i * 3000;
        const date = new Date(timeMs);
        const timeStr = date.toLocaleTimeString([], { hour12: false, minute: "2-digit", second: "2-digit" });
        const wave = Math.sin((i + pairHash) * 0.55) * 0.65 + Math.cos((i + pairHash) * 0.27) * 0.35;
        const delta = wave * (runningPrice * 0.0008);
        const open = runningPrice;
        const close = i === 1 ? baseRate : runningPrice + delta;
        const wickSpan = Math.abs(Math.sin((i + pairHash) * 0.9)) * (runningPrice * 0.0006) + runningPrice * 0.0002;
        const high = Math.max(open, close) + wickSpan;
        const low = Math.min(open, close) - wickSpan;
        const volume = 1200 + ((pairHash + i * 397) % 3800);

        initialCandles.push({
          time: timeStr,
          timestamp: timeMs,
          open,
          high,
          low,
          close,
          volume,
        });

        runningPrice = close;
      }

      lastPriceRef.current = baseRate;
      setCandles(initialCandles);
      setCurrentPrice(baseRate);

      // Initial trades anchored to deterministic candle closes
      const initialTrades: TradeTick[] = [];
      for (let j = 0; j < MAX_VISIBLE_TRADES; j++) {
        const refCandle = initialCandles[initialCandles.length - 1 - j] || initialCandles[0];
        const isBuy = refCandle.close >= refCandle.open;
        tradeSeqRef.current += 1;
        initialTrades.push({
          id: `init-${symbol}-${tradeSeqRef.current}`,
          time: new Date(now - j * 1200).toLocaleTimeString([], { hour12: false, minute: "2-digit", second: "2-digit" }),
          price: refCandle.close,
          amount: 2500 + ((pairHash + j * 1723) % 18000),
          side: isBuy ? "buy" : "sell",
        });
      }
      setRecentTrades(initialTrades);
    });

    return () => window.cancelAnimationFrame(frameId);
  }, [symbol, baseRate]);

  // Real-time ticking engine: deterministic micro-oscillation anchored to live mid-market baseRate
  useEffect(() => {
    if (!isPlaying) return;

    let step = 0;
    let flashTimeout: number | null = null;

    const tickTimer = window.setInterval(() => {
      step += 1;
      const now = Date.now();
      const nowSec = Math.floor(now / 1000);
      const prevPrice = lastPriceRef.current;
      const phase = Math.sin(nowSec * 0.85 + step * 0.6) * 0.00035;
      const newPrice = Number((baseRate * (1 + phase)).toFixed(4));
      const isUp = newPrice >= prevPrice;
      const nowStr = new Date(now).toLocaleTimeString([], {
        hour12: false,
        minute: "2-digit",
        second: "2-digit",
      });

      lastPriceRef.current = newPrice;
      setCurrentPrice(newPrice);

      // Flash price badge
      setPriceFlash(isUp ? "up" : "down");
      if (flashTimeout !== null) {
        window.clearTimeout(flashTimeout);
      }
      flashTimeout = window.setTimeout(() => setPriceFlash(null), 500);

      // Update or append candle (pure state updater — no nested setState calls)
      setCandles((prevCandles) => {
        if (prevCandles.length === 0) return prevCandles;

        const lastCandle = prevCandles[prevCandles.length - 1];
        const intervalMs = interval === "1s" ? 3000 : interval === "5s" ? 5000 : 15000;

        if (now - lastCandle.timestamp >= intervalMs) {
          const newCandle: Candle = {
            time: nowStr,
            timestamp: Math.max(now, lastCandle.timestamp + 1),
            open: lastCandle.close,
            high: Math.max(lastCandle.close, newPrice),
            low: Math.min(lastCandle.close, newPrice),
            close: newPrice,
            volume: 800 + ((nowSec * 173) % 1400),
          };

          // Keep max 42 candles on screen
          const sliced = prevCandles.length >= 42 ? prevCandles.slice(1) : prevCandles;
          return [...sliced, newCandle];
        } else {
          // Update the active candle in real time
          const updated: Candle = {
            ...lastCandle,
            high: Math.max(lastCandle.high, newPrice),
            low: Math.min(lastCandle.low, newPrice),
            close: newPrice,
            volume: lastCandle.volume + 120 + ((nowSec * 67) % 180),
          };

          return [...prevCandles.slice(0, -1), updated];
        }
      });

      // Add to live trade ticker with a strictly unique monotonic id
      tradeSeqRef.current += 1;
      const newTrade: TradeTick = {
        id: `tick-${symbol}-${tradeSeqRef.current}`,
        time: nowStr,
        price: newPrice,
        amount: 2000 + ((nowSec * 997) % 24000),
        side: isUp ? "buy" : "sell",
      };
      setRecentTrades((prevTrades) => [newTrade, ...prevTrades.slice(0, MAX_VISIBLE_TRADES - 1)]);
    }, 1000);

    return () => {
      window.clearInterval(tickTimer);
      if (flashTimeout !== null) {
        window.clearTimeout(flashTimeout);
      }
    };
  }, [isPlaying, interval, baseRate, symbol]);

  // Compute scale boundaries
  const { minPrice, maxPrice, priceRange, startPrice, netChange, netChangePct } = useMemo(() => {
    if (candles.length === 0) {
      return {
        minPrice: baseRate * 0.99,
        maxPrice: baseRate * 1.01,
        priceRange: baseRate * 0.02,
        startPrice: baseRate,
        netChange: 0,
        netChangePct: 0,
      };
    }

    const highs = candles.map((c) => c.high);
    const lows = candles.map((c) => c.low);
    const min = Math.min(...lows);
    const max = Math.max(...highs);
    const pad = (max - min) * 0.1 || 0.0005;
    const start = candles[0].open;
    const diff = currentPrice - start;
    const pct = start > 0 ? (diff / start) * 100 : 0;

    return {
      minPrice: min - pad,
      maxPrice: max + pad,
      priceRange: max - min + pad * 2,
      startPrice: start,
      netChange: diff,
      netChangePct: pct,
    };
  }, [candles, currentPrice, baseRate]);

  // SVG dimensions
  const svgWidth = 840;
  const svgHeight = 320;
  const paddingLeft = 15;
  const paddingRight = 75; // for price tags
  const paddingTop = 25;
  const paddingBottom = 40;
  const chartW = svgWidth - paddingLeft - paddingRight;
  const chartH = svgHeight - paddingTop - paddingBottom;

  // Normalized coordinate helpers
  const getY = (val: number) => {
    const norm = (val - minPrice) / (priceRange || 0.001);
    return paddingTop + (1 - norm) * chartH;
  };

  const candleWidth = Math.max(4, Math.min(14, chartW / Math.max(candles.length, 1) - 4));

  // Current price Y coordinate
  const currentPriceY = getY(currentPrice);

  return (
    <div className="afab-card p-5 sm:p-6 relative overflow-hidden transition-all">
      {/* Top Banner: Pair Info, 1s Live Ticker, 24h High/Low, Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-gray-100 dark:border-gray-800/60">
        <div className="flex items-center gap-3 min-w-0">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
            <Activity className="h-5 w-5 animate-pulse" />
          </div>

          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-lg font-bold tracking-tight text-gray-900 dark:text-white whitespace-nowrap">{symbol}</span>
              <span className="afab-badge afab-badge-success uppercase tracking-wider whitespace-nowrap shrink-0">
                {isArabic ? "بث بينانس مباشر" : "Binance Live Tick"}
              </span>
            </div>

            <div className="flex items-baseline gap-2.5 mt-0.5 flex-wrap">
              <span
                className={`text-xl sm:text-2xl font-bold font-mono tabular-nums tracking-tight transition-colors duration-300 ${
                  priceFlash === "up"
                    ? "text-emerald-600 dark:text-emerald-400"
                    : priceFlash === "down"
                    ? "text-red-600 dark:text-red-400"
                    : "text-gray-900 dark:text-white"
                }`}
              >
                {currentPrice.toFixed(4)}
              </span>

              <div
                className={`afab-badge whitespace-nowrap shrink-0 ${
                  netChange >= 0
                    ? "afab-badge-success"
                    : "afab-badge-danger"
                }`}
              >
                {netChange >= 0 ? <ArrowUp className="h-3 w-3" /> : <ArrowDown className="h-3 w-3" />}
                <span>{netChange >= 0 ? "+" : ""}{netChangePct.toFixed(2)}%</span>
              </div>
            </div>
          </div>
        </div>

        {/* Right Controls: Play/Pause, Interval Pills, Chart Style */}
        <div className="flex items-center gap-2 flex-wrap">
          {/* Pause / Resume Live Tick Stream */}
          <button
            type="button"
            onClick={() => setIsPlaying(!isPlaying)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border whitespace-nowrap transition-all ${
              isPlaying
                ? "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100 dark:bg-emerald-500/10 dark:text-emerald-400 dark:border-emerald-500/30 dark:hover:bg-emerald-500/20"
                : "afab-btn-secondary"
            }`}
            title={
              isPlaying
                ? isArabic
                  ? "إيقاف البث المباشر مؤقتاً"
                  : "Pause Live Feed"
                : isArabic
                ? "استئناف البث المباشر"
                : "Resume Live Feed"
            }
          >
            {isPlaying ? (
              <>
                <span className="relative flex h-2 w-2 shrink-0">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500 dark:bg-emerald-400" />
                </span>
                <span>{isArabic ? "بث مباشر" : "Live Active"}</span>
              </>
            ) : (
              <>
                <Play className="h-3.5 w-3.5" />
                <span>{isArabic ? "متوقف" : "Paused"}</span>
              </>
            )}
          </button>

          {/* Timeframe intervals */}
          <div className="afab-segmented">
            {(["1s", "5s", "1m", "15m"] as const).map((int) => (
              <button
                key={int}
                type="button"
                onClick={() => setInterval(int)}
                className={`afab-segment px-2.5 py-1 ${
                  interval === int ? "afab-segment-active" : ""
                }`}
              >
                {int}
              </button>
            ))}
          </div>

          {/* Candlestick vs Line toggle */}
          <div className="afab-segmented">
            <button
              type="button"
              onClick={() => setChartType("candles")}
              className={`afab-segment px-2.5 py-1 ${
                chartType === "candles" ? "afab-segment-active" : ""
              }`}
            >
              {isArabic ? "شموع" : "Candles"}
            </button>
            <button
              type="button"
              onClick={() => setChartType("line")}
              className={`afab-segment px-2.5 py-1 ${
                chartType === "line" ? "afab-segment-active" : ""
              }`}
            >
              {isArabic ? "موجة" : "Wave"}
            </button>
          </div>
        </div>
      </div>

      {/* Main Grid: Candlestick Chart Area + Real-Time Live Orderbook & Trades */}
      <div
        className={`grid grid-cols-1 gap-4 mt-4 items-stretch ${
          compact ? "xl:grid-cols-12" : "lg:grid-cols-12"
        }`}
      >
        {/* Candlestick SVG Viewport */}
        <div
          ref={containerRef}
          className={`${
            compact ? "xl:col-span-7" : "lg:col-span-8"
          } afab-inset p-2 relative h-[320px] overflow-hidden select-none`}
        >
          <svg viewBox={`0 0 ${svgWidth} ${svgHeight}`} className="w-full h-full overflow-visible">
            <defs>
              <linearGradient id="liveWaveGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#8b5cf6" stopOpacity="0.3" />
                <stop offset="100%" stopColor="#8b5cf6" stopOpacity="0" />
              </linearGradient>
            </defs>

            {/* Horizontal Gridlines & Price Labels */}
            {[0, 0.25, 0.5, 0.75, 1].map((ratio, idx) => {
              const y = paddingTop + ratio * chartH;
              const price = maxPrice - ratio * priceRange;
              return (
                <g key={idx}>
                  <line
                    x1={paddingLeft}
                    y1={y}
                    x2={svgWidth - paddingRight}
                    y2={y}
                    stroke="currentColor"
                    className="text-gray-200 dark:text-gray-800/50"
                    strokeDasharray="3 3"
                    strokeWidth="1"
                  />
                  <text
                    x={svgWidth - paddingRight + 8}
                    y={y + 3.5}
                    fontSize="10"
                    fontFamily="monospace"
                    fill="currentColor"
                    className="text-gray-400 dark:text-gray-500"
                  >
                    {price.toFixed(4)}
                  </text>
                </g>
              );
            })}

            {/* Wave Mode (Line chart) */}
            {chartType === "line" && (
              <g>
                {/* Area */}
                <path
                  d={(() => {
                    if (candles.length < 2) return "";
                    let d = `M ${paddingLeft} ${getY(candles[0].close)}`;
                    candles.forEach((c, idx) => {
                      const x = paddingLeft + (idx / (candles.length - 1)) * chartW;
                      d += ` L ${x} ${getY(c.close)}`;
                    });
                    const lastX = paddingLeft + chartW;
                    d += ` L ${lastX} ${svgHeight - paddingBottom} L ${paddingLeft} ${svgHeight - paddingBottom} Z`;
                    return d;
                  })()}
                  fill="url(#liveWaveGrad)"
                />
                {/* Line */}
                <path
                  d={(() => {
                    if (candles.length < 2) return "";
                    let d = `M ${paddingLeft} ${getY(candles[0].close)}`;
                    candles.forEach((c, idx) => {
                      const x = paddingLeft + (idx / (candles.length - 1)) * chartW;
                      d += ` L ${x} ${getY(c.close)}`;
                    });
                    return d;
                  })()}
                  fill="none"
                  stroke="#8b5cf6"
                  strokeWidth="2.5"
                />
              </g>
            )}

            {/* Candlestick Mode (OHLC + Wicks) */}
            {chartType === "candles" && (
              <g>
                {candles.map((c, idx) => {
                  const x = paddingLeft + (idx / Math.max(candles.length - 1, 1)) * chartW;
                  const isUp = c.close >= c.open;
                  const color = isUp ? "#0ECB81" : "#F6465D";

                  const yOpen = getY(c.open);
                  const yClose = getY(c.close);
                  const yHigh = getY(c.high);
                  const yLow = getY(c.low);

                  const bodyY = Math.min(yOpen, yClose);
                  const bodyHeight = Math.max(2, Math.abs(yClose - yOpen));

                  return (
                    <g key={c.timestamp} className="transition-all duration-100">
                      {/* Upper & Lower Wick Line */}
                      <line
                        x1={x}
                        y1={yHigh}
                        x2={x}
                        y2={yLow}
                        stroke={color}
                        strokeWidth="1.5"
                      />

                      {/* Candle Body */}
                      <rect
                        x={x - candleWidth / 2}
                        y={bodyY}
                        width={candleWidth}
                        height={bodyHeight}
                        fill={color}
                        rx="1"
                      />
                    </g>
                  );
                })}
              </g>
            )}

            {/* Live Ticking Horizontal Price Guide Line */}
            <line
              x1={paddingLeft}
              y1={currentPriceY}
              x2={svgWidth - paddingRight}
              y2={currentPriceY}
              stroke={netChange >= 0 ? "#0ECB81" : "#F6465D"}
              strokeDasharray="4 2"
              strokeWidth="1.5"
            />

            {/* Live Pulsing Price Radar Dot */}
            <circle
              cx={svgWidth - paddingRight}
              cy={currentPriceY}
              r="4.5"
              fill={netChange >= 0 ? "#0ECB81" : "#F6465D"}
              className="animate-ping"
            />
            <circle
              cx={svgWidth - paddingRight}
              cy={currentPriceY}
              r="3.5"
              fill="#FFFFFF"
            />

            {/* Live Price Tag on Right Axis */}
            <g transform={`translate(${svgWidth - paddingRight + 4}, ${currentPriceY - 9})`}>
              <rect
                x="0"
                y="0"
                width="64"
                height="18"
                rx="4"
                fill={netChange >= 0 ? "#0ECB81" : "#F6465D"}
              />
              <text
                x="32"
                y="12.5"
                textAnchor="middle"
                fontSize="10"
                fontFamily="monospace"
                fontWeight="bold"
                fill="#FFFFFF"
              >
                {currentPrice.toFixed(4)}
              </text>
            </g>
          </svg>
        </div>

        {/* Right Side: Real-Time Live Stream of Micro Trades (Binance Style) */}
        <div
          className={`${
            compact ? "xl:col-span-5" : "lg:col-span-4"
          } afab-inset p-3.5 h-[320px] overflow-hidden flex flex-col`}
        >
          <div className="flex items-center justify-between gap-2 pb-2 border-b border-gray-200/70 dark:border-gray-800/60 shrink-0">
            <span className="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5 min-w-0 truncate">
              <Flame className="h-3.5 w-3.5 text-amber-500 dark:text-amber-400 shrink-0" />
              <span className="truncate">
                {isArabic ? "صفقات السوق الحية" : "Live Market Trades"}
              </span>
            </span>
            <span className="text-[10px] text-gray-400 dark:text-gray-500 font-mono whitespace-nowrap shrink-0">
              {isArabic ? "بث 1ث" : "1s stream"}
            </span>
          </div>

          <div className="text-[10px] grid grid-cols-3 gap-1 text-gray-400 dark:text-gray-500 font-mono py-1.5 border-b border-gray-200/50 dark:border-gray-800/50 shrink-0">
            <span>{isArabic ? "الوقت" : "Time"}</span>
            <span>{isArabic ? "السعر" : "Price"}</span>
            <span className="text-end">{isArabic ? "الحجم" : "Volume"}</span>
          </div>

          {/* Trade list ticking in real time — fixed height, max 8 rows */}
          <div className="flex-1 min-h-0 overflow-hidden flex flex-col justify-between py-1">
            {recentTrades.slice(0, MAX_VISIBLE_TRADES).map((t) => (
              <div
                key={t.id}
                className="grid grid-cols-3 gap-1 text-[11px] font-mono tabular-nums leading-none py-1 items-center"
              >
                <span className="text-gray-500 dark:text-gray-400 truncate">{t.time}</span>
                <span
                  className={`font-bold truncate ${
                    t.side === "buy"
                      ? "text-emerald-600 dark:text-emerald-400"
                      : "text-red-600 dark:text-red-400"
                  }`}
                >
                  {t.price.toFixed(4)}
                </span>
                <span className="text-end text-gray-700 dark:text-gray-300 truncate">
                  {t.amount.toLocaleString()}
                </span>
              </div>
            ))}
          </div>

          {/* Footer spread insight */}
          <div className="pt-2 border-t border-gray-200/70 dark:border-gray-800/60 flex items-center justify-between gap-2 text-[10px] text-gray-500 dark:text-gray-400 font-mono shrink-0 whitespace-nowrap">
            <span className="truncate">{isArabic ? "الفارق: 0.04%" : "Spread: 0.04%"}</span>
            <span className="text-emerald-600 dark:text-emerald-400 flex items-center gap-1 shrink-0">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 dark:bg-emerald-400" />
              <span>{isArabic ? "سجل الأوامر متزامن" : "Orderbook Synced"}</span>
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
