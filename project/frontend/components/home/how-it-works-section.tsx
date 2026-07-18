import { useTranslations } from "next-intl";
import { Fragment } from "react";

const stepKeys = [
  { title: "step1Title", desc: "step1Desc" },
  { title: "step2Title", desc: "step2Desc" },
  { title: "step3Title", desc: "step3Desc" },
  { title: "step4Title", desc: "step4Desc" },
];

export function HowItWorksSection() {
  const t = useTranslations("Home.howItWorks");

  return (
    <section id="how-it-works" className="py-12 lg:py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">

        {/* ── Section Title ── */}
        <h2 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl mb-14">
          {t("title")}{" "}
          <span className="italic text-[#8b5cf6]">{t("titleHighlight")}</span>
        </h2>

        {/* ── Steps Row ── 
             On desktop: 7-column grid → card | arrow | card | arrow | card | arrow | card
             On mobile:  2-col grid, arrows hidden
        */}
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-[1fr_48px_1fr_48px_1fr_48px_1fr] lg:gap-0 items-stretch">

          {stepKeys.map((step, i) => (
            <Fragment key={step.title}>

              {/* ── Card ── */}
              <div className="relative flex flex-col h-full rounded-[20px] border border-gray-200/80 dark:border-gray-700/50 bg-white dark:bg-[#0d1225] p-7 sm:p-8 transition-all hover:shadow-xl dark:hover:shadow-[0_0_40px_rgba(139,92,246,0.06)]">

                {/* Step Number Badge */}
                <div className="mb-10">
                  <div className="inline-flex h-10 w-10 items-center justify-center rounded-xl bg-[#8b5cf6]/10 dark:bg-[#8b5cf6]/15 text-[#8b5cf6] text-base font-bold">
                    {i + 1}
                  </div>
                </div>

                {/* Content pushed to bottom */}
                <div className="mt-auto">
                  {/* Icon */}
                  <div className="mb-5 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-[#8b5cf6]/10 dark:bg-[#8b5cf6]/15 text-[#8b5cf6]">
                    {i === 0 && (
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="2" y="7" width="20" height="14" rx="2" />
                        <path d="M16 7V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v2" />
                        <line x1="12" y1="12" x2="12" y2="16" />
                        <line x1="10" y1="14" x2="14" y2="14" />
                      </svg>
                    )}
                    {i === 1 && (
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                        <polyline points="17 8 12 3 7 8" />
                        <line x1="12" y1="3" x2="12" y2="15" />
                      </svg>
                    )}
                    {i === 2 && (
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                        <circle cx="12" cy="12" r="10" />
                        <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
                        <line x1="2" y1="12" x2="22" y2="12" />
                      </svg>
                    )}
                    {i === 3 && (
                      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                        <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
                      </svg>
                    )}
                  </div>

                  {/* Title */}
                  <h3 className="mb-2 text-[15px] font-bold text-gray-900 dark:text-white leading-snug">
                    {t(step.title)}
                  </h3>

                  {/* Description */}
                  <p className="text-[13px] leading-relaxed text-gray-500 dark:text-gray-400">
                    {t(step.desc)}
                  </p>
                </div>
              </div>

              {/* ── Dashed Arrow Connector (between cards, not after last) ── */}
              {i < stepKeys.length - 1 && (
                <div className="hidden lg:flex items-center justify-center self-center">
                  <div className="flex items-center w-full px-1">
                    <div className="flex-1 h-0 border-t-[2px] border-dashed border-[#8b5cf6]/40" />
                    <svg width="7" height="10" viewBox="0 0 7 10" className="text-[#8b5cf6]/60 flex-shrink-0 -ml-px">
                      <path d="M0 0L7 5L0 10Z" fill="currentColor" />
                    </svg>
                  </div>
                </div>
              )}

            </Fragment>
          ))}

        </div>
      </div>
    </section>
  );
}
