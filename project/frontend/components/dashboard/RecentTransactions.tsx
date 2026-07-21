"use client";

import { ArrowUpRight, ArrowDownLeft, MoreHorizontal } from "lucide-react";
import { useTranslations } from "next-intl";

export function RecentTransactions({ transactions }: { transactions: any[] }) {
  const tTx = useTranslations("Dashboard.transactions");

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tTx("title")}</h3>
        <button className="text-xs font-semibold text-[#8b5cf6] hover:text-[#7c3aed] transition-colors">
          {tTx("viewAll")}
        </button>
      </div>

      <div className="space-y-4">
        {(transactions || []).map((tx) => (
          <div key={tx.id} className="flex items-center justify-between group">
            <div className="flex items-center gap-3">
              <div 
                className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-white text-xs font-bold shadow-sm ${tx.color}`}
              >
                {tx.initials}
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                  {tx.name}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {tx.date}
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="flex flex-col items-end">
                <span className={`text-sm font-bold flex items-center gap-1 ${tx.isCredit ? 'text-emerald-600 dark:text-emerald-400' : 'text-gray-900 dark:text-white'}`}>
                  {tx.isCredit ? <ArrowUpRight className="h-3 w-3" /> : <ArrowDownLeft className="h-3 w-3 text-gray-400" />}
                  {tx.amount}
                </span>
                <span className={`text-[10px] font-medium px-2 py-0.5 mt-1 rounded-full ${
                  tx.status === 'Completed' 
                    ? 'bg-gray-100 text-gray-600 dark:bg-white/5 dark:text-gray-400' 
                    : 'bg-orange-50 text-orange-600 dark:bg-orange-500/10 dark:text-orange-400'
                }`}>
                  {tx.status}
                </span>
              </div>
              <button className="hidden sm:flex h-8 w-8 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors">
                <MoreHorizontal className="h-4 w-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
