import type {ReactNode} from 'react';
import {LayoutShell} from '@/components/layout/layout-shell';

type MarketingLayoutProps = {
  children: ReactNode;
};

export default function MarketingLayout({children}: MarketingLayoutProps) {
  return (
    <LayoutShell>
      <div className="mx-auto flex min-h-full w-full max-w-content flex-col">{children}</div>
    </LayoutShell>
  );
}
