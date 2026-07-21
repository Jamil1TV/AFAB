/**
 * DashboardMockup – A fully coded HTML/CSS dashboard preview.
 * Matches the actual dashboard precisely (Sidebar, Header, KPI Cards, AI Insights).
 */
export function DashboardMockup() {
  return (
    <div className="w-full rounded-[20px] overflow-hidden border border-gray-200/60 dark:border-[#1e1b4b]/40 bg-white dark:bg-[#080c18] text-[10px] leading-tight select-none shadow-2xl">
      <div className="flex h-[420px] sm:h-[480px] md:h-[520px]">

        {/* ═══ SIDEBAR ═══ */}
        <div className="w-[110px] sm:w-[130px] shrink-0 bg-gray-50/50 dark:bg-[#080c18] flex flex-col p-3 sm:p-4 border-r border-gray-200 dark:border-gray-800/60 relative">
          
          {/* Brand */}
          <div className="flex items-center justify-between mb-6 bg-gray-100 dark:bg-white/[0.05] p-1.5 rounded-lg">
            <div className="flex items-center gap-1.5 overflow-hidden">
              <div className="h-5 w-5 shrink-0 rounded-md bg-gradient-to-br from-[#7c3aed] to-[#8b5cf6] flex items-center justify-center">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" className="text-white">
                  <path d="M12 2L2 12L12 22L22 12L12 2Z" fill="currentColor" opacity="0.3" />
                  <path d="M12 7L7 12L12 17L17 12L12 7Z" fill="currentColor" />
                </svg>
              </div>
              <div className="flex flex-col overflow-hidden">
                <span className="truncate text-[9px] font-bold text-gray-900 dark:text-white">Acme Corp</span>
                <span className="truncate text-[6px] font-medium text-gray-500 uppercase">Free Plan</span>
              </div>
            </div>
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-gray-400 shrink-0"><path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/></svg>
          </div>

          {/* Nav Items */}
          <nav className="flex flex-col gap-0.5 flex-1">
            {/* Active */}
            <div className="flex items-center justify-between px-2 py-1.5 rounded-lg bg-[#8b5cf6]/10 text-[#7c3aed] dark:bg-[#8b5cf6]/20 dark:text-[#a78bfa] text-[8px] font-medium">
              <div className="flex items-center gap-1.5">
                <svg width="10" height="10" viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="1" width="6" height="6" rx="1.5"/><rect x="9" y="1" width="6" height="6" rx="1.5"/><rect x="1" y="9" width="6" height="6" rx="1.5"/><rect x="9" y="9" width="6" height="6" rx="1.5"/></svg>
                Overview
              </div>
            </div>
            {[
              { label: "Transactions", icon: "⇄" },
              { label: "Expenses", icon: "📉" },
              { label: "Revenue", icon: "📈" },
              { label: "Invoices", icon: "📄" },
              { label: "Customers", icon: "👥" },
              { label: "Reports", icon: "📊" },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-gray-500 dark:text-gray-400 text-[8px] font-medium">
                <span className="text-[8px] w-[10px] text-center opacity-60">{item.icon}</span>
                {item.label}
              </div>
            ))}
            
            <div className="mt-4 mb-1 px-2">
              <h4 className="text-[6px] font-bold uppercase text-gray-400">Workspace</h4>
            </div>
            
            <div className="flex items-center justify-between px-2 py-1.5 rounded-lg text-gray-500 dark:text-gray-400 text-[8px] font-medium">
              <div className="flex items-center gap-1.5">
                <span className="text-[8px] w-[10px] text-center opacity-60">✨</span>
                AI Assistant
              </div>
              <span className="bg-[#8b5cf6] text-white text-[6px] px-1.5 py-0.5 rounded-full font-bold">New</span>
            </div>
          </nav>

          {/* Upgrade Card */}
          <div className="mt-auto bg-gradient-to-br from-[#7c3aed] to-[#6d28d9] rounded-xl p-2.5 relative overflow-hidden">
            <div className="absolute -right-4 -top-4 h-12 w-12 rounded-full bg-white/10 blur-xl" />
            <p className="text-white font-bold text-[9px] mb-0.5 relative z-10">Upgrade to Pro</p>
            <p className="text-white/80 text-[7px] mb-2 leading-[1.4] relative z-10">Unlock AI insights, custom reports, and unlimited invoices.</p>
            <div className="bg-white text-[#7c3aed] text-center py-1 rounded-md text-[8px] font-bold relative z-10">Upgrade Now</div>
          </div>
        </div>

        {/* ═══ MAIN CONTENT ═══ */}
        <div className="flex-1 flex flex-col overflow-hidden bg-gray-50/30 dark:bg-transparent">

          {/* Header */}
          <div className="flex items-center justify-between px-4 sm:px-5 py-3 border-b border-gray-200 dark:border-gray-800/60 bg-white/80 dark:bg-[#080c18]/80 backdrop-blur-sm">
            <div className="flex-1">
              <div className="relative w-48 hidden sm:block">
                <div className="absolute inset-y-0 left-0 flex items-center pl-2">
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-gray-400"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
                </div>
                <div className="w-full bg-gray-50 dark:bg-[#12162b] border border-gray-200 dark:border-gray-700/60 rounded-full py-1.5 pl-6 pr-2 text-[8px] text-gray-400">Search transactions, invoices...</div>
                <div className="absolute inset-y-0 right-0 flex items-center pr-2">
                  <span className="text-[6px] border border-gray-200 dark:border-gray-700 rounded px-1 text-gray-400">⌘K</span>
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <div className="hidden sm:flex items-center gap-1 bg-white dark:bg-[#12162b] border border-gray-200 dark:border-gray-700/60 rounded-lg px-2 py-1 text-[8px] text-gray-500 dark:text-gray-300">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>
                This Month
              </div>
              <div className="flex items-center justify-center w-6 h-6 rounded-full border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-white/[0.06]">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-gray-500 dark:text-gray-400"><circle cx="12" cy="12" r="10"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
              </div>
              <div className="flex items-center justify-center w-6 h-6 rounded-full relative">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-gray-500 dark:text-gray-400"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
                <div className="absolute top-0 right-0 w-1.5 h-1.5 bg-[#7c3aed] rounded-full border border-white dark:border-[#080c18]" />
              </div>
              <div className="bg-[#7c3aed] text-white rounded-full px-3 py-1.5 flex items-center gap-1 text-[8px] font-bold">
                <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="M12 5v14"/></svg>
                Create
              </div>
            </div>
          </div>

          <div className="px-4 sm:px-5 pt-4 pb-2">
            <h2 className="text-gray-900 dark:text-white font-bold text-[14px] sm:text-[18px]">Good Morning, Ahmed 👋</h2>
            <p className="text-gray-500 dark:text-gray-400 text-[9px] mt-0.5">Here&apos;s what&apos;s happening with your business today.</p>
          </div>

          {/* Stats Row */}
          <div className="grid grid-cols-4 gap-2 px-4 sm:px-5 pb-2">
            {[
              { label: "Total Revenue", value: "$24,850.00", change: "+12.5%", isPos: true },
              { label: "Total Expenses", value: "$9,420.00", change: "-8.4%", isPos: false },
              { label: "Net Profit", value: "$15,430.00", change: "+33.4%", isPos: true },
              { label: "Cash Flow", value: "$8,750.00", change: "+16.7%", isPos: true },
            ].map((stat) => (
              <div key={stat.label} className="bg-white dark:bg-[#0c101c] rounded-xl p-3 border border-gray-200 dark:border-gray-800/60 shadow-sm">
                <div className="flex items-center gap-1.5 mb-2">
                  <div className="w-5 h-5 rounded bg-gray-50 dark:bg-white/[0.03] flex items-center justify-center">
                    <div className="w-2.5 h-2.5 rounded-full border border-gray-400" />
                  </div>
                  <p className="text-gray-500 dark:text-gray-400 text-[8px] font-medium">{stat.label}</p>
                </div>
                <p className="text-gray-900 dark:text-white font-bold text-[13px] sm:text-[15px] tracking-tight">{stat.value}</p>
                <div className="flex items-center gap-1 mt-1">
                  <span className={`text-[7px] font-bold px-1 rounded-sm ${stat.isPos ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400" : "bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400"}`}>{stat.change}</span>
                  <span className="text-gray-400 text-[7px]">vs last month</span>
                </div>
              </div>
            ))}
          </div>

          {/* Chart + AI Insights Row */}
          <div className="grid grid-cols-[1fr_180px] sm:grid-cols-[1fr_220px] gap-2 px-4 sm:px-5 pb-2 flex-1 min-h-0">
            {/* Revenue Chart */}
            <div className="bg-white dark:bg-[#0c101c] rounded-xl p-4 border border-gray-200 dark:border-gray-800/60 flex flex-col shadow-sm relative overflow-hidden">
              <div className="flex items-center justify-between mb-3 z-10">
                <div>
                  <h3 className="text-gray-900 dark:text-white font-bold text-[11px]">Revenue & Expenses</h3>
                  <p className="text-gray-500 dark:text-gray-400 text-[8px]">Your cash flow over the last 7 days</p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-[#8b5cf6]" /><span className="text-[7px] text-gray-500 dark:text-gray-400">Revenue</span></div>
                  <div className="flex items-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-[#0ea5e9]" /><span className="text-[7px] text-gray-500 dark:text-gray-400">Expenses</span></div>
                </div>
              </div>

              {/* Chart Graphics */}
              <div className="flex-1 min-h-0 relative z-0">
                <svg viewBox="0 0 300 100" className="w-full h-full" preserveAspectRatio="none">
                  {[0, 25, 50, 75, 100].map((y) => (
                    <line key={y} x1="0" y1={y} x2="300" y2={y} stroke="currentColor" strokeWidth="0.5" className="text-gray-100 dark:text-[#1a1f35]" />
                  ))}
                  {/* Expense Line (Blue) */}
                  <path d="M0,80 Q40,90 80,75 T160,70 T240,75 T300,65" fill="none" stroke="#0ea5e9" strokeWidth="2" strokeLinecap="round" />
                  <path d="M0,80 Q40,90 80,75 T160,70 T240,75 T300,65 L300,100 L0,100 Z" fill="url(#expenseGrad)" opacity="0.3" />
                  <defs>
                    <linearGradient id="expenseGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#0ea5e9" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="#0ea5e9" stopOpacity="0" />
                    </linearGradient>
                  </defs>

                  {/* Revenue Line (Purple) */}
                  <path d="M0,60 Q40,65 80,40 T160,15 T240,40 T300,30" fill="none" stroke="#8b5cf6" strokeWidth="2" strokeLinecap="round" />
                  <path d="M0,60 Q40,65 80,40 T160,15 T240,40 T300,30 L300,100 L0,100 Z" fill="url(#revenueGrad)" opacity="0.4" />
                  <defs>
                    <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#8b5cf6" stopOpacity="0.5" />
                      <stop offset="100%" stopColor="#8b5cf6" stopOpacity="0" />
                    </linearGradient>
                  </defs>
                </svg>
              </div>
            </div>

            {/* AI Insights Card */}
            <div className="relative overflow-hidden rounded-xl border border-[#8b5cf6]/30 bg-gradient-to-br from-[#f5f0ff] to-white dark:from-[#131128] dark:to-[#0c101c] p-4 shadow-sm">
              <div className="absolute -right-8 -top-8 h-24 w-24 rounded-full bg-[#8b5cf6]/20 blur-xl" />
              
              <div className="flex items-center justify-between mb-3 relative z-10">
                <div className="flex items-center gap-1.5">
                  <div className="h-5 w-5 rounded-full bg-[#8b5cf6] flex items-center justify-center text-white">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m12 3-1.912 5.813a2 2 0 0 1-1.275 1.275L3 12l5.813 1.912a2 2 0 0 1 1.275 1.275L12 21l1.912-5.813a2 2 0 0 1 1.275-1.275L21 12l-5.813-1.912a2 2 0 0 1-1.275-1.275L12 3Z"/></svg>
                  </div>
                  <h3 className="text-gray-900 dark:text-white font-bold text-[10px]">AI Assistant Insights</h3>
                </div>
                <span className="bg-[#8b5cf6]/10 text-[#7c3aed] dark:text-[#a78bfa] border border-[#8b5cf6]/30 text-[7px] px-1.5 py-0.5 rounded-full font-bold">Premium</span>
              </div>

              <div className="space-y-2 relative z-10">
                <div className="bg-white/60 dark:bg-black/20 p-2 rounded-lg border border-gray-100 dark:border-white/5 backdrop-blur-sm">
                  <p className="text-gray-900 dark:text-gray-200 font-semibold text-[8px]"><span className="text-[#8b5cf6] mr-1">✦</span> High Marketing Spend</p>
                  <p className="text-gray-500 dark:text-gray-400 text-[7px] mt-0.5 leading-relaxed">Marketing expenses are up 42% this month. Consider optimizing your Google Ads campaigns.</p>
                </div>
                <div className="bg-white/60 dark:bg-black/20 p-2 rounded-lg border border-gray-100 dark:border-white/5 backdrop-blur-sm">
                  <p className="text-gray-900 dark:text-gray-200 font-semibold text-[8px]"><span className="text-[#8b5cf6] mr-1">✦</span> Unused Subscriptions</p>
                  <p className="text-gray-500 dark:text-gray-400 text-[7px] mt-0.5 leading-relaxed">3 software subscriptions haven't been used in 60+ days. Canceling saves $340/mo.</p>
                </div>
              </div>

              <div className="mt-4 relative z-10">
                <div className="bg-gray-900 dark:bg-white text-white dark:text-gray-900 text-center py-1.5 rounded-lg text-[9px] font-bold flex items-center justify-center gap-1">
                  Ask AI Assistant 
                  <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
