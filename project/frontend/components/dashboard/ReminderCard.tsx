"use client";

import { Clock, Calendar, FileText, Repeat } from "lucide-react";
import { useTranslations } from "next-intl";

export function ReminderCard({ reminders }: { reminders: any[] }) {
  const tReminders = useTranslations("Dashboard.reminders");

  const getIcon = (type: string) => {
    switch (type) {
      case "Tax": return <FileText className="h-4 w-4" />;
      case "Meeting": return <Calendar className="h-4 w-4" />;
      case "Subscription": return <Repeat className="h-4 w-4" />;
      default: return <Clock className="h-4 w-4" />;
    }
  };

  const getColor = (type: string) => {
    switch (type) {
      case "Tax": return "bg-orange-50 text-orange-600 dark:bg-orange-500/10 dark:text-orange-400";
      case "Meeting": return "bg-blue-50 text-blue-600 dark:bg-blue-500/10 dark:text-blue-400";
      case "Subscription": return "bg-purple-50 text-[var(--primary)] dark:bg-[var(--primary)]/10 dark:text-[var(--primary)]";
      default: return "bg-gray-50 text-gray-600 dark:bg-gray-800 dark:text-gray-400";
    }
  };

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tReminders("title")}</h3>
        <button className="text-xs font-semibold text-[var(--primary)] hover:text-[var(--primary-hover)] transition-colors">
          {tReminders("viewAll")}
        </button>
      </div>

      <div className="space-y-4">
        {(!reminders || reminders.length === 0) ? (
          <div className="py-8 flex flex-col items-center justify-center text-center">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-100 dark:bg-white/5 text-gray-400 mb-2.5">
              <Clock className="h-5 w-5" />
            </div>
            <p className="text-xs font-semibold text-gray-700 dark:text-gray-300">No upcoming reminders</p>
            <p className="text-[11px] text-gray-400 dark:text-gray-500 mt-0.5 max-w-xs">
              Scheduled tax deadlines and billing reminders will appear here.
            </p>
          </div>
        ) : (
          reminders.map((reminder) => (
            <div key={reminder.id} className="flex items-start gap-3 group">
              <div className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${getColor(reminder.type)}`}>
                {getIcon(reminder.type)}
              </div>
              <div className="flex-1 border-b border-gray-100 dark:border-gray-800/60 pb-3 group-last:border-0 group-last:pb-0">
                <p className="text-sm font-semibold text-gray-900 dark:text-white">
                  {reminder.title}
                </p>
                <div className="flex items-center gap-2 mt-1">
                  <Clock className="h-3 w-3 text-gray-400" />
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    {reminder.date}
                  </p>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
