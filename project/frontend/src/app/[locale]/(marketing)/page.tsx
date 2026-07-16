'use client';

import {useTranslations} from 'next-intl';
import {ThemeToggle} from '@/components/shared/theme-toggle';

export default function LocalizedHomePage() {
  const t = useTranslations('marketing.landing');
  const themeT = useTranslations('theme');

  return (
    <main className="mx-auto flex min-h-full w-full max-w-6xl flex-1 flex-col justify-center px-4 py-16 sm:px-6 sm:py-20 lg:px-10">
      <section className="rounded-3xl border border-border bg-card p-8 shadow-[var(--shadow-soft)] sm:p-12">
        <div className="mb-6 flex items-start justify-between gap-4 sm:mb-8">
          <p className="text-inline-start inline-flex w-fit items-center rounded-full border border-secondary/20 bg-secondary/5 px-3 py-1 text-xs font-semibold uppercase tracking-[0.08em] text-secondary">
            {t('badge')}
          </p>
          <ThemeToggle
            labels={{
              light: themeT('light'),
              dark: themeT('dark'),
              system: themeT('system')
            }}
            ariaLabel={themeT('toggleAriaLabel')}
          />
        </div>
        <h1 className="text-inline-start max-w-3xl text-4xl font-semibold leading-tight text-foreground sm:text-5xl">
          {t('title')}
        </h1>
        <p className="text-inline-start mt-4 max-w-2xl text-base leading-7 text-muted-foreground sm:text-lg">
          {t('subtitle')}
        </p>
        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
          <button
            type="button"
            className="h-button-md w-full rounded-xl bg-primary px-5 text-sm font-semibold text-primary-foreground transition hover:opacity-90 sm:w-auto"
          >
            {t('primaryAction')}
          </button>
          <button
            type="button"
            className="h-button-md w-full rounded-xl border border-border bg-background px-5 text-sm font-semibold text-foreground transition hover:bg-muted sm:w-auto"
          >
            {t('secondaryAction')}
          </button>
        </div>
      </section>
    </main>
  );
}
