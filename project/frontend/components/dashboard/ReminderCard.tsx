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
      case "Subscription": return "bg-purple-50 text-purple-600 dark:bg-[#8b5cf6]/10 dark:text-[#a78bfa]";
      default: return "bg-gray-50 text-gray-600 dark:bg-gray-800 dark:text-gray-400";
    }
  };

  return (
    <div className="rounded-2xl border border-gray-200 dark:border-gray-800/60 bg-white dark:bg-[#0c101c] p-6 shadow-sm">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-sm font-bold text-gray-900 dark:text-white">{tReminders("title")}</h3>
        <button className="text-xs font-semibold text-[#8b5cf6] hover:text-[#7c3aed] transition-colors">
          {tReminders("viewAll")}
        </button>
      </div>

      <div className="space-y-4">
        {(reminders || []).map((reminder) => (
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
        ))}
      </div>
    </div>
  );
}
