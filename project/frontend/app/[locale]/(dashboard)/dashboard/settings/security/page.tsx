"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { SecuritySettings } from "@/components/settings/SecuritySettings";

export default function SecuritySettingsPage() {
  const { profile } = useSettings();

  return <SecuritySettings profile={profile} />;
}
