"use client";

import { useEffect } from "react";
import { useRouter } from "@/i18n/routing";
import { Loader2 } from "lucide-react";

export default function UpgradeRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/dashboard/settings/subscription");
  }, [router]);

  return (
    <div className="flex items-center justify-center py-20">
      <Loader2 className="h-6 w-6 animate-spin text-[#7c3aed]" />
    </div>
  );
}
