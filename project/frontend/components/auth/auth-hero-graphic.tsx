"use client";

import { LineChart, BarChart2, Star, FileText } from "lucide-react";

import { useLocale } from 'next-intl';

export function AuthHeroGraphic() {
  const locale = useLocale();
  const isArabic = locale === 'ar';

  return (
    <div className="relative w-full h-full min-h-0 flex items-end justify-center pb-8">
      
      {/* ── Background Ambient Glows ── */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-[20%] left-[10%] w-[300px] h-[300px] rounded-full bg-[#7c3aed]/15 blur-[90px]" />
        <div className="absolute bottom-[10%] right-[20%] w-[250px] h-[250px] rounded-full bg-[#3b82f6]/10 blur-[80px]" />
      </div>

      {/* ── Main 3D Composition Container ── */}
      <div 
        className="relative w-[400px] h-[400px] scale-[0.8] xl:scale-[0.95] origin-bottom"
        style={{ perspective: '1200px' }}
      >
        {/* 3D Scene Wrapper - Tilts everything to face left-to-right */}
        <div 
          className="w-full h-full absolute inset-0"
          style={{
            transformStyle: 'preserve-3d',
            transform: isArabic ? 'rotateY(-25deg) rotateX(10deg) rotateZ(2deg)' : 'rotateY(25deg) rotateX(10deg) rotateZ(-2deg)'
          }}
        >
          
          {/* ── Floating Icons Background ── */}
          <div className={`absolute top-[10%] ${isArabic ? 'right-[-10%]' : 'left-[-10%]'}`} style={{ transform: 'translateZ(-20px)' }}>
            <div className="w-10 h-10 rounded-[12px] bg-gradient-to-tr from-[#6d28d9] to-[#8b5cf6] shadow-lg flex items-center justify-center animate-float-slow">
              <Star className="text-white fill-white w-5 h-5" />
            </div>
          </div>
          <div className={`absolute bottom-[15%] ${isArabic ? 'right-[-5%]' : 'left-[-5%]'}`} style={{ transform: 'translateZ(10px)' }}>
            <div className="w-8 h-8 rounded-[10px] bg-gradient-to-tr from-[#16a34a] to-[#22c55e] shadow-lg flex items-center justify-center animate-float-delayed">
              <BarChart2 className="text-white w-4 h-4" />
            </div>
          </div>
          <div className={`absolute bottom-[10%] ${isArabic ? 'left-[10%]' : 'right-[10%]'}`} style={{ transform: 'translateZ(40px)' }}>
            <div className="w-10 h-10 rounded-[12px] bg-gradient-to-tr from-[#2563eb] to-[#3b82f6] shadow-lg flex items-center justify-center animate-float">
              <FileText className="text-white w-5 h-5" />
            </div>
          </div>

          {/* ── Center Background Glass Panel ── */}
          <div className={`absolute top-[5%] ${isArabic ? 'right-[10%]' : 'left-[10%]'}`} style={{ transform: 'translateZ(-60px)' }}>
            <div className="w-[280px] h-[340px] rounded-[32px] bg-white/5 border border-white/10 backdrop-blur-md shadow-2xl" />
          </div>

          {/* ── Pie Chart Glass Panel (Right) ── */}
          <div className={`absolute top-[25%] ${isArabic ? 'left-[-15%]' : 'right-[-15%]'}`} style={{ transform: 'translateZ(20px)' }}>
            <div className="w-[180px] h-[180px] rounded-[24px] bg-white/10 dark:bg-white/5 border border-white/20 backdrop-blur-xl shadow-[0_20px_40px_rgba(0,0,0,0.3)] flex items-center justify-center animate-float-delayed">
              <div className="relative w-[100px] h-[100px]">
                {/* CSS Pie Chart */}
                <div className="absolute inset-0 rounded-full border-[16px] border-[#8b5cf6] border-r-transparent border-t-transparent transform rotate-45 shadow-lg" />
                <div className="absolute inset-0 rounded-full border-[16px] border-[#f59e0b] border-l-transparent border-b-transparent transform -rotate-45 shadow-lg" />
                <div className="absolute inset-0 rounded-full border-[16px] border-[#3b82f6] border-b-transparent border-r-transparent border-l-transparent transform rotate-45 shadow-lg" />
                <div className="absolute inset-0 rounded-full border-[16px] border-[#6d28d9] border-t-transparent border-r-transparent border-l-transparent transform rotate-45 shadow-lg" />
              </div>
            </div>
          </div>

          {/* ── Revenue Purple Card (Top Left) ── */}
          <div className={`absolute top-[0%] ${isArabic ? 'right-[-5%]' : 'left-[-5%]'}`} style={{ transform: 'translateZ(60px)' }}>
            <div className="w-[280px] h-[180px] rounded-[24px] bg-gradient-to-br from-[#8b5cf6] to-[#6d28d9] border border-white/20 shadow-[0_30px_60px_-15px_rgba(109,40,217,0.5)] p-5 animate-float">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-white/70 text-[13px] font-medium">{isArabic ? 'الإيرادات' : 'Revenue'}</p>
                  <h3 className="text-white text-[26px] font-bold mt-0.5">{isArabic ? '24,850 ر.ق' : '$24,850'}</h3>
                </div>
                <div className="bg-white/20 backdrop-blur-md px-2.5 py-1 rounded-full text-white text-[11px] font-semibold flex items-center">
                  + 12.5%
                </div>
              </div>
              <div className="mt-6 relative h-[50px] w-full">
                {/* SVG Line Chart */}
                <svg viewBox="0 0 240 50" className="w-full h-full overflow-visible">
                  <path 
                    d="M 0,40 C 30,40 50,15 80,25 C 110,35 130,5 170,15 C 200,25 220,0 240,10" 
                    fill="none" 
                    stroke="white" 
                    strokeWidth="3" 
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <circle cx="80" cy="25" r="4" fill="white" />
                  <circle cx="170" cy="15" r="4" fill="white" />
                  <circle cx="240" cy="10" r="4" fill="white" />
                </svg>
              </div>
            </div>
          </div>

          {/* ── Profit Dark Card (Bottom Left) ── */}
          <div className={`absolute top-[45%] ${isArabic ? 'right-[5%]' : 'left-[5%]'}`} style={{ transform: 'translateZ(100px)' }}>
            <div className="w-[240px] h-[140px] rounded-[24px] bg-[#161B2B] border border-[#2A3042] shadow-[0_30px_60px_-15px_rgba(0,0,0,0.8)] p-5 animate-float-slow overflow-hidden">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-gray-400 text-[13px] font-medium">{isArabic ? 'الأرباح' : 'Profit'}</p>
                  <h3 className="text-white text-[24px] font-bold mt-0.5">{isArabic ? '8,420 ر.ق' : '$8,420'}</h3>
                  <p className="text-[#22c55e] text-[11px] font-semibold mt-1">+ 8.2%</p>
                </div>
                <div className="bg-[#1F2537] w-7 h-7 rounded-full flex items-center justify-center">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
                  </svg>
                </div>
              </div>
              
              <div className="absolute bottom-0 left-5 right-5 flex items-end gap-1.5 h-10">
                <div className="w-1/6 bg-[#22c55e]/30 rounded-t-sm h-[40%]" />
                <div className="w-1/6 bg-[#22c55e]/50 rounded-t-sm h-[60%]" />
                <div className="w-1/6 bg-[#22c55e]/70 rounded-t-sm h-[50%]" />
                <div className="w-1/6 bg-[#22c55e]/90 rounded-t-sm h-[80%]" />
                <div className="w-1/6 bg-[#22c55e] rounded-t-sm h-[100%]" />
                <div className="w-1/6 bg-[#22c55e] rounded-t-sm h-[90%]" />
              </div>
            </div>
          </div>

        </div>
      </div>

      <style jsx global>{`
        @keyframes float {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-15px); }
        }
        @keyframes float-slow {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-10px); }
        }
        @keyframes float-delayed {
          0%, 100% { transform: translateY(0); }
          50% { transform: translateY(-20px); }
        }
        .animate-float {
          animation: float 6s ease-in-out infinite;
        }
        .animate-float-slow {
          animation: float-slow 8s ease-in-out infinite;
        }
        .animate-float-delayed {
          animation: float-delayed 7s ease-in-out infinite;
          animation-delay: 1.5s;
        }
      `}</style>
    </div>
  );
}
