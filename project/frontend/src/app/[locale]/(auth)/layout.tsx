import type {ReactNode} from 'react';
import {LayoutShell} from '@/components/layout/layout-shell';

type AuthLayoutProps = {
  children: ReactNode;
};

export default function AuthLayout({children}: AuthLayoutProps) {
  return (
    <LayoutShell>
      <main className="mx-auto flex min-h-full w-full max-w-content flex-1 items-center justify-center px-4 py-10 sm:px-6 lg:px-8">
        {children}
      </main>
    </LayoutShell>
  );
}
