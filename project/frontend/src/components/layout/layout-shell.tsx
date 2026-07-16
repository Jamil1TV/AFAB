import type {ReactNode} from 'react';

type LayoutShellProps = {
  children: ReactNode;
};

export function LayoutShell({children}: LayoutShellProps) {
  return (
    <div className="relative min-h-full overflow-hidden bg-background">
      <div
        className="pointer-events-none absolute inset-0 opacity-60"
        style={{
          background:
            'radial-gradient(65rem 32rem at 8% -10%, color-mix(in srgb, var(--secondary) 12%, transparent), transparent 58%), radial-gradient(55rem 28rem at 95% 8%, color-mix(in srgb, var(--accent) 10%, transparent), transparent 62%), linear-gradient(180deg, color-mix(in srgb, var(--surface) 70%, var(--background)), var(--background))'
        }}
        aria-hidden="true"
      />
      <div className="relative z-10 min-h-full">{children}</div>
    </div>
  );
}
