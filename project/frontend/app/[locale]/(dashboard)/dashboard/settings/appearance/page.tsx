"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { AppearanceSettings } from "@/components/settings/AppearanceSettings";

export default function AppearanceSettingsPage() {
  const { profile, refreshSettings } = useSettings();

  return (
    <AppearanceSettings profile={profile} onRefresh={refreshSettings} />
  );
}
