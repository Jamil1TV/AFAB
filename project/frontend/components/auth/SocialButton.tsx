import { type ReactNode } from "react";

interface SocialButtonProps {
  icon: ReactNode;
  label: string;
  onClick?: () => void;
}

export function SocialButton({ icon, label, onClick }: SocialButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="group flex w-full items-center justify-center gap-3 rounded-xl border border-gray-200 dark:border-gray-700/60 bg-white dark:bg-[#0d1120] px-4 py-3 text-sm font-medium text-gray-700 dark:text-gray-300 transition-all duration-200 hover:bg-gray-50 dark:hover:bg-white/[0.04] hover:border-gray-300 dark:hover:border-gray-600 hover:shadow-sm focus:outline-none focus:ring-2 focus:ring-[#8b5cf6]/20 focus:ring-offset-1 dark:focus:ring-offset-[#131825]"
    >
      <span className="flex h-5 w-5 items-center justify-center transition-transform duration-200 group-hover:scale-110">
        {icon}
      </span>
      {label}
    </button>
  );
}
