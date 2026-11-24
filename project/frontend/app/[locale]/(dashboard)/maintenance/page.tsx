'use client';

import { RefreshCw, Activity, ArrowRight, Wallet, Home } from 'lucide-react';
import { useState, useEffect } from 'react';
import { Link } from '@/i18n/routing';
import { ThemeToggle } from '@/components/theme-toggle';
import { LanguageSwitcher } from '@/components/language-switcher';

export default function MaintenancePage() {
    const [progress, setProgress] = useState(65);

    useEffect(() => {
        const timer = setInterval(() => {
            setProgress((prev) => {
                if (prev < 98) {
                    return prev + 0.05;
                }
                return prev;
            });
        }, 1000);
        return () => clearInterval(timer);
    }, []);

    return (
        <div className="flex flex-col min-h-screen items-center justify-center p-6 relative overflow-hidden bg-[#f8f9fb] dark:bg-[#060813]">
            {/* Header Actions */}
            <div className="absolute top-6 end-6 flex items-center gap-3 z-50">
                <ThemeToggle />
                <LanguageSwitcher />
            </div>

            {/* Ambient Background Effects */}
            <div className="absolute inset-0 pointer-events-none overflow-hidden z-0 flex items-center justify-center">
                <div className="absolute top-0 left-0 w-[40vw] h-[40vw] bg-[var(--primary)]/5 dark:bg-[var(--primary)]/10 blur-[120px] rounded-full translate-x-[-20%] translate-y-[-20%]"></div>
                <div className="absolute bottom-0 right-0 w-[40vw] h-[40vw] bg-[var(--primary)]/10 dark:bg-[var(--primary)]/15 blur-[120px] rounded-full translate-x-[20%] translate-y-[20%]"></div>
            </div>

            <main className="relative z-10 w-full max-w-[800px] mx-auto flex flex-col items-center text-center">

                {/* Header Branding */}
                <div className="mb-12 flex flex-col items-center gap-4">
                    <div className="flex h-14 w-14 items-center justify-center rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] shadow-sm overflow-hidden">
                        <img src="/assets/afablogo.png" alt="AFAB Logo" className="h-10 w-10 object-contain dark:hidden" />
                        <img src="/assets/afablogo_dark.png" alt="AFAB Logo Dark" className="h-10 w-10 object-contain hidden dark:block" />
                    </div>
                    <div className="flex flex-col gap-1">
                        <span className="font-heading text-2xl font-bold text-gray-900 dark:text-white tracking-tight">AFAB</span>
                        <span className="font-sans text-xs text-gray-500 dark:text-gray-400 uppercase tracking-widest font-semibold">AI Finance Assistant</span>
                    </div>
                </div>

                {/* Message */}
                <div className="mb-8 space-y-4">
                    <h1 className="font-heading text-3xl sm:text-4xl md:text-5xl text-gray-900 dark:text-white font-bold leading-tight tracking-tight">
                        We're Under Maintenance
                    </h1>
                    <p className="font-sans text-gray-500 dark:text-gray-400 text-base sm:text-lg max-w-xl mx-auto leading-relaxed">
                        We're performing scheduled maintenance to improve your experience and bring you smarter financial insights. We'll be back shortly!
                    </p>
                </div>

                {/* Status Card */}
                <div className="max-w-md w-full mx-auto mb-10">
                    <div className="afab-card p-6 flex flex-col items-center gap-2 relative overflow-hidden">
                        <span className="font-sans text-xs text-[var(--primary)] uppercase tracking-widest font-bold mb-1">Estimated Time</span>
                        <div className="flex items-center gap-3">
                            <Activity className="text-[var(--primary)] h-6 w-6 animate-pulse" />
                            <span className="font-heading text-2xl sm:text-3xl text-gray-900 dark:text-white font-bold">30 – 60 Minutes</span>
                        </div>
                        <div className="w-full h-1.5 bg-gray-100 dark:bg-[#080c18] rounded-full mt-5 overflow-hidden">
                            <div
                                className="h-full bg-[var(--primary)] rounded-full transition-all duration-1000 ease-linear"
                                style={{ width: `${progress}%` }}
                            ></div>
                        </div>
                    </div>
                </div>

                {/* Actions Cluster */}
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12 w-full">
                    <button
                        onClick={() => window.location.reload()}
                        className="afab-btn-primary group relative px-8 py-3.5 text-sm w-full sm:w-auto"
                    >
                        <RefreshCw className="h-4 w-4 group-hover:rotate-180 transition-transform duration-500" />
                        Refresh Page
                    </button>
                    <Link
                        href="/"
                        className="afab-btn-secondary group px-8 py-3.5 text-sm w-full sm:w-auto"
                    >
                        <Home className="h-4 w-4" />
                        Home Page
                    </Link>
                </div>

                {/* Footer Help */}
                <div className="flex flex-col items-center gap-2">
                    <div className="flex flex-wrap items-center justify-center gap-2 text-sm text-gray-500 dark:text-gray-400 font-sans">
                        Need urgent help?
                        <a href="mailto:support@afab.ai" className="text-[var(--primary)] font-semibold hover:underline flex items-center gap-1 group">
                            Contact Support
                            <ArrowRight className="h-4 w-4 group-hover:translate-x-1 rtl:rotate-180 rtl:group-hover:-translate-x-1 transition-transform" />
                        </a>
                    </div>
                    <p className="font-sans text-xs text-gray-500 dark:text-gray-400 uppercase mt-4 font-semibold tracking-widest">
                        System Status: <span className="text-amber-600 dark:text-amber-400">Partial Outage</span>
                    </p>
                </div>
            </main>
        </div>
    );
}
