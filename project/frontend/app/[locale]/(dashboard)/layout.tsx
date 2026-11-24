"use client";

import { Sidebar, SidebarProvider, useSidebar } from "@/components/dashboard/Sidebar";
import { DashboardHeader } from "@/components/dashboard/DashboardHeader";
import { LifecycleBanners } from "@/components/dashboard/LifecycleBanners";

function DashboardLayoutInner({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden bg-gray-50/50 dark:bg-[#060813] text-gray-900 dark:text-white selection:bg-[var(--primary)]/30">
      <Sidebar />
      <div className="flex w-0 flex-1 flex-col h-screen overflow-hidden min-w-0">
        <DashboardHeader />
        <LifecycleBanners />
        <main className="flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar">
          {children}
        </main>
      </div>
    </div>
  );
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      <DashboardLayoutInner>{children}</DashboardLayoutInner>
    </SidebarProvider>
  );
}
