import type {ReactNode} from 'react';
import {PageTransition} from '@/components/layout/page-transition';

type LocaleTemplateProps = {
  children: ReactNode;
};

export default function LocaleTemplate({children}: LocaleTemplateProps) {
  return <PageTransition>{children}</PageTransition>;
}
