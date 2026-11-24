"use client";

import { useState, useEffect, useRef } from "react";

/**
 * Wrapper that measures its box via ResizeObserver and delays mounting children
 * until width > 0 and height > 0, preventing Recharts "width(-1) height(-1)" warnings
 * across responsive grid/flex layouts, theme switches, and RTL flips.
 */
export function ChartContainer({
  children,
  className = "",
  minHeight = 200,
}: {
  children: React.ReactNode;
  className?: string;
  minHeight?: number;
}) {
  const [hasSize, setHasSize] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    let mounted = true;
    const measure = () => {
      if (!mounted || !el) return;
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        setHasSize(true);
      }
    };

    // Use requestAnimationFrame + slight timeout to ensure container has computed CSS layout
    const raf = requestAnimationFrame(() => {
      measure();
      if (!hasSize) {
        setTimeout(measure, 50);
      }
    });

    let observer: ResizeObserver | null = null;
    if (typeof ResizeObserver !== "undefined") {
      observer = new ResizeObserver((entries) => {
        for (const entry of entries) {
          const { width, height } = entry.contentRect;
          if (width > 0 && height > 0 && mounted) {
            setHasSize(true);
          }
        }
      });
      observer.observe(el);
    }

    return () => {
      mounted = false;
      cancelAnimationFrame(raf);
      observer?.disconnect();
    };
  }, [hasSize]);

  return (
    <div
      ref={ref}
      style={{ minHeight: `${minHeight}px`, height: "100%" }}
      className={`relative w-full h-full min-w-0 min-h-0 ${className}`}
    >
      {hasSize ? children : null}
    </div>
  );
}
