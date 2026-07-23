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
        <div className="flex flex-col min-h-screen items-center justify-center p-6 relative overflow-hidden">
            {/* Header Actions */}
            <div className="absolute top-6 right-6 flex items-center gap-3 z-50">
                <ThemeToggle />
                <LanguageSwitcher />
            </div>

            {/* Ambient Background Effects */}
            <div className="absolute inset-0 pointer-events-none overflow-hidden z-0 flex items-center justify-center">
                <div className="absolute top-0 left-0 w-[40vw] h-[40vw] bg-primary/10 blur-[120px] rounded-full mix-blend-screen translate-x-[-20%] translate-y-[-20%]"></div>
                <div className="absolute bottom-0 right-0 w-[40vw] h-[40vw] bg-primary/20 blur-[120px] rounded-full mix-blend-screen translate-x-[20%] translate-y-[20%]"></div>
            </div>

            <main className="relative z-10 w-full max-w-[800px] mx-auto flex flex-col items-center text-center">

                {/* Header Branding */}
                <div className="mb-12 flex flex-col items-center gap-4">
                    <div className="w-12 h-12 bg-primary rounded-xl flex items-center justify-center shadow-[0_0_20px_rgba(124,58,237,0.4)]">
                        <Wallet className="text-primary-foreground h-6 w-6" />
                    </div>
                    <div className="flex flex-col gap-1">
                        <span className="font-heading text-2xl font-bold text-foreground tracking-tight">AFAB</span>
                        <span className="font-sans text-xs text-muted-foreground uppercase tracking-widest font-semibold">AI Finance Assistant</span>
                    </div>
                </div>

                {/* Message */}
                <div className="mb-8 space-y-4">
                    <h1 className="font-heading text-4xl md:text-5xl text-foreground font-extrabold leading-tight tracking-tight">
                        We're Under Maintenance
                    </h1>
                    <p className="font-sans text-muted-foreground text-lg max-w-xl mx-auto leading-relaxed">
                        We're performing scheduled maintenance to improve your experience and bring you smarter financial insights. We'll be back shortly!
                    </p>
                </div>

                {/* Status Card */}
                <div className="max-w-md w-full mx-auto mb-10">
                    <div className="bg-card/50 backdrop-blur-md border border-border p-6 rounded-2xl flex flex-col items-center gap-2 relative overflow-hidden shadow-sm">
                        <div className="absolute inset-0 bg-primary/5 pointer-events-none"></div>
                        <span className="font-sans text-xs text-primary uppercase tracking-widest font-bold mb-1">Estimated Time</span>
                        <div className="flex items-center gap-3">
                            <Activity className="text-primary h-6 w-6 animate-pulse" />
                            <span className="font-heading text-3xl text-foreground font-bold">30 – 60 Minutes</span>
                        </div>
                        <div className="w-full h-1.5 bg-muted rounded-full mt-5 overflow-hidden">
                            <div
                                className="h-full bg-primary rounded-full shadow-[0_0_8px_rgba(124,58,237,0.6)] transition-all duration-1000 ease-linear"
                                style={{ width: `${progress}%` }}
                            ></div>
                        </div>
                    </div>
                </div>

                {/* Actions Cluster */}
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12 w-full">
                    <button
                        onClick={() => window.location.reload()}
                        className="group relative flex items-center justify-center gap-2 bg-primary text-primary-foreground px-8 py-3.5 rounded-xl font-semibold hover:shadow-[0_0_20px_rgba(124,58,237,0.4)] active:scale-95 transition-all w-full sm:w-auto"
                    >
                        <RefreshCw className="h-5 w-5 group-hover:rotate-180 transition-transform duration-500" />
                        Refresh Page
                    </button>
                    <Link
                        href="/"
                        className="group flex items-center justify-center gap-2 bg-transparent text-foreground px-8 py-3.5 rounded-xl font-semibold border border-border hover:bg-muted active:scale-95 transition-all w-full sm:w-auto"
                    >
                        <Home className="h-5 w-5" />
                        Home Page
                    </Link>
                </div>

                {/* Footer Help */}
                <div className="flex flex-col items-center gap-2">
                    <div className="flex items-center gap-2 text-muted-foreground font-sans">
                        Need urgent help?
                        <a href="mailto:support@afab.ai" className="text-primary font-semibold hover:underline flex items-center gap-1 group">
                            Contact Support
                            <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform" />
                        </a>
                    </div>
                    <p className="font-sans text-xs text-muted-foreground uppercase mt-4 font-semibold tracking-widest">
                        System Status: <span className="text-amber-500">Partial Outage</span>
                    </p>
                </div>
            </main>
        </div>
    );
}
