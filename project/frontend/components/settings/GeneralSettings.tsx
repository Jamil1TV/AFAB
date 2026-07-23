"use client";

import { useTranslations } from "next-intl";
import { useState, useEffect } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { AlertCircle, LogOut, CheckCircle2, ChevronRight, Download, Trash2, CalendarDays, DollarSign } from "lucide-react";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { cn } from "@/lib/utils";

export function GeneralSettings({ profile, business }: { profile: any, business: any }) {
  const t = useTranslations("settings");
  
  const [formData, setFormData] = useState({
    name: business?.name || "",
    businessEmail: business?.businessEmail || "",
    currency: business?.currency || "USD",
    timezone: business?.timezone || "UTC",
    fiscalYearStartMonth: business?.fiscalYearStartMonth?.toString() || "1",
    dateFormat: business?.dateFormat || "MM/DD/YYYY",
    numberFormat: business?.numberFormat || "US",
  });

  const [userPrefs, setUserPrefs] = useState({
    enableAiInsights: profile?.enableAiInsights ?? true,
    compactMode: profile?.compactMode ?? false,
    autoCategorizeTransactions: profile?.autoCategorizeTransactions ?? true,
    showTips: profile?.showTips ?? true,
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  // Helper to extract initials
  const getInitials = (firstName: string, lastName: string) => {
    return `${firstName?.[0] || ""}${lastName?.[0] || ""}`.toUpperCase();
  };

  const handleSave = async () => {
    setIsLoading(true);
    setError("");
    setSuccess(false);

    try {
      // 1. Update Business Settings
      await SettingsService.updateBusiness(business.id, {
        name: formData.name,
        businessEmail: formData.businessEmail,
        currency: formData.currency,
        timezone: formData.timezone,
        fiscalYearStartMonth: parseInt(formData.fiscalYearStartMonth, 10),
        dateFormat: formData.dateFormat,
        numberFormat: formData.numberFormat,
      });

      // 2. Update User Preferences
      await SettingsService.updateProfile({
        enableAiInsights: userPrefs.enableAiInsights,
        compactMode: userPrefs.compactMode,
        autoCategorizeTransactions: userPrefs.autoCategorizeTransactions,
        showTips: userPrefs.showTips,
      });

      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || "Failed to update settings");
    } finally {
      setIsLoading(false);
    }
  };

  const handlePrefChange = (key: keyof typeof userPrefs, checked: boolean) => {
    setUserPrefs(prev => ({ ...prev, [key]: checked }));
  };

  return (
    <div className="space-y-8 pb-10">
      {/* Left Form Content */}
      <div className="space-y-8">
        <div>
          <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-1">
            {t("general.title")}
          </h2>
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            {t("general.subtitle")}
          </p>
        </div>

        {error && (
          <div className="p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-lg flex items-start gap-3 text-sm">
            <AlertCircle className="w-5 h-5 shrink-0" />
            <p>{error}</p>
          </div>
        )}
        {success && (
          <div className="p-4 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 rounded-lg flex items-start gap-3 text-sm">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <p>{t("saved")}</p>
          </div>
        )}

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-700">
             <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Business Settings</h3>
          </div>
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label>{t("general.businessName")}</Label>
                <Input
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label>{t("general.businessEmail")}</Label>
                <Input
                  type="email"
                  value={formData.businessEmail}
                  onChange={(e) => setFormData({ ...formData, businessEmail: e.target.value })}
                  placeholder="billing@example.com"
                />
              </div>

              <div className="space-y-2">
                <Label>{t("general.currency")}</Label>
                <Select
                  value={formData.currency}
                  onValueChange={(val) => setFormData({ ...formData, currency: val })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select Currency" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="USD">USD - US Dollar</SelectItem>
                    <SelectItem value="EUR">EUR - Euro</SelectItem>
                    <SelectItem value="GBP">GBP - British Pound</SelectItem>
                    <SelectItem value="DZD">DZD - Algerian Dinar</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>{t("general.timezone")}</Label>
                <Select
                  value={formData.timezone}
                  onValueChange={(val) => setFormData({ ...formData, timezone: val })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select Timezone" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="UTC">UTC (Universal Time Coordinated)</SelectItem>
                    <SelectItem value="America/New_York">EST / EDT (New York)</SelectItem>
                    <SelectItem value="Europe/London">GMT / BST (London)</SelectItem>
                    <SelectItem value="Africa/Algiers">CET (Algiers)</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2 md:col-span-2">
                <Label>{t("general.fiscalYearStart")}</Label>
                <Select
                  value={formData.fiscalYearStartMonth}
                  onValueChange={(val) => setFormData({ ...formData, fiscalYearStartMonth: val })}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select Month" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="1">January</SelectItem>
                    <SelectItem value="4">April</SelectItem>
                    <SelectItem value="7">July</SelectItem>
                    <SelectItem value="10">October</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-xs text-gray-500 mt-1">{t("general.fiscalYearHelper")}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex items-center gap-3">
             <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <CalendarDays className="w-5 h-5" />
             </div>
             <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Date Format</h3>
          </div>
          <div className="p-6">
             <RadioGroup 
                value={formData.dateFormat} 
                onValueChange={(val) => setFormData({ ...formData, dateFormat: val })}
                className="grid grid-cols-1 md:grid-cols-3 gap-4"
             >
                <div className={cn(
                  "flex items-center space-x-2 border rounded-lg p-4 cursor-pointer transition-all",
                  formData.dateFormat === "MM/DD/YYYY" ? "border-primary bg-primary/5 ring-1 ring-primary/20" : "border-gray-200 dark:border-gray-700 hover:border-gray-300"
                )} onClick={() => setFormData({ ...formData, dateFormat: "MM/DD/YYYY" })}>
                  <RadioGroupItem value="MM/DD/YYYY" id="date-1" />
                  <Label htmlFor="date-1" className="flex-1 cursor-pointer font-medium">MM/DD/YYYY<br/><span className="text-gray-500 font-normal text-xs mt-1 block">12/31/2026</span></Label>
                </div>
                <div className={cn(
                  "flex items-center space-x-2 border rounded-lg p-4 cursor-pointer transition-all",
                  formData.dateFormat === "DD/MM/YYYY" ? "border-primary bg-primary/5 ring-1 ring-primary/20" : "border-gray-200 dark:border-gray-700 hover:border-gray-300"
                )} onClick={() => setFormData({ ...formData, dateFormat: "DD/MM/YYYY" })}>
                  <RadioGroupItem value="DD/MM/YYYY" id="date-2" />
                  <Label htmlFor="date-2" className="flex-1 cursor-pointer font-medium">DD/MM/YYYY<br/><span className="text-gray-500 font-normal text-xs mt-1 block">31/12/2026</span></Label>
                </div>
                <div className={cn(
                  "flex items-center space-x-2 border rounded-lg p-4 cursor-pointer transition-all",
                  formData.dateFormat === "YYYY-MM-DD" ? "border-primary bg-primary/5 ring-1 ring-primary/20" : "border-gray-200 dark:border-gray-700 hover:border-gray-300"
                )} onClick={() => setFormData({ ...formData, dateFormat: "YYYY-MM-DD" })}>
                  <RadioGroupItem value="YYYY-MM-DD" id="date-3" />
                  <Label htmlFor="date-3" className="flex-1 cursor-pointer font-medium">YYYY-MM-DD<br/><span className="text-gray-500 font-normal text-xs mt-1 block">2026-12-31</span></Label>
                </div>
             </RadioGroup>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex items-center gap-3">
             <div className="bg-primary/10 p-2 rounded-lg text-primary">
                <DollarSign className="w-5 h-5" />
             </div>
             <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Number Format</h3>
          </div>
          <div className="p-6">
             <RadioGroup 
                value={formData.numberFormat} 
                onValueChange={(val) => setFormData({ ...formData, numberFormat: val })}
                className="grid grid-cols-1 md:grid-cols-2 gap-4"
             >
                <div className={cn(
                  "flex items-center space-x-2 border rounded-lg p-4 cursor-pointer transition-all",
                  formData.numberFormat === "US" ? "border-primary bg-primary/5 ring-1 ring-primary/20" : "border-gray-200 dark:border-gray-700 hover:border-gray-300"
                )} onClick={() => setFormData({ ...formData, numberFormat: "US" })}>
                  <RadioGroupItem value="US" id="num-1" />
                  <Label htmlFor="num-1" className="flex-1 cursor-pointer font-medium">1,234,567.89<br/><span className="text-gray-500 font-normal text-xs mt-1 block">US Standard (Comma separator, dot decimal)</span></Label>
                </div>
                <div className={cn(
                  "flex items-center space-x-2 border rounded-lg p-4 cursor-pointer transition-all",
                  formData.numberFormat === "EU" ? "border-primary bg-primary/5 ring-1 ring-primary/20" : "border-gray-200 dark:border-gray-700 hover:border-gray-300"
                )} onClick={() => setFormData({ ...formData, numberFormat: "EU" })}>
                  <RadioGroupItem value="EU" id="num-2" />
                  <Label htmlFor="num-2" className="flex-1 cursor-pointer font-medium">1.234.567,89<br/><span className="text-gray-500 font-normal text-xs mt-1 block">EU Standard (Dot separator, comma decimal)</span></Label>
                </div>
             </RadioGroup>
          </div>
        </div>

        <div className="flex justify-end gap-4 mt-8 pt-4">
          <Button variant="outline" className="min-w-[120px]">Cancel</Button>
          <Button
            onClick={handleSave}
            disabled={isLoading}
            className="bg-primary hover:bg-primary/90 text-white min-w-[140px]"
          >
            {isLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
          </Button>
        </div>
      </div>

      {/* Account & Preferences */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {/* Account Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden relative">
          <div className="h-24 bg-gradient-to-r from-primary/20 to-primary/5"></div>
          <div className="px-6 pb-6 text-center -mt-12 relative z-10">
            <Avatar className="w-24 h-24 mx-auto mb-4 border-4 border-white dark:border-gray-800 shadow-sm bg-white">
              <AvatarImage src={profile?.avatarUrl} />
              <AvatarFallback className="text-2xl bg-primary/10 text-primary font-bold">
                {getInitials(profile?.firstName, profile?.lastName)}
              </AvatarFallback>
            </Avatar>
            <h3 className="font-semibold text-gray-900 dark:text-white text-lg">
              {profile?.firstName} {profile?.lastName}
            </h3>
            <p className="text-gray-500 text-sm mb-6">{profile?.email}</p>
            <Button variant="outline" className="w-full">
              {t("account.editProfile")}
            </Button>
          </div>
        </div>

        {/* Preferences */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-6 text-lg">{t("preferences.title")}</h3>
          <div className="space-y-6">
            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">Enable AI Insights</p>
                <p className="text-xs text-gray-500 mt-1">Get smart suggestions for categorization and cash flow.</p>
              </div>
              <Switch 
                checked={userPrefs.enableAiInsights} 
                onCheckedChange={(c) => handlePrefChange('enableAiInsights', c)} 
              />
            </div>
            
            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">Compact Mode</p>
                <p className="text-xs text-gray-500 mt-1">Decrease padding in tables to fit more information.</p>
              </div>
              <Switch 
                checked={userPrefs.compactMode} 
                onCheckedChange={(c) => handlePrefChange('compactMode', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">Auto-categorize</p>
                <p className="text-xs text-gray-500 mt-1">Automatically categorize recurring transactions.</p>
              </div>
              <Switch 
                checked={userPrefs.autoCategorizeTransactions} 
                onCheckedChange={(c) => handlePrefChange('autoCategorizeTransactions', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">Show Tips & Tutorials</p>
                <p className="text-xs text-gray-500 mt-1">Show helpful tooltips when navigating new features.</p>
              </div>
              <Switch 
                checked={userPrefs.showTips} 
                onCheckedChange={(c) => handlePrefChange('showTips', c)} 
              />
            </div>
          </div>
        </div>

        {/* Other Settings */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4 text-lg">{t("otherSettings.title")}</h3>
          <div className="space-y-1">
             <div className="flex items-center justify-between group cursor-pointer p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 rounded-lg transition-colors -mx-3">
              <div className="flex items-center gap-3 text-gray-700 dark:text-gray-300">
                <Download className="w-5 h-5" />
                <p className="text-sm font-medium group-hover:text-primary transition-colors">{t("otherSettings.exportData")}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-primary transition-colors" />
            </div>
            <div className="flex items-center justify-between group cursor-pointer p-3 hover:bg-red-50 dark:hover:bg-red-900/10 rounded-lg transition-colors -mx-3">
              <div className="flex items-center gap-3 text-red-600 dark:text-red-400">
                <Trash2 className="w-5 h-5" />
                <p className="text-sm font-medium">{t("otherSettings.deleteAccount")}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-red-400 opacity-0 group-hover:opacity-100 transition-opacity" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
