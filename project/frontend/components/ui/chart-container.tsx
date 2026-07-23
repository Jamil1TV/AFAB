"use client";

import { useState, useEffect, useRef } from "react";

/**
 * Wrapper that delays rendering children until the container has positive dimensions.
 * Fixes Recharts "width(-1) height(-1)" warnings caused by flex layouts with w-0.
 */
export function ChartContainer({ 
  children, 
  className = "" 
}: { 
  children: React.ReactNode; 
  className?: string;
}) {
  const [ready, setReady] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Use requestAnimationFrame to wait for layout to complete
    const raf = requestAnimationFrame(() => {
      if (ref.current) {
        const { width, height } = ref.current.getBoundingClientRect();
        if (width > 0 && height > 0) {
          setReady(true);
        } else {
          // Fallback: try again after a short delay
          const timeout = setTimeout(() => setReady(true), 100);
          return () => clearTimeout(timeout);
        }
      }
    });
    return () => cancelAnimationFrame(raf);
  }, []);

  return (
    <div ref={ref} className={className}>
      {ready ? children : null}
    </div>
  );
}
