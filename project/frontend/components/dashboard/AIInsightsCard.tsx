"use client";

import { Sparkles, ArrowRight } from "lucide-react";
import { useTranslations } from "next-intl";

export function AIInsightsCard() {
  const tAi = useTranslations("Dashboard.ai");

  return (
    <div className="relative overflow-hidden rounded-2xl border border-[#8b5cf6]/30 bg-gradient-to-br from-[#f5f0ff] to-white dark:from-[#131128] dark:to-[#0c101c] p-6 shadow-sm shadow-[#8b5cf6]/10">
      {/* Background glow */}
      <div className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-[#8b5cf6]/20 blur-[50px] dark:bg-[#7c3aed]/20" />
      
      <div className="relative z-10 flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-[#8b5cf6] text-white shadow-sm shadow-[#8b5cf6]/30">
            <Sparkles className="h-4 w-4" />
          </div>
          <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tAi("title")}</h3>
        </div>
        <span className="rounded-full border border-[#8b5cf6]/30 bg-[#8b5cf6]/10 px-2.5 py-0.5 text-[10px] font-bold text-[#7c3aed] dark:text-[#a78bfa]">
          {tAi("premium")}
        </span>
      </div>

      <div className="relative z-10 space-y-4">
        <div className="rounded-xl bg-white/60 dark:bg-black/20 p-3 backdrop-blur-sm border border-gray-100 dark:border-white/5">
          <h4 className="text-xs font-semibold text-gray-900 dark:text-gray-200">
            <span className="text-[#8b5cf6] mr-1.5">✦</span> 
            {tAi("insight1Title")}
          </h4>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
            {tAi("insight1Desc")}
          </p>
        </div>

        <div className="rounded-xl bg-white/60 dark:bg-black/20 p-3 backdrop-blur-sm border border-gray-100 dark:border-white/5">
          <h4 className="text-xs font-semibold text-gray-900 dark:text-gray-200">
            <span className="text-[#8b5cf6] mr-1.5">✦</span> 
            {tAi("insight2Title")}
          </h4>
          <p className="mt-1 text-xs text-gray-500 dark:text-gray-400 leading-relaxed">
            {tAi("insight2Desc")}
          </p>
        </div>
      </div>

      <button className="relative z-10 mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-gray-900 dark:bg-white px-4 py-2.5 text-sm font-semibold text-white dark:text-gray-900 transition-all hover:bg-gray-800 dark:hover:bg-gray-100 shadow-md">
        {tAi("askBtn")} <ArrowRight className="h-4 w-4" />
      </button>
    </div>
  );
}
