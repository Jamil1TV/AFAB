import { redirect } from "next/navigation";

export default async function SettingsRedirect({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  // Automatically redirect /settings to /settings/general
  redirect(`/${locale}/dashboard/settings/general`);
}
