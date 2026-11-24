"use client";

import { useSettings } from "@/components/settings/SettingsProvider";
import { SignatureSettings } from "@/components/settings/SignatureSettings";

export default function SignaturePage() {
  const { profile, business } = useSettings();

  return <SignatureSettings profile={profile} business={business} />;
}
