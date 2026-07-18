/**
 * DashboardMockup – A fully coded HTML/CSS dashboard preview.
 * NO images needed. Renders pixel-perfectly in both light and dark mode.
 * Matches the Stitch design mockup exactly.
 */
export function DashboardMockup() {
  return (
    <div className="w-full rounded-[20px] overflow-hidden border border-gray-200/60 dark:border-[#1e1b4b]/40 bg-white dark:bg-[#080c18] text-[10px] leading-tight select-none">
      <div className="flex h-[420px] sm:h-[480px] md:h-[520px]">

        {/* ═══ SIDEBAR ═══ */}
        <div className="w-[110px] sm:w-[130px] shrink-0 bg-[#0f1117] flex flex-col p-3 sm:p-4 border-r border-gray-800/30">
          {/* Logo */}
          <div className="flex items-center gap-1.5 mb-5">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="#8b5cf6">
              <path d="M12 2L2 12L12 22L22 12L12 2Z" />
              <path d="M12 7L7 12L12 17L17 12L12 7Z" fill="#0f1117" />
              <path d="M12 9.5L9.5 12L12 14.5L14.5 12L12 9.5Z" fill="#8b5cf6" />
            </svg>
            <span className="text-white font-bold text-[11px]">AFAB</span>
          </div>

          {/* Nav Items */}
          <nav className="flex flex-col gap-0.5 flex-1">
            {/* Active */}
            <div className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg bg-[#8b5cf6] text-white text-[9px] font-medium">
              <svg width="10" height="10" viewBox="0 0 16 16" fill="currentColor"><rect x="1" y="1" width="6" height="6" rx="1.5"/><rect x="9" y="1" width="6" height="6" rx="1.5"/><rect x="1" y="9" width="6" height="6" rx="1.5"/><rect x="9" y="9" width="6" height="6" rx="1.5"/></svg>
              Overview
            </div>
            {[
              { label: "Transactions", icon: "⇄" },
              { label: "Expenses", icon: "📊" },
              { label: "Revenue", icon: "💰" },
              { label: "Invoices", icon: "📄" },
              { label: "Customers", icon: "👥" },
              { label: "Reports", icon: "📈" },
              { label: "AI Assistant", icon: "✨" },
              { label: "Settings", icon: "⚙" },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-gray-400 hover:text-gray-200 text-[9px] cursor-pointer transition-colors">
                <span className="text-[8px] w-[10px] text-center opacity-60">{item.icon}</span>
                {item.label}
              </div>
            ))}
          </nav>

          {/* Upgrade Card */}
          <div className="mt-auto bg-[#161927] rounded-xl p-2.5 border border-gray-800/40">
            <p className="text-white font-semibold text-[9px] mb-0.5">Upgrade to Pro</p>
            <p className="text-gray-500 text-[7px] mb-2 leading-[1.4]">Unlock all AI features, reports & more.</p>
            <div className="bg-[#8b5cf6] text-white text-center py-1 rounded-md text-[8px] font-semibold cursor-pointer hover:bg-[#7c3aed] transition-colors">Upgrade Now</div>
          </div>
        </div>

        {/* ═══ MAIN CONTENT ═══ */}
        <div className="flex-1 flex flex-col overflow-hidden bg-white dark:bg-[#080c18]">

          {/* Header */}
          <div className="flex items-center justify-between px-4 sm:px-5 pt-3 pb-2">
            <div>
              <h2 className="text-gray-900 dark:text-white font-bold text-[14px] sm:text-[16px]">Good Morning, Ahmed 👋</h2>
              <p className="text-gray-400 dark:text-gray-500 text-[8px] mt-0.5">Here&apos;s what&apos;s happening with your business today.</p>
            </div>
            <div className="flex items-center gap-2">
              <div className="hidden sm:flex items-center gap-1.5 bg-gray-50 dark:bg-[#111525] rounded-lg px-2.5 py-1.5 border border-gray-100 dark:border-gray-800/40">
                <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-gray-400"><circle cx="7" cy="7" r="5"/><path d="M11 11L14 14"/></svg>
                <span className="text-gray-400 text-[8px]">Search anything...</span>
              </div>
              <div className="h-6 w-6 rounded-full bg-gray-100 dark:bg-[#111525] flex items-center justify-center">
                <svg width="10" height="10" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" className="text-gray-400"><path d="M8 1.5a4 4 0 0 1 4 4v2.5l1.5 2H2.5L4 8V5.5a4 4 0 0 1 4-4z"/><path d="M6 12a2 2 0 0 0 4 0"/></svg>
              </div>
              <div className="h-7 w-7 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 border-2 border-white dark:border-gray-800" />
            </div>
          </div>

          {/* Stats Row */}
          <div className="grid grid-cols-4 gap-2 px-4 sm:px-5 pb-2">
            {[
              { label: "Revenue", value: "$24,850", change: "+12.5%", up: true },
              { label: "Expenses", value: "$9,420", change: "-8.4%", up: false },
              { label: "Profit", value: "$15,430", change: "+33.4%", up: true },
              { label: "Cash Flow", value: "$8,750", change: "+16.7%", up: true },
            ].map((stat) => (
              <div key={stat.label} className="bg-gray-50 dark:bg-[#0d1120] rounded-xl p-2.5 border border-gray-100 dark:border-gray-800/30">
                <p className="text-gray-500 dark:text-gray-400 text-[7px] mb-1">{stat.label}</p>
                <p className="text-gray-900 dark:text-white font-bold text-[13px] sm:text-[15px]">{stat.value}</p>
                <div className="flex items-center gap-0.5 mt-0.5">
                  <span className={`text-[7px] font-medium ${stat.up ? "text-emerald-500" : "text-red-500"}`}>{stat.change}</span>
                  <span className="text-gray-400 text-[6px]">vs last week</span>
                </div>
              </div>
            ))}
          </div>

          {/* Chart + AI Insights Row */}
          <div className="grid grid-cols-[1fr_160px] sm:grid-cols-[1fr_180px] gap-2 px-4 sm:px-5 pb-2 flex-1 min-h-0">
            {/* Revenue Chart */}
            <div className="bg-gray-50 dark:bg-[#0d1120] rounded-xl p-3 border border-gray-100 dark:border-gray-800/30 flex flex-col">
              <div className="flex items-center justify-between mb-1">
                <div>
                  <p className="text-gray-900 dark:text-white font-bold text-[11px]">Revenue Overview</p>
                  <div className="flex items-center gap-1 mt-0.5">
                    <span className="text-gray-900 dark:text-white font-bold text-[13px]">$24,850</span>
                    <span className="text-emerald-500 text-[7px] font-medium">+12.5%</span>
                    <span className="text-gray-400 text-[6px]">vs last 7 days</span>
                  </div>
                </div>
                <div className="text-[7px] text-gray-500 bg-white dark:bg-[#161927] px-2 py-0.5 rounded border border-gray-100 dark:border-gray-700/40">This Week ▾</div>
              </div>

              {/* Chart SVG */}
              <div className="flex-1 min-h-0 mt-1 relative">
                <svg viewBox="0 0 300 100" className="w-full h-full" preserveAspectRatio="none">
                  {/* Grid lines */}
                  {[0, 25, 50, 75, 100].map((y) => (
                    <line key={y} x1="0" y1={y} x2="300" y2={y} stroke="currentColor" strokeWidth="0.3" className="text-gray-200 dark:text-gray-800" />
                  ))}
                  {/* Chart line */}
                  <polyline
                    points="0,80 42,75 85,70 128,65 170,40 213,35 256,30 300,20"
                    fill="none"
                    stroke="#8b5cf6"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  {/* Gradient fill */}
                  <defs>
                    <linearGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#8b5cf6" stopOpacity="0.2" />
                      <stop offset="100%" stopColor="#8b5cf6" stopOpacity="0" />
                    </linearGradient>
                  </defs>
                  <polygon
                    points="0,80 42,75 85,70 128,65 170,40 213,35 256,30 300,20 300,100 0,100"
                    fill="url(#chartGrad)"
                  />
                  {/* Tooltip dot */}
                  <circle cx="170" cy="40" r="3" fill="#8b5cf6" />
                  <circle cx="170" cy="40" r="5" fill="#8b5cf6" opacity="0.2" />
                </svg>
                {/* Tooltip label */}
                <div className="absolute text-[7px] text-gray-500 dark:text-gray-400" style={{ left: "52%", top: "20%" }}>
                  <span className="font-medium text-gray-700 dark:text-gray-300">Thu, May 16</span>
                  <br />
                  <span className="font-bold text-gray-900 dark:text-white">$4,230</span>
                </div>
                {/* X-axis labels */}
                <div className="absolute bottom-0 left-0 right-0 flex justify-between text-[6px] text-gray-400">
                  <span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
                </div>
              </div>
            </div>

            {/* AI Insights */}
            <div className="bg-[#f5f0ff] dark:bg-[#0d1120] rounded-xl p-3 border border-purple-100 dark:border-gray-800/30 flex flex-col">
              <div className="flex items-center gap-1.5 mb-2">
                <span className="text-gray-900 dark:text-white font-bold text-[10px]">AI Insights</span>
                <span className="bg-[#8b5cf6] text-white text-[6px] px-1.5 py-0.5 rounded-full font-medium">New</span>
              </div>
              <div className="flex flex-col gap-2 flex-1 text-[7px]">
                <div>
                  <p className="text-gray-800 dark:text-gray-200 font-semibold flex items-center gap-0.5">
                    <span className="text-[#8b5cf6]">✦</span> Expenses increased by 18%
                  </p>
                  <p className="text-gray-500 dark:text-gray-500 mt-0.5 leading-[1.4]">Mainly from Marketing and Subscriptions.</p>
                </div>
                <div>
                  <p className="text-gray-800 dark:text-gray-200 font-semibold flex items-center gap-0.5">
                    <span className="text-[#8b5cf6]">✦</span> Cancel unused subscriptions
                  </p>
                  <p className="text-gray-500 dark:text-gray-500 mt-0.5 leading-[1.4]">You can save up to $320 this month.</p>
                </div>
                <div>
                  <p className="text-gray-800 dark:text-gray-200 font-semibold flex items-center gap-0.5">
                    <span className="text-[#8b5cf6]">✦</span> Profit can increase 12%
                  </p>
                  <p className="text-gray-500 dark:text-gray-500 mt-0.5 leading-[1.4]">By optimizing your product pricing.</p>
                </div>
              </div>
              <div className="mt-auto pt-1">
                <div className="bg-[#8b5cf6] text-white text-center py-1.5 rounded-lg text-[8px] font-semibold cursor-pointer hover:bg-[#7c3aed] transition-colors">Ask AI Assistant</div>
              </div>
            </div>
          </div>

          {/* Bottom Row: Transactions + Expense Categories */}
          <div className="grid grid-cols-2 gap-2 px-4 sm:px-5 pb-3">
            {/* Recent Transactions */}
            <div className="bg-gray-50 dark:bg-[#0d1120] rounded-xl p-2.5 border border-gray-100 dark:border-gray-800/30">
              <div className="flex items-center justify-between mb-2">
                <span className="text-gray-900 dark:text-white font-bold text-[10px]">Recent Transactions</span>
                <span className="text-[#8b5cf6] text-[7px] font-medium cursor-pointer">View all</span>
              </div>
              <div className="flex items-center gap-2 py-1.5 border-b border-gray-100 dark:border-gray-800/30">
                <div className="h-5 w-5 rounded-md bg-[#635BFF] flex items-center justify-center text-white text-[6px] font-bold shrink-0">S</div>
                <div className="flex-1 min-w-0">
                  <p className="text-gray-900 dark:text-white font-semibold text-[8px]">Stripe Payment</p>
                  <p className="text-gray-400 text-[6px]">May 18, 10:40 AM</p>
                </div>
                <span className="text-emerald-500 font-bold text-[8px]">+$1,250.00</span>
              </div>
            </div>

            {/* Expense Categories */}
            <div className="bg-gray-50 dark:bg-[#0d1120] rounded-xl p-2.5 border border-gray-100 dark:border-gray-800/30">
              <span className="text-gray-900 dark:text-white font-bold text-[10px] block mb-2">Expense Categories</span>
              <div className="flex items-start gap-3">
                {/* Donut chart */}
                <div className="relative shrink-0">
                  <svg width="56" height="56" viewBox="0 0 36 36">
                    <circle cx="18" cy="18" r="14" fill="none" stroke="#e5e7eb" className="dark:stroke-gray-800" strokeWidth="4" />
                    <circle cx="18" cy="18" r="14" fill="none" stroke="#8b5cf6" strokeWidth="4" strokeDasharray="37 63" strokeDashoffset="25" strokeLinecap="round" />
                    <circle cx="18" cy="18" r="14" fill="none" stroke="#06b6d4" strokeWidth="4" strokeDasharray="19 81" strokeDashoffset="88" strokeLinecap="round" />
                    <circle cx="18" cy="18" r="14" fill="none" stroke="#22c55e" strokeWidth="4" strokeDasharray="16 84" strokeDashoffset="69" strokeLinecap="round" />
                  </svg>
                  <div className="absolute inset-0 flex flex-col items-center justify-center">
                    <span className="text-gray-900 dark:text-white font-bold text-[9px]">$9,420</span>
                    <span className="text-gray-400 text-[5px]">Total</span>
                  </div>
                </div>
                {/* Legend */}
                <div className="flex flex-col gap-1 text-[7px]">
                  <div className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-[#8b5cf6]" />Marketing <span className="text-gray-400 ml-auto">42%</span></div>
                  <div className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-[#06b6d4]" />Subscriptions <span className="text-gray-400 ml-auto">22%</span></div>
                  <div className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-[#22c55e]" />Operations <span className="text-gray-400 ml-auto">18%</span></div>
                  <div className="flex items-center gap-1"><span className="h-1.5 w-1.5 rounded-full bg-gray-400" />Others <span className="text-gray-400 ml-auto">18%</span></div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
