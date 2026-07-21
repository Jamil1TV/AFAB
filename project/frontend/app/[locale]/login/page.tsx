import type { Metadata } from "next";
import { HeroSection, LoginCard, MobileAuthHeader } from "@/components/auth";

export const metadata: Metadata = {
  title: "Log In — AFAB | AI Finance Assistant for Business",
  description:
    "Sign in to your AFAB account. Access AI-powered financial insights, track revenue, manage expenses, and grow your business smarter.",
};

export default function LoginPage() {
  return (
    <div className="flex min-h-screen">
      {/* ═══════════════════════════════════════════════════
         LEFT SIDE — Hero (hidden on mobile/tablet)
         ═══════════════════════════════════════════════════ */}
      <div className="hidden lg:flex lg:w-[55%] xl:w-[58%] relative">
        <HeroSection />
      </div>

      {/* ═══════════════════════════════════════════════════
         RIGHT SIDE — Login Card
         ═══════════════════════════════════════════════════ */}
      <div
        className="flex flex-1 flex-col items-center justify-center bg-background px-4 py-8 sm:px-8"
        style={{ zoom: 0.80 }}
      >
        {/* Mobile-only header with logo, theme toggle, and language switcher */}
        <MobileAuthHeader />

        <LoginCard />

        {/* Footer */}
        <p className="mt-8 text-center text-xs text-gray-400 dark:text-gray-500">
          © {new Date().getFullYear()} AFAB. All rights reserved.
        </p>
      </div>
    </div>
  );
}
