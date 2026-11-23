"use client";

import { useState, useEffect, useRef } from "react";

/**
 * Wrapper that measures its box via ResizeObserver and delays mounting children
 * until width > 0 and height > 0, preventing Recharts 3 "width(-1) height(-1)" warnings
 * across responsive grid/flex layouts, theme switches, and RTL flips.
 */
export function ChartContainer({
  children,
  className = "",
}: {
  children: React.ReactNode;
  className?: string;
}) {
  const [hasSize, setHasSize] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const measure = () => {
      const rect = el.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        setHasSize(true);
      }
    };

    const raf = requestAnimationFrame(measure);
    let observer: ResizeObserver | null = null;

    if (typeof ResizeObserver !== "undefined") {
      observer = new ResizeObserver((entries) => {
        for (const entry of entries) {
          const { width, height } = entry.contentRect;
          if (width > 0 && height > 0) {
            setHasSize(true);
          }
        }
      });
      observer.observe(el);
    }

    return () => {
      cancelAnimationFrame(raf);
      observer?.disconnect();
    };
  }, []);

  return (
    <div ref={ref} className={`min-w-0 min-h-0 ${className}`}>
      {hasSize ? children : null}
    </div>
  );
}
