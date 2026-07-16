'use client';

import type {LucideProps} from 'lucide-react';
import type {ForwardRefExoticComponent, RefAttributes} from 'react';
import {useLocale} from 'next-intl';
import {cn} from '@/lib/utils';
import {isRtlLocale} from '@/lib/rtl';

type LucideIcon = ForwardRefExoticComponent<
  Omit<LucideProps, 'ref'> & RefAttributes<SVGSVGElement>
>;

type DirectionalIconProps = LucideProps & {
  icon: LucideIcon;
  mirrorInRtl?: boolean;
};

export function DirectionalIcon({
  icon: Icon,
  className,
  mirrorInRtl = true,
  ...props
}: DirectionalIconProps) {
  const locale = useLocale();
  const shouldMirror = mirrorInRtl && isRtlLocale(locale);

  return (
    <Icon
      className={cn(shouldMirror && 'scale-x-[-1]', className)}
      aria-hidden="true"
      {...props}
    />
  );
}
