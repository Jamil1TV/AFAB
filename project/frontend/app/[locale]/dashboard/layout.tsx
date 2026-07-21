import { Sidebar } from "@/components/dashboard/Sidebar";
import { DashboardHeader } from "@/components/dashboard/DashboardHeader";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen bg-gray-50/50 dark:bg-[#060813] text-gray-900 dark:text-white selection:bg-[#8b5cf6]/30">
      <Sidebar />
      <div className="flex w-0 flex-1 flex-col overflow-hidden">
        <DashboardHeader />
        <main className="flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar pb-16">
          {children}
        </main>
      </div>
    </div>
  );
}
