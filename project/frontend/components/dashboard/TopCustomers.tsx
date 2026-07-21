"use client";

import { ArrowUpRight } from "lucide-react";
import { useTranslations } from "next-intl";

export function TopCustomers({ customers }: { customers: any[] }) {
  const tCust = useTranslations("Dashboard.customers");

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tCust("title")}</h3>
        <button className="text-xs font-semibold text-[#8b5cf6] hover:text-[#7c3aed] transition-colors">
          {tCust("viewAll")}
        </button>
      </div>

      <div className="space-y-4">
        {(customers || []).map((customer) => (
          <div key={customer.id} className="flex items-center justify-between group">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full border border-gray-100 dark:border-gray-800">
                <img src={customer.avatar} alt={customer.name} className="h-full w-full object-cover" />
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[#8b5cf6] transition-colors">
                  {customer.name}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  12 orders
                </p>
              </div>
            </div>
            
            <div className="text-right flex items-center gap-4">
              <div>
                <div className="text-sm font-bold text-gray-900 dark:text-white">
                  ${customer.revenue.toLocaleString()}
                </div>
                <div className="text-[10px] text-gray-500">{tCust("revenue")}</div>
              </div>
              <button className="flex h-8 w-8 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors">
                <ArrowUpRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
