"use client";

import { ArrowUpRight, ArrowDownLeft, MoreHorizontal, Wallet, Plus } from "lucide-react";
import { useTranslations } from "next-intl";
import Link from "next/link";
import { formatCurrency } from "@/lib/currency";

export function RecentTransactions({ transactions, currency = "USD" }: { transactions: any[]; currency?: string }) {
  const tTx = useTranslations("Dashboard.transactions");

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm flex flex-col justify-between">
      <div>
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tTx("title")}</h3>
          <Link 
            href="/dashboard/transactions"
            className="text-xs font-semibold text-[#8b5cf6] hover:text-[#7c3aed] transition-colors"
          >
            {tTx("viewAll")}
          </Link>
        </div>

        {(!transactions || transactions.length === 0) ? (
          <div className="py-12 flex flex-col items-center justify-center text-center">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-purple-500/10 text-[#8b5cf6] mb-3">
              <Wallet className="h-6 w-6" />
            </div>
            <p className="text-sm font-semibold text-gray-800 dark:text-gray-200">No transactions recorded yet</p>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 max-w-xs">
              Add your first income or expense to see real-time cash flow and metrics.
            </p>
            <Link
              href="/dashboard/transactions"
              className="mt-4 inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#8b5cf6] text-white text-xs font-semibold hover:bg-[#7c3aed] transition-colors shadow-sm"
            >
              <Plus className="h-3.5 w-3.5" />
              Add Transaction
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {transactions.map((tx) => (
              <div key={tx.id} className="flex items-center justify-between group">
                <div className="flex items-center gap-3">
                  <div 
                    className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-white text-xs font-bold shadow-sm ${tx.color || "bg-purple-500"}`}
                  >
                    {tx.initials || "TX"}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                      {tx.name || tx.description}
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
                      {tx.rawAmount != null ? formatCurrency(tx.rawAmount, currency) : tx.amount}
                    </span>
                    <span className={`text-[10px] font-medium px-2 py-0.5 mt-1 rounded-full ${
                      tx.status === 'Completed' || tx.status === 'COMPLETED'
                        ? 'bg-gray-100 text-gray-600 dark:bg-white/5 dark:text-gray-400' 
                        : 'bg-orange-50 text-orange-600 dark:bg-orange-500/10 dark:text-orange-400'
                    }`}>
                      {tx.status}
                    </span>
                  </div>
                  <Link
                    href="/dashboard/transactions"
                    className="hidden sm:flex h-8 w-8 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors"
                  >
                    <MoreHorizontal className="h-4 w-4" />
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
