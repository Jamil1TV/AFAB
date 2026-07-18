"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { ChevronLeft, ChevronRight } from "lucide-react";

export function StatsTestimonialSection() {
  const tStats = useTranslations("Home.stats");
  const tTestimonial = useTranslations("Home.testimonial");
  const [current, setCurrent] = useState(0);

  const stats = [
    { value: tStats("activeUsersValue"), label: tStats("activeUsers") },
    { value: tStats("satisfactionRateValue"), label: tStats("satisfactionRate") },
    { value: tStats("appRatingValue"), label: tStats("appRating") },
  ];

  return (
    <section className="py-12 lg:py-16">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="grid gap-6 lg:grid-cols-5 lg:gap-8">

          {/* ═══════════════════════════════════════ */}
          {/* LEFT — Stats Card                      */}
          {/* ═══════════════════════════════════════ */}
          <div className="flex flex-col justify-center rounded-[20px] border border-gray-200/80 dark:border-gray-700/50 bg-white dark:bg-[#0d1225] p-8 lg:col-span-3 lg:p-10">
            <div className="flex flex-col gap-8 md:flex-row md:items-center md:justify-between">
              {/* Title */}
              <h2 className="max-w-[200px] text-xl font-bold leading-snug text-gray-900 dark:text-white">
                {tStats("trustedTitle")}
              </h2>

              {/* Stat Numbers */}
              <div className="flex flex-wrap gap-8 lg:gap-12">
                {stats.map((stat) => (
                  <div key={stat.label}>
                    <div className="text-4xl font-bold tracking-tight text-[#8b5cf6] lg:text-5xl">
                      {stat.value}
                    </div>
                    <div className="mt-2 text-sm font-medium text-gray-500 dark:text-gray-400">
                      {stat.label}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* ═══════════════════════════════════════ */}
          {/* RIGHT — Testimonial Card                */}
          {/* ═══════════════════════════════════════ */}
          <div className="flex flex-col justify-between rounded-[20px] border border-gray-200/80 dark:border-gray-700/50 bg-white dark:bg-[#0d1225] p-8 lg:col-span-2 lg:p-10">
            {/* Quote */}
            <div>
              {/* Purple Quote Icon */}
              <div className="mb-5">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" className="text-[#8b5cf6]">
                  <path d="M3 21c3 0 7-1 7-8V5c0-1.25-.756-2.017-2-2H4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2 1 0 1 0 1 1v1c0 1-1 2-2 2s-1 .008-1 1.031V20c0 1 0 1 1 1z" fill="currentColor" />
                  <path d="M15 21c3 0 7-1 7-8V5c0-1.25-.757-2.017-2-2h-4c-1.25 0-2 .75-2 1.972V11c0 1.25.75 2 2 2h.75c0 2.25.25 4-2.75 4v3c0 1 0 1 1 1z" fill="currentColor" />
                </svg>
              </div>

              <p className="text-sm leading-relaxed text-gray-600 dark:text-gray-300 sm:text-[15px]">
                {tTestimonial("quote")}
              </p>
            </div>

            {/* Author + Navigation */}
            <div className="mt-8 flex items-center justify-between">
              {/* Avatar & Info */}
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-200 dark:bg-gray-800 overflow-hidden">
                  <img
                    src="https://i.pravatar.cc/150?u=a042581f4e29026704d"
                    alt="User Avatar"
                    className="h-full w-full object-cover"
                  />
                </div>
                <div>
                  <div className="text-sm font-semibold text-gray-900 dark:text-white">
                    {tTestimonial("name")}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    {tTestimonial("role")}
                  </div>
                </div>
              </div>

              {/* Carousel Arrow Buttons */}
              <div className="flex items-center gap-2">
                <button
                  className="rounded-full border border-gray-200 dark:border-gray-700 bg-transparent p-2 transition-colors hover:bg-gray-50 dark:hover:bg-white/5"
                  onClick={() => setCurrent((c) => Math.max(0, c - 1))}
                >
                  <ChevronLeft className="h-4 w-4 text-gray-600 dark:text-white rtl:rotate-180" />
                </button>
                <button
                  className="rounded-full border border-gray-200 dark:border-gray-700 bg-transparent p-2 transition-colors hover:bg-gray-50 dark:hover:bg-white/5"
                  onClick={() => setCurrent((c) => Math.min(2, c + 1))}
                >
                  <ChevronRight className="h-4 w-4 text-gray-600 dark:text-white rtl:rotate-180" />
                </button>
              </div>
            </div>
          </div>

        </div>

        {/* Pagination Dots */}
        <div className="mt-6 flex justify-end gap-1.5 pe-4 lg:pe-12">
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              className={`h-2 rounded-full transition-all ${
                i === current ? "w-5 bg-[#8b5cf6]" : "w-2 bg-gray-300 dark:bg-gray-600"
              }`}
            />
          ))}
        </div>

      </div>
    </section>
  );
}
