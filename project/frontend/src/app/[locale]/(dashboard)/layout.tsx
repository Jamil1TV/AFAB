import type {ReactNode} from 'react';

type DashboardLayoutProps = {
  children: ReactNode;
};

export default function DashboardLayout({children}: DashboardLayoutProps) {
  return (
    <div className="mx-auto flex min-h-full w-full max-w-dashboard flex-1 px-4 py-4 sm:px-6 sm:py-6 lg:px-8 lg:py-8">
      {children}
    </div>
  );
}
