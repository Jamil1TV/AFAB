"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { GeneralSettings } from "@/components/settings/GeneralSettings";

export default function GeneralSettingsPage() {
  const { profile, business, refreshSettings } = useSettings();

  return <GeneralSettings profile={profile} business={business} onRefresh={refreshSettings} />;
}
