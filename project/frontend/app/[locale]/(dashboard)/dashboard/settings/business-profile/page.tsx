"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { BusinessProfile } from "@/components/settings/BusinessProfile";

export default function BusinessProfilePage() {
  const { business } = useSettings();

  return <BusinessProfile business={business} />;
}
