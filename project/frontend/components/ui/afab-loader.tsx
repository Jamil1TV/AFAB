"use client";

import { useId } from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface AfabLoaderProps {
  className?: string;
  size?: "xs" | "sm" | "md" | "lg" | "xl";
  text?: string;
}

/**
 * Creative AFAB Quantum "A" Loader.
 * Features a bespoke aerodynamic geometric "A" monogram with:
 * - Internal fluid energy surge & upward light pulse (clipped to the "A" geometry)
 * - Continuous high-speed iridescent laser shimmer across the facets
 * - Perimeter photon path sprint along the "A" contour
 * - Dual counter-rotating orbital holographic rings (matching the circular AFAB logo badge)
 * - Ambient backdrop luminescence
 */
export function AfabLoader({ className, size = "md", text }: AfabLoaderProps) {
  const uid = useId().replace(/:/g, "_");

  // Dimensional scale for SVG container
  const sizeMap = {
    xs: { box: "w-5 h-5", px: 20, showRings: false, stroke: 1.2 },
    sm: { box: "w-8 h-8", px: 32, showRings: true, stroke: 1.5 },
    md: { box: "w-14 h-14", px: 56, showRings: true, stroke: 1.8 },
    lg: { box: "w-20 h-20", px: 80, showRings: true, stroke: 2.0 },
    xl: { box: "w-28 h-28", px: 112, showRings: true, stroke: 2.2 },
  };

  const currentSize = sizeMap[size];

  // Mathematically balanced, aerodynamic geometric monogram "A"
  // Outer apex (50, 10), feet (14, 88) & (86, 88), inner triangular counter (50, 28) -> (43, 50) -> (57, 50)
  const aPath = "M 50,10 L 86,88 L 68,88 L 58,64 L 42,64 L 32,88 L 14,88 Z M 50,28 L 43,50 L 57,50 Z";

  return (
    <div
      role="status"
      aria-label={text || "Loading"}
      className={cn("flex flex-col items-center justify-center gap-3 select-none", className)}
    >
      <div className={cn("relative flex items-center justify-center", currentSize.box)}>
        {/* ── Layer 1: Ambient Luminescent Aura (Soft Background Glow) ── */}
        {size !== "xs" && (
          <motion.div
            animate={{
              scale: [0.95, 1.15, 0.95],
              opacity: [0.45, 0.8, 0.45],
            }}
            transition={{
              duration: 2.4,
              repeat: Infinity,
              ease: "easeInOut",
            }}
            className="absolute inset-0 m-auto w-3/4 h-3/4 rounded-full bg-gradient-to-tr from-[var(--primary)]/35 via-[#06b6d4]/30 to-[#10b981]/25 blur-xl pointer-events-none"
          />
        )}

        {/* ── Layer 2: Main Vector Stage (SVG with Clipped Fluid Interior) ── */}
        <svg
          viewBox="0 0 100 100"
          className="w-full h-full overflow-visible"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            {/* 1. Mask that cuts all interior motion to the exact silhouette of the letter "A" */}
            <mask id={`mask_${uid}`}>
              <path d={aPath} fill="#ffffff" fillRule="evenodd" />
            </mask>

            {/* 2. Fluid Wave Energy Gradient */}
            <linearGradient id={`fluidGrad_${uid}`} x1="0" y1="1" x2="0" y2="0">
              <stop offset="0%" stopColor="#3b82f6" stopOpacity="0.85" />
              <stop offset="45%" stopColor="var(--primary)" stopOpacity="0.95" />
              <stop offset="85%" stopColor="#06b6d4" stopOpacity="1" />
              <stop offset="100%" stopColor="#10b981" stopOpacity="0.9" />
            </linearGradient>

            {/* 3. Diagonal Iridescent Shimmer Streak */}
            <linearGradient id={`shimmerGrad_${uid}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#ffffff" stopOpacity="0" />
              <stop offset="40%" stopColor="#ffffff" stopOpacity="0.15" />
              <stop offset="50%" stopColor="#ffffff" stopOpacity="0.95" />
              <stop offset="60%" stopColor="#06b6d4" stopOpacity="0.6" />
              <stop offset="100%" stopColor="#ffffff" stopOpacity="0" />
            </linearGradient>

            {/* 4. Fine Border Contour Gradient */}
            <linearGradient id={`borderGrad_${uid}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="var(--primary)" />
              <stop offset="50%" stopColor="#06b6d4" />
              <stop offset="100%" stopColor="#10b981" />
            </linearGradient>

            {/* 5. Perimeter Laser Tracer Gradient */}
            <linearGradient id={`laserGrad_${uid}`} x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="#ffffff" stopOpacity="1" />
              <stop offset="40%" stopColor="#06b6d4" stopOpacity="0.9" />
              <stop offset="100%" stopColor="var(--primary)" stopOpacity="0" />
            </linearGradient>

            {/* 6. Orbital Ring Gradient */}
            <linearGradient id={`orbitGrad_${uid}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="var(--primary)" stopOpacity="0.8" />
              <stop offset="50%" stopColor="#06b6d4" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#10b981" stopOpacity="0.8" />
            </linearGradient>
          </defs>

          {/* ── Outer Orbital Holographic Rings (Reflecting the AFAB Logo circular badge) ── */}
          {currentSize.showRings && (
            <>
              {/* Outer Clockwise Orbit */}
              <motion.circle
                cx="50"
                cy="50"
                r="45"
                stroke={`url(#orbitGrad_${uid})`}
                strokeWidth="1.2"
                strokeDasharray="18 12 6 12"
                strokeLinecap="round"
                animate={{ rotate: 360 }}
                transition={{
                  duration: 4,
                  repeat: Infinity,
                  ease: "linear",
                }}
                style={{ transformOrigin: "50px 50px" }}
              />

              {/* Inner Counter-Clockwise Dash Orbit */}
              <motion.circle
                cx="50"
                cy="50"
                r="41"
                stroke="currentColor"
                className="text-[#06b6d4]/30 dark:text-[#06b6d4]/40"
                strokeWidth="1"
                strokeDasharray="4 8"
                strokeLinecap="round"
                animate={{ rotate: -360 }}
                transition={{
                  duration: 6,
                  repeat: Infinity,
                  ease: "linear",
                }}
                style={{ transformOrigin: "50px 50px" }}
              />

              {/* Orbiting Satellite Photon Spark */}
              <motion.g
                animate={{ rotate: 360 }}
                transition={{
                  duration: 3,
                  repeat: Infinity,
                  ease: "linear",
                }}
                style={{ transformOrigin: "50px 50px" }}
              >
                <circle cx="50" cy="5" r="2.2" fill="#06b6d4" />
                <circle cx="50" cy="5" r="4" fill="#06b6d4" opacity="0.4" />
              </motion.g>
            </>
          )}

          {/* ── Masked Interior of the Letter "A" (Where the Magic Moves Inside) ── */}
          <g mask={`url(#mask_${uid})`}>
            {/* Ambient Base Silhouette (Always keeps the "A" visible) */}
            <rect
              x="0"
              y="0"
              width="100"
              height="100"
              fill="var(--primary)"
              className="opacity-15 dark:opacity-25"
            />

            {/* Rising Fluid Wave / Energy Level surging up and down inside the "A" */}
            <motion.g
              animate={{
                y: [25, -25, 25],
              }}
              transition={{
                duration: 2.2,
                repeat: Infinity,
                ease: "easeInOut",
              }}
            >
              <rect
                x="0"
                y="20"
                width="100"
                height="100"
                fill={`url(#fluidGrad_${uid})`}
                opacity="0.85"
              />
              {/* Dynamic Wave Ripple Crest */}
              <motion.path
                d="M 0,20 Q 25,12 50,20 T 100,20 L 100,30 L 0,30 Z"
                fill="#ffffff"
                opacity="0.4"
                animate={{
                  x: [-20, 20, -20],
                }}
                transition={{
                  duration: 1.6,
                  repeat: Infinity,
                  ease: "easeInOut",
                }}
              />
            </motion.g>

            {/* High-Intensity Laser Shimmer Sweep (Diagonal Light Streak inside the "A") */}
            <motion.rect
              x="-80"
              y="-20"
              width="45"
              height="140"
              fill={`url(#shimmerGrad_${uid})`}
              transform="rotate(28 50 50)"
              animate={{
                x: [-120, 160],
              }}
              transition={{
                duration: 1.8,
                repeat: Infinity,
                ease: [0.4, 0, 0.2, 1],
              }}
            />

            {/* Glowing Internal Quantum Core at the intersection */}
            <motion.circle
              cx="50"
              cy="39"
              r="6"
              fill="#06b6d4"
              animate={{
                scale: [0.7, 1.3, 0.7],
                opacity: [0.5, 0.95, 0.5],
              }}
              transition={{
                duration: 1.8,
                repeat: Infinity,
                ease: "easeInOut",
              }}
              style={{ transformOrigin: "50px 39px" }}
            />
          </g>

          {/* ── Layer 3: Razor-Sharp Perimeter Contour Outline ── */}
          <path
            d={aPath}
            fill="none"
            stroke={`url(#borderGrad_${uid})`}
            strokeWidth={currentSize.stroke}
            strokeLinejoin="round"
            fillRule="evenodd"
            className="opacity-90 drop-shadow-[0_0_4px_rgba(6,182,212,0.4)]"
          />

          {/* ── Layer 4: Running Laser Light Sprinting Around the Perimeter ── */}
          <motion.path
            d={aPath}
            fill="none"
            stroke={`url(#laserGrad_${uid})`}
            strokeWidth={currentSize.stroke + 0.6}
            strokeLinecap="round"
            strokeLinejoin="round"
            fillRule="evenodd"
            strokeDasharray="35 150"
            animate={{
              strokeDashoffset: [0, -185],
            }}
            transition={{
              duration: 2.2,
              repeat: Infinity,
              ease: "linear",
            }}
          />
        </svg>
      </div>

      {/* ── Optional Shimmering Loading Text ── */}
      {text && (
        <motion.p
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
          className="text-xs sm:text-[13px] font-semibold tracking-wide text-transparent bg-clip-text bg-gradient-to-r from-gray-700 via-gray-900 to-gray-700 dark:from-gray-300 dark:via-white dark:to-gray-300 animate-pulse text-center"
        >
          {text}
        </motion.p>
      )}
    </div>
  );
}
