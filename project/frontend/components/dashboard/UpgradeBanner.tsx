"use client";

import { Sparkles, ArrowRight, CheckCircle2 } from "lucide-react";
import { useTranslations } from "next-intl";

export function UpgradeBanner() {
  const tBanner = useTranslations("Dashboard.banner");
  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#7c3aed] to-[#6d28d9] text-white shadow-lg shadow-[#7c3aed]/20 sm:col-span-2 lg:col-span-4">
      {/* Background decoration */}
      <div className="absolute -right-20 -top-20 h-64 w-64 rounded-full bg-white/10 blur-[80px]" />
      <div className="absolute -bottom-20 -left-20 h-64 w-64 rounded-full bg-white/10 blur-[80px]" />
      
      <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-6 p-6 sm:p-8">
        <div className="flex-1 space-y-4">
          <div className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-bold backdrop-blur-sm">
            <Sparkles className="h-3.5 w-3.5 text-[#a78bfa]" />
            {tBanner("pro")}
          </div>
          
          <h2 className="text-2xl sm:text-3xl font-bold tracking-tight">
            {tBanner("title")}
          </h2>
          
          <p className="max-w-2xl text-white/80 text-sm sm:text-base leading-relaxed">
            {tBanner("desc")}
          </p>

          <div className="flex flex-wrap items-center gap-4 pt-2">
            {[tBanner("unlimitedAI"), tBanner("customReports"), tBanner("apiAccess")].map((feature) => (
              <div key={feature} className="flex items-center gap-1.5 text-sm font-medium text-white/90">
                <CheckCircle2 className="h-4 w-4 text-[#a78bfa]" />
                {feature}
              </div>
            ))}
          </div>
        </div>

        <div className="flex w-full md:w-auto shrink-0 flex-col items-center gap-3">
          <button className="group flex w-full md:w-auto items-center justify-center gap-2 rounded-xl bg-white px-6 py-3 font-bold text-[#7c3aed] transition-all hover:bg-gray-50 hover:scale-[1.02] active:scale-[0.98] shadow-md shadow-white/10">
            {tBanner("upgradeBtn")}
            <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
          </button>
          <p className="text-xs font-medium text-white/60">
            {tBanner("price")}
          </p>
        </div>
      </div>
    </div>
  );
}
