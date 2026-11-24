"use client";

import { useEffect, useState } from "react";
import { ArrowUpRight, Users } from "lucide-react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/routing";
import { formatCurrency } from "@/lib/currency";
import { CustomerItem } from "@/lib/api/dashboard";
import { CustomerService } from "@/lib/api/customers";

type TopCustomerDisplay = CustomerItem & {
  email?: string;
  ordersCount?: number;
};

function isAvatarImageUrl(value?: string): boolean {
  if (!value) return false;
  return /^(https?:\/\/|\/|data:image\/)/i.test(value.trim());
}

export function TopCustomers({ customers, currency = "USD" }: { customers: TopCustomerDisplay[]; currency?: string }) {
  const tCust = useTranslations("Dashboard.customers");
  const [storedCustomers, setStoredCustomers] = useState<TopCustomerDisplay[]>([]);

  useEffect(() => {
    if (!customers || customers.length === 0) {
      CustomerService.getSummary("month", currency)
        .then((res) => {
          if (res?.topCustomers?.length) {
            setStoredCustomers(res.topCustomers);
          }
        })
        .catch(() => { });
    }
  }, [customers, currency]);

  const list = customers && customers.length > 0 ? customers : storedCustomers;

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-4 sm:p-6 shadow-sm">
      <div className="flex items-center justify-between mb-4 sm:mb-6">
        <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tCust("title")}</h3>
        <Link
          href="/dashboard/customers"
          className="text-xs font-semibold text-[var(--primary)] hover:text-[var(--primary-hover)] transition-colors"
        >
          {tCust("viewAll")}
        </Link>
      </div>

      {list.length === 0 ? (
        <div className="py-8 flex flex-col items-center justify-center text-center">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-100 dark:bg-white/5 text-gray-400 mb-2.5">
            <Users className="h-5 w-5" />
          </div>
          <p className="text-xs font-semibold text-gray-700 dark:text-gray-300">No customers yet.</p>
          <p className="text-[11px] text-gray-400 dark:text-gray-500 mt-0.5 max-w-xs">
            Add customers and record orders to track your highest-revenue accounts.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {list.map((customer) => (
            <div key={customer.id} className="flex items-center justify-between group">
              <Link href="/dashboard/customers" className="flex items-center gap-3 min-w-0">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-[var(--primary)]/20 bg-[var(--primary)]/10 text-xs font-bold text-[var(--primary)]">
                  {customer.avatar && isAvatarImageUrl(customer.avatar) ? (
                    <img src={customer.avatar} alt={customer.name} className="h-full w-full object-cover" />
                  ) : (
                    <span>
                      {customer.avatar && customer.avatar.trim().length <= 3
                        ? customer.avatar.trim().toUpperCase()
                        : (customer.name || "C").charAt(0).toUpperCase()}
                    </span>
                  )}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-[var(--primary)] transition-colors truncate">
                    {customer.name}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                    {customer.ordersCount != null ? `${customer.ordersCount} orders` : customer.email || "Active customer"}
                  </p>
                </div>
              </Link>

              <div className="text-end flex items-center gap-2 sm:gap-4 shrink-0">
                <div>
                  <div className="text-sm font-bold text-gray-900 dark:text-white">
                    {formatCurrency(customer.revenue || 0, currency)}
                  </div>
                  <div className="text-[10px] text-gray-500">{tCust("revenue")}</div>
                </div>
                <Link
                  href="/dashboard/customers"
                  className="flex h-8 w-8 items-center justify-center rounded-lg text-gray-400 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-white/[0.05] dark:hover:text-white transition-colors"
                >
                  <ArrowUpRight className="h-4 w-4" />
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
