import { useTranslations } from "next-intl";

export function LogosSection() {
  const t = useTranslations("Home.logos");

  return (
    <section className="py-8 border-t border-gray-100 dark:border-gray-800/40">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <p className="mb-10 text-center text-sm font-medium text-gray-400 dark:text-gray-500">
          {t("title")}
        </p>
        <div className="flex flex-wrap items-center justify-center gap-10 sm:gap-14 lg:gap-20">

          {/* ── Dropbox ── */}
          <div className="flex items-center gap-2.5 grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <svg width="28" height="26" viewBox="0 0 528 512" className="text-[#0061FF]">
              <path fill="currentColor" d="M264.4 116.3l-132 84.3 132 84.3-132 84.3L0 284.1l132.3-84.3L0 116.3 132.3 32l132.1 84.3zM131.6 395.7l132-84.3 132 84.3-132 84.3-132-84.3zm132.8-111.6l132-84.3-132-84.3L396.4 32l132.3 84.3-132.3 84.3 132.3 84.3L396.4 369.2l-131.9-85.1z" />
            </svg>
            <span className="text-xl font-bold text-gray-900 dark:text-white tracking-tight">Dropbox</span>
          </div>

          {/* ── Notion ── */}
          <div className="flex items-center gap-2.5 grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <div className="flex h-7 w-7 items-center justify-center rounded-[6px] border-[1.5px] border-gray-800 dark:border-gray-300">
              <span className="text-gray-900 dark:text-white font-bold text-[16px] leading-none">N</span>
            </div>
            <span className="text-xl font-bold text-gray-900 dark:text-white tracking-tight">Notion</span>
          </div>

          {/* ── Stripe ── */}
          <div className="flex items-center grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <span className="text-[#635BFF] text-[30px] font-extrabold tracking-tight lowercase">stripe</span>
          </div>

          {/* ── Linear ── */}
          <div className="flex items-center gap-2.5 grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <svg width="24" height="24" viewBox="0 0 100 100" className="text-[#5E6AD2]">
              <path fill="currentColor" d="M1.22 61.5a48.85 48.85 0 0 0 37.28 37.28L1.22 61.5zm-1 8.55a49.43 49.43 0 0 0 30.73 29.73L.22 70.05zm2.94-11.2L44.73 99.4A49.57 49.57 0 0 0 50 99.9c.36 0 .72 0 1.08-.02L3.16 51.96a49.76 49.76 0 0 0 0 6.89zm3.53-14.42L55.1 92.84a49.4 49.4 0 0 0 8.55-4.14L10.83 35.88a49.4 49.4 0 0 0-4.14 8.55zm7.53-13.23L64.17 81.14a49.3 49.3 0 0 0 5.36-5.36L18.86 25.1a49.3 49.3 0 0 0-4.64 6.1zm11.27-11.94l50.46 50.46a49.4 49.4 0 0 0 4.14-8.55L33.66 10.74a49.4 49.4 0 0 0-8.17 9.52zM36.73 5.67l55.6 55.6c1.2-3.02 2.1-6.17 2.7-9.42L46.15 2.97a49.2 49.2 0 0 0-9.42 2.7zm17.38-4.8l43.93 43.93a49.5 49.5 0 0 0-.63-7.6L53.46.1c-2.57.04-5.1.27-7.6.77h1.25z" />
            </svg>
            <span className="text-xl font-bold text-gray-900 dark:text-white tracking-tight">Linear</span>
          </div>

          {/* ── Google ── */}
          <div className="flex items-center grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <span className="text-[26px] font-bold tracking-tight">
              <span className="text-[#4285F4]">G</span>
              <span className="text-[#EA4335]">o</span>
              <span className="text-[#FBBC05]">o</span>
              <span className="text-[#4285F4]">g</span>
              <span className="text-[#34A853]">l</span>
              <span className="text-[#EA4335]">e</span>
            </span>
          </div>

          {/* ── Microsoft ── */}
          <div className="flex items-center gap-2.5 grayscale opacity-50 hover:grayscale-0 hover:opacity-100 transition-all duration-300 cursor-pointer">
            <div className="grid grid-cols-2 gap-[2.5px]">
              <div className="h-[10px] w-[10px] bg-[#F25022]" />
              <div className="h-[10px] w-[10px] bg-[#7FBA00]" />
              <div className="h-[10px] w-[10px] bg-[#00A4EF]" />
              <div className="h-[10px] w-[10px] bg-[#FFB900]" />
            </div>
            <span className="text-xl font-semibold text-gray-900 dark:text-white tracking-tight">Microsoft</span>
          </div>

        </div>
      </div>
    </section>
  );
}
