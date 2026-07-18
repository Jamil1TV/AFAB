"use client";

import { useState } from "react";
import { useTranslations, useLocale } from "next-intl";
import { Link, useRouter, usePathname } from "@/i18n/routing";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { Menu, X, ChevronDown, Globe } from "lucide-react";
import Image from "next/image";

export function Navbar() {
  const t = useTranslations("Common.nav");
  const tLang = useTranslations("Common.language");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const toggleLanguage = () => {
    const nextLocale = locale === "en" ? "ar" : "en";
    router.replace(pathname, { locale: nextLocale });
  };

  const navLinks = [
    { label: t("features"), href: "#features" },
    { label: t("pricing"), href: "#pricing" },
    { label: t("howItWorks"), href: "#how-it-works" },
    { label: t("about"), href: "#about" },
  ];

  return (
    <nav className="fixed top-0 inset-x-0 z-50 border-b border-border/50 bg-background/80 backdrop-blur-xl">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-3">
            <div className="relative h-10 w-10 flex-shrink-0 overflow-hidden rounded-[10px] bg-white shadow-sm">
              <Image 
                src="/assets/logo.png" 
                alt="AFAB Logo" 
                fill
                sizes="40px"
                className="object-cover scale-[1.15]"
                priority
              />
            </div>
            <span className="text-[22px] font-bold tracking-tight text-gray-900 dark:text-white">AFAB</span>
          </Link>

          {/* Desktop Nav Links */}
          <div className="hidden items-center gap-1 lg:flex">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="rounded-full px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
              >
                {link.label}
              </a>
            ))}
            <button className="flex items-center gap-1 rounded-full px-4 py-2 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground">
              {t("resources")}
              <ChevronDown className="h-3.5 w-3.5" />
            </button>
          </div>

          {/* Desktop Actions */}
          <div className="hidden items-center gap-3 lg:flex">
            <ThemeToggle />
            <Button
              variant="ghost"
              size="sm"
              onClick={toggleLanguage}
              className="gap-1.5 text-sm rounded-full px-4"
            >
              <Globe className="h-4 w-4" />
              {tLang("switchTo")}
            </Button>
            <Button variant="outline" size="sm" className="rounded-full px-6 border-gray-700 bg-transparent hover:bg-white/5">
              {t("login")}
            </Button>
            <Button size="sm" className="rounded-full bg-[#8b5cf6] hover:bg-[#8b5cf6]/90 px-6 text-white font-medium border-0">
              {t("getStarted")}
            </Button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="rounded-md p-2 lg:hidden"
            onClick={() => setMobileOpen(!mobileOpen)}
            aria-label={t("menu")}
          >
            {mobileOpen ? (
              <X className="h-5 w-5" />
            ) : (
              <Menu className="h-5 w-5" />
            )}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileOpen && (
        <div className="absolute top-full left-0 right-0 border-b border-border bg-background shadow-xl lg:hidden max-h-[calc(100vh-4rem)] overflow-y-auto z-50">
          <div className="flex flex-col px-6 py-6">
            <div className="space-y-6">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="block text-[16px] font-semibold text-[#64748B] dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                  onClick={() => setMobileOpen(false)}
                >
                  {link.label}
                </a>
              ))}
              <a
                href="#resources"
                className="block text-[16px] font-semibold text-[#64748B] dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                onClick={() => setMobileOpen(false)}
              >
                {t("resources")}
              </a>
            </div>
            
            <div className="mt-8 border-t border-gray-100 dark:border-gray-800 pt-6">
              {/* Theme & Language */}
              <div className="flex items-center gap-6 mb-6">
                <div className="flex items-center justify-center rounded-xl border border-gray-200 dark:border-gray-800 w-10 h-10">
                  <ThemeToggle />
                </div>
                <button 
                  onClick={toggleLanguage} 
                  className="flex items-center gap-2 text-[15px] font-bold text-gray-800 dark:text-gray-200"
                >
                  <Globe className="h-4 w-4" />
                  {tLang("switchTo")}
                </button>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col gap-3">
                <Button 
                  variant="outline" 
                  className="w-full h-11 rounded-xl text-[15px] font-semibold border-gray-200 dark:border-gray-800 bg-transparent text-foreground hover:bg-gray-50 dark:hover:bg-gray-900"
                >
                  {t("login")}
                </Button>
                <Button 
                  className="w-full h-11 rounded-xl text-[15px] font-semibold bg-[#8b5cf6] hover:bg-[#7c3aed] text-white"
                >
                  {t("getStarted")}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}
