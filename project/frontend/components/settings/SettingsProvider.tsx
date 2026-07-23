"use client";

import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { SettingsService } from "@/lib/api/settings";
import { AfabLoader } from "@/components/ui/afab-loader";

interface SettingsContextType {
  profile: any;
  business: any;
  refreshSettings: () => Promise<void>;
}

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<any>(null);
  const [business, setBusiness] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshSettings = async () => {
    try {
      const [profileData, businessData] = await Promise.all([
        SettingsService.getProfile(),
        SettingsService.getMyBusiness()
      ]);
      setProfile(profileData);
      setBusiness(businessData);
    } catch (err) {
      console.error("Failed to load settings data", err);
    }
  };

  useEffect(() => {
    refreshSettings().finally(() => setIsLoading(false));
  }, []);

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center min-h-screen">
        <AfabLoader size="lg" />
      </div>
    );
  }

  return (
    <SettingsContext.Provider value={{ profile, business, refreshSettings }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const context = useContext(SettingsContext);
  if (context === undefined) {
    throw new Error("useSettings must be used within a SettingsProvider");
  }
  return context;
}
