"use client";

import { useTranslations, useLocale } from "next-intl";
import { useState } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { AlertCircle, CheckCircle2, ChevronRight, Download, Trash2, CalendarDays } from "lucide-react";
import {
  CURRENCIES,
  TIMEZONES,
  MONTHS,
  DATE_FORMATS,
  NUMBER_FORMATS,
  getLocalizedCurrencyOption,
} from "@/lib/constants/business-data";

export function GeneralSettings({ profile, business }: { profile: any, business: any }) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isArabic = locale === "ar";

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

  const getInitials = (firstName: string, lastName: string) => {
    return `${firstName?.[0] || ""}${lastName?.[0] || ""}`.toUpperCase();
  };

  const handleSave = async () => {
    setIsLoading(true);
    setError("");
    setSuccess(false);

    try {
      await SettingsService.updateBusiness(business.id, {
        name: formData.name,
        businessEmail: formData.businessEmail,
        currency: formData.currency,
        timezone: formData.timezone,
        fiscalYearStartMonth: parseInt(formData.fiscalYearStartMonth, 10),
        dateFormat: formData.dateFormat,
        numberFormat: formData.numberFormat,
      });

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

        {/* Business Settings Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden shadow-sm">
          <div className="p-6 border-b border-gray-200 dark:border-gray-600">
             <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{t("general.businessSettings")}</h3>
          </div>
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.businessName")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.businessEmail")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  type="email"
                  value={formData.businessEmail}
                  onChange={(e) => setFormData({ ...formData, businessEmail: e.target.value })}
                  placeholder="billing@example.com"
                />
              </div>

              {/* Currency Dropdown with Scroll */}
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.currency")}</Label>
                <Select
                  value={formData.currency}
                  onValueChange={(val) => setFormData({ ...formData, currency: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Currency" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {CURRENCIES.map((curr) => (
                      <SelectItem key={curr.code} value={curr.code}>
                        {getLocalizedCurrencyOption(curr, locale)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Timezone Dropdown with Scroll */}
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.timezone")}</Label>
                <Select
                  value={formData.timezone}
                  onValueChange={(val) => setFormData({ ...formData, timezone: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Timezone" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {TIMEZONES.map((tz) => (
                      <SelectItem key={tz.value} value={tz.value}>
                        {isArabic ? tz.labelAr : tz.labelEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Fiscal Year Start Dropdown with Scroll */}
              <div className="space-y-2 md:col-span-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.fiscalYearStart")}</Label>
                <Select
                  value={formData.fiscalYearStartMonth}
                  onValueChange={(val) => setFormData({ ...formData, fiscalYearStartMonth: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white w-full md:w-64">
                    <SelectValue placeholder="Select Month" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {MONTHS.map((m) => (
                      <SelectItem key={m.value} value={m.value.toString()}>
                        {m.value} - {isArabic ? m.nameAr : m.nameEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("general.fiscalYearHelper")}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Regional Formats Card: Date Format & Number Format Side-by-Side */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden shadow-sm">
          <div className="p-6 border-b border-gray-200 dark:border-gray-600 flex items-center gap-3">
             <div className="bg-[#8b5cf6]/10 p-2 rounded-lg text-[#8b5cf6]">
                <CalendarDays className="w-5 h-5" />
             </div>
             <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{t("general.regionalFormats")}</h3>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

              {/* Date Format Scrollable Select */}
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.dateFormat")}</Label>
                <Select
                  value={formData.dateFormat}
                  onValueChange={(val) => setFormData({ ...formData, dateFormat: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Date Format" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {DATE_FORMATS.map((df) => (
                      <SelectItem key={df.value} value={df.value}>
                        {isArabic ? df.labelAr : df.labelEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Number Format Scrollable Select */}
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.numberFormat")}</Label>
                <Select
                  value={formData.numberFormat}
                  onValueChange={(val) => setFormData({ ...formData, numberFormat: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Number Format" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {NUMBER_FORMATS.map((nf) => (
                      <SelectItem key={nf.value} value={nf.value}>
                        {isArabic ? nf.labelAr : nf.labelEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

            </div>
          </div>
        </div>

        <div className="flex justify-end gap-4 mt-8 pt-4">
          <Button variant="outline" className="min-w-[120px] border-gray-200 dark:border-gray-600">{t("general.cancel")}</Button>
          <Button
            onClick={handleSave}
            disabled={isLoading}
            className="bg-[#8b5cf6] hover:bg-[#7c3aed] text-white min-w-[140px]"
          >
            {isLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
          </Button>
        </div>
      </div>

      {/* Account & Preferences */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {/* Account Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden relative">
          <div className="h-24 bg-gradient-to-r from-[#8b5cf6]/20 to-[#8b5cf6]/5"></div>
          <div className="px-6 pb-6 text-center -mt-12 relative z-10">
            <Avatar className="w-24 h-24 mx-auto mb-4 border-4 border-white dark:border-gray-800 shadow-sm bg-white">
              <AvatarImage src={profile?.avatarUrl} />
              <AvatarFallback className="text-2xl bg-[#8b5cf6]/10 text-[#8b5cf6] font-bold">
                {getInitials(profile?.firstName, profile?.lastName)}
              </AvatarFallback>
            </Avatar>
            <h3 className="font-semibold text-gray-900 dark:text-white text-lg">
              {profile?.firstName} {profile?.lastName}
            </h3>
            <p className="text-gray-500 text-sm mb-6">{profile?.email}</p>
            <Button variant="outline" className="w-full border-gray-200 dark:border-gray-600">
              {t("account.editProfile")}
            </Button>
          </div>
        </div>

        {/* Preferences */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 p-6">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-6 text-lg">{t("preferences.title")}</h3>
          <div className="space-y-6">
            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.aiInsights")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("preferences.aiInsightsDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.enableAiInsights} 
                onCheckedChange={(c) => handlePrefChange('enableAiInsights', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.compactMode")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("preferences.compactModeDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.compactMode} 
                onCheckedChange={(c) => handlePrefChange('compactMode', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.autoCategorie")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("preferences.autoCategorieDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.autoCategorizeTransactions} 
                onCheckedChange={(c) => handlePrefChange('autoCategorizeTransactions', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.showTips")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("preferences.showTipsDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.showTips} 
                onCheckedChange={(c) => handlePrefChange('showTips', c)} 
              />
            </div>
          </div>
        </div>

        {/* Other Settings */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 p-6">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-4 text-lg">{t("otherSettings.title")}</h3>
          <div className="space-y-1">
             <div className="flex items-center justify-between group cursor-pointer p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 rounded-lg transition-colors -mx-3">
              <div className="flex items-center gap-3 text-gray-700 dark:text-gray-300">
                <Download className="w-5 h-5" />
                <p className="text-sm font-medium group-hover:text-[#8b5cf6] transition-colors">{t("otherSettings.exportData")}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-[#8b5cf6] transition-colors" />
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
