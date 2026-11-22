import { useTranslations } from "next-intl";
import { Fragment } from "react";
import { Briefcase, Upload, Globe, Activity } from "lucide-react";

const stepKeys = [
  { title: "step1Title", desc: "step1Desc", Icon: Briefcase },
  { title: "step2Title", desc: "step2Desc", Icon: Upload },
  { title: "step3Title", desc: "step3Desc", Icon: Globe },
  { title: "step4Title", desc: "step4Desc", Icon: Activity },
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
              <div className="relative flex flex-col h-full rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-7 sm:p-8 shadow-sm transition-all hover:shadow-xl dark:hover:shadow-[#8b5cf6]/5">

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
                    <step.Icon className="h-5 w-5" />
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
