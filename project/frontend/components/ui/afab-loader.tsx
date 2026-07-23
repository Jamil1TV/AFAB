"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface AfabLoaderProps {
  className?: string;
  size?: "xs" | "sm" | "md" | "lg" | "xl";
  text?: string;
}

export function AfabLoader({ className, size = "md", text }: AfabLoaderProps) {
  // Dimensions map
  const sizeMap = {
    xs: "w-5 h-5",
    sm: "w-8 h-8",
    md: "w-16 h-16",
    lg: "w-24 h-24",
    xl: "w-32 h-32",
  };

  const containerSize = sizeMap[size];

  return (
    <div className={cn("flex flex-col items-center justify-center gap-4", className)}>
      <div className={cn("relative", containerSize)}>
        {/* Outer rotating gradient ring */}
        <motion.div
          className="absolute inset-0 rounded-full border-y-2 border-primary/80 opacity-70"
          animate={{ rotate: 360 }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "linear",
          }}
        />

        {/* Inner reverse rotating ring */}
        <motion.div
          className="absolute inset-2 rounded-full border-x-2 border-emerald-500/80 opacity-70"
          animate={{ rotate: -360 }}
          transition={{
            duration: 3,
            repeat: Infinity,
            ease: "linear",
          }}
        />

        {/* Center glowing dot/logo representation */}
        <motion.div
          className="absolute inset-0 m-auto w-1/3 h-1/3 rounded-full bg-primary/40 blur-[4px]"
          animate={{
            scale: [1, 1.5, 1],
            opacity: [0.5, 1, 0.5],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />

        {/* Stylized "A" in the center */}
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="font-bold text-transparent bg-clip-text bg-gradient-to-br from-primary to-emerald-400 drop-shadow-lg font-mono tracking-tighter" style={{ fontSize: size === 'xl' ? '2.5rem' : size === 'lg' ? '1.5rem' : size === 'md' ? '1rem' : size === 'sm' ? '0.6rem' : '0.45rem' }}>
            A
          </span>
        </div>
      </div>

      {/* Optional loading text */}
      {text && (
        <motion.p
          className="text-sm font-medium text-muted-foreground animate-pulse"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
        >
          {text}
        </motion.p>
      )}
    </div>
  );
}
