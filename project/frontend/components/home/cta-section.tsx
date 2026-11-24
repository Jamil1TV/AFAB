import { useTranslations } from "next-intl";
import { Play } from "lucide-react";

export function CTASection() {
  const t = useTranslations("Common.footer");

  return (
    <section className="py-8 lg:py-12">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="relative overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] px-6 py-8 shadow-sm sm:px-10 lg:px-12">

          <div className="relative z-10 flex flex-col items-center justify-between gap-8 lg:flex-row lg:gap-12">

            {/* Left — Icon + Text */}
            <div className="flex items-center gap-5 flex-1">
              {/* Official AFAB Logo */}
              <div className="flex-shrink-0 flex h-14 w-14 items-center justify-center rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden">
                <img src="/assets/afablogo.png" alt="AFAB Logo" className="h-10 w-10 object-contain dark:hidden" />
                <img src="/assets/afablogo_dark.png" alt="AFAB Logo Dark" className="h-10 w-10 object-contain hidden dark:block" />
              </div>

              <div>
                <h2 className="text-xl font-bold text-gray-900 dark:text-white sm:text-2xl">
                  {t("cta_title")}
                </h2>
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400 sm:text-base">
                  {t("cta_subtitle")}
                </p>
              </div>
            </div>

            {/* Right — Action Buttons */}
            <div className="flex flex-shrink-0 flex-wrap items-center justify-center gap-4 lg:justify-end">
              <button className="inline-flex items-center gap-2 rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-hover)] px-8 py-3.5 text-sm font-semibold text-white shadow-lg shadow-[var(--primary)]/25 transition-all hover:shadow-xl hover:-translate-y-0.5">
                {t("getStartedFree")}
              </button>
              <button className="inline-flex items-center gap-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-transparent px-8 py-3.5 text-sm font-semibold text-gray-900 dark:text-white transition-colors hover:bg-gray-50 dark:hover:bg-white/5">
                <Play className="h-4 w-4 fill-current" />
                {t("watchDemo")}
              </button>
            </div>

          </div>
        </div>
      </div>
    </section>
  );
}
