"use client";

import { useEffect } from "react";
import { useRouter } from "@/i18n/routing";
import { AfabLoader } from "@/components/ui/afab-loader";

export default function PlansRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/dashboard/settings/subscription");
  }, [router]);

  return (
    <div className="flex items-center justify-center py-20">
      <AfabLoader size="md" />
    </div>
  );
}
