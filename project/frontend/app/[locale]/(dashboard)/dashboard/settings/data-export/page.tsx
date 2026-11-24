"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { DataExportSettings } from "@/components/settings/DataExportSettings";

export default function DataExportPage() {
  const { profile, business } = useSettings();

  return <DataExportSettings profile={profile} business={business} />;
}
