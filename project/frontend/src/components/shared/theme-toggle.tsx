'use client';

import * as React from 'react';
import {Monitor, Moon, Sun} from 'lucide-react';
import {useTheme} from 'next-themes';
import {Button} from '@/components/ui/button';

type ThemeMode = 'light' | 'dark' | 'system';

type ThemeToggleProps = {
  labels: {
    light: string;
    dark: string;
    system: string;
  };
  ariaLabel: string;
};

export function ThemeToggle({labels, ariaLabel}: ThemeToggleProps) {
  const {theme, setTheme} = useTheme();

  const modes = React.useMemo(
    () => [
      {key: 'light' as const, label: labels.light, icon: Sun},
      {key: 'dark' as const, label: labels.dark, icon: Moon},
      {key: 'system' as const, label: labels.system, icon: Monitor}
    ],
    [labels.dark, labels.light, labels.system]
  );

  return (
    <div
      className="inline-flex items-center gap-1 rounded-xl border border-border bg-card p-1 shadow-xs"
      role="group"
      aria-label={ariaLabel}
    >
      {modes.map((mode) => {
        const Icon = mode.icon;
        const isActive = (theme ?? 'system') === mode.key;

        return (
          <Button
            key={mode.key}
            type="button"
            size="sm"
            variant={isActive ? 'default' : 'ghost'}
            className="h-button-sm px-2.5"
            aria-pressed={isActive}
            onClick={() => setTheme(mode.key as ThemeMode)}
          >
            <Icon className="size-4" aria-hidden="true" />
            <span className="sr-only">{mode.label}</span>
          </Button>
        );
      })}
    </div>
  );
}
