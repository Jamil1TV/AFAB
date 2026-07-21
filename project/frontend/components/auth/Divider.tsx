interface DividerProps {
  text: string;
}

export function Divider({ text }: DividerProps) {
  return (
    <div className="relative my-6">
      <div className="absolute inset-0 flex items-center">
        <div className="w-full border-t border-gray-200 dark:border-gray-700/60" />
      </div>
      <div className="relative flex justify-center">
        <span className="bg-white dark:bg-[#131825] px-4 text-xs font-medium text-gray-400 dark:text-gray-500">
          {text}
        </span>
      </div>
    </div>
  );
}
