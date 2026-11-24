"use client";

import { Sidebar, SidebarProvider } from "@/components/dashboard/Sidebar";
import { DashboardHeader } from "@/components/dashboard/DashboardHeader";
import { LifecycleBanners } from "@/components/dashboard/LifecycleBanners";
import { CopilotContextProvider } from "@/components/ai/CopilotContextProvider";
import { GlobalCopilotDrawer } from "@/components/ai/GlobalCopilotDrawer";

function DashboardLayoutInner({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden bg-[var(--background)] text-gray-900 dark:text-white selection:bg-[var(--primary)]/30">
      <Sidebar />
      <div className="flex w-0 flex-1 flex-col h-screen overflow-hidden min-w-0">
        <DashboardHeader />
        <LifecycleBanners />
        <main className="flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar">
          {children}
        </main>
      </div>
      <GlobalCopilotDrawer />
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
      <CopilotContextProvider>
        <DashboardLayoutInner>{children}</DashboardLayoutInner>
      </CopilotContextProvider>
    </SidebarProvider>
  );
}
