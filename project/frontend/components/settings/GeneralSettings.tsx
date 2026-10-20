"use client";

import { useTranslations, useLocale } from "next-intl";
import { useState, useMemo, useEffect } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { 
  AlertCircle, 
  CheckCircle2, 
  ChevronRight, 
  Download, 
  Trash2, 
  CalendarDays,
  Calendar,
  Sparkles,
  RotateCcw,
  Check
} from "lucide-react";
import {
  CURRENCIES,
  TIMEZONES,
  MONTHS,
  DATE_FORMATS,
  NUMBER_FORMATS,
  getLocalizedCurrencyOption,
  getLocalizedTimezone,
  getLocalizedDateFormat,
  getLocalizedNumberFormat,
} from "@/lib/constants/business-data";
import { formatCurrency } from "@/lib/currency";
import { CurrencyMigrationModal } from "./CurrencyMigrationModal";

export function GeneralSettings({ profile, business }: { profile: any; business: any }) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isArabic = locale === "ar";

  // Initial pristine values derived from server props
  const initialFormData = useMemo(() => ({
    name: business?.name || "",
    businessEmail: business?.businessEmail || "",
    currency: business?.currency || "USD",
    timezone: business?.timezone || "UTC",
    fiscalYearStartMonth: business?.fiscalYearStartMonth?.toString() || "1",
    dateFormat: business?.dateFormat || "MM/DD/YYYY",
    numberFormat: business?.numberFormat || "US",
  }), [business]);

  const initialUserPrefs = useMemo(() => ({
    enableAiInsights: profile?.enableAiInsights ?? true,
    compactMode: profile?.compactMode ?? false,
    autoCategorizeTransactions: profile?.autoCategorizeTransactions ?? true,
    showTips: profile?.showTips ?? true,
  }), [profile]);

  // Baseline states used for dirty checking & resetting on Cancel
  const [baselineFormData, setBaselineFormData] = useState(initialFormData);
  const [baselineUserPrefs, setBaselineUserPrefs] = useState(initialUserPrefs);

  // Active editable form state
  const [formData, setFormData] = useState(initialFormData);
  const [userPrefs, setUserPrefs] = useState(initialUserPrefs);

  // Sync baseline when props change from server
  useEffect(() => {
    setBaselineFormData(initialFormData);
    setFormData(initialFormData);
  }, [initialFormData]);

  useEffect(() => {
    setBaselineUserPrefs(initialUserPrefs);
    setUserPrefs(initialUserPrefs);
  }, [initialUserPrefs]);

  // Compute dirty state
  const isDirty = useMemo(() => {
    const formDirty =
      formData.name !== baselineFormData.name ||
      formData.businessEmail !== baselineFormData.businessEmail ||
      formData.currency !== baselineFormData.currency ||
      formData.timezone !== baselineFormData.timezone ||
      formData.fiscalYearStartMonth !== baselineFormData.fiscalYearStartMonth ||
      formData.dateFormat !== baselineFormData.dateFormat ||
      formData.numberFormat !== baselineFormData.numberFormat;

    const prefsDirty =
      userPrefs.enableAiInsights !== baselineUserPrefs.enableAiInsights ||
      userPrefs.compactMode !== baselineUserPrefs.compactMode ||
      userPrefs.autoCategorizeTransactions !== baselineUserPrefs.autoCategorizeTransactions ||
      userPrefs.showTips !== baselineUserPrefs.showTips;

    return formDirty || prefsDirty;
  }, [formData, baselineFormData, userPrefs, baselineUserPrefs]);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [isMigrationModalOpen, setIsMigrationModalOpen] = useState(false);
  const [pendingCurrency, setPendingCurrency] = useState<string | null>(null);
  const [migrationSuccessMsg, setMigrationSuccessMsg] = useState<string | null>(null);

  const handleMigrationSuccess = (newCurr: string, count: number) => {
    setFormData((prev) => ({ ...prev, currency: newCurr }));
    setBaselineFormData((prev) => ({ ...prev, currency: newCurr }));
    setMigrationSuccessMsg(
      locale === "ar"
        ? `تم تحديث العملة الأساسية بنجاح إلى ${newCurr} وتحويل ${count} معاملة بسعر الصرف المباشر!`
        : `Successfully updated base currency to ${newCurr} and converted ${count} transactions at live market rate!`
    );
    setTimeout(() => setMigrationSuccessMsg(null), 6000);
  };

  const getInitials = (firstName: string, lastName: string) => {
    return `${firstName?.[0] || ""}${lastName?.[0] || ""}`.toUpperCase();
  };

  const handleCancel = () => {
    setFormData(baselineFormData);
    setUserPrefs(baselineUserPrefs);
    setError("");
  };

  const handleSave = async () => {
    if (!isDirty) return;

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

      // Update baseline to newly saved values
      setBaselineFormData(formData);
      setBaselineUserPrefs(userPrefs);

      // Persist regional formatting preferences to client storage
      if (typeof window !== "undefined") {
        localStorage.setItem("afab_number_format", formData.numberFormat);
        localStorage.setItem("afab_date_format", formData.dateFormat);
        window.dispatchEvent(new Event("afab_format_change"));
      }

      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || "Failed to update settings");
    } finally {
      setIsLoading(false);
    }
  };

  const handlePrefChange = (key: keyof typeof userPrefs, checked: boolean) => {
    setUserPrefs((prev) => ({ ...prev, [key]: checked }));
  };

  // Fiscal year calculations & quarter breakdown
  const fiscalYearDetails = useMemo(() => {
    const startNum = parseInt(formData.fiscalYearStartMonth, 10) || 1;
    const startM = MONTHS.find((m) => m.value === startNum) || MONTHS[0];
    const endNum = startNum === 1 ? 12 : startNum - 1;
    const endM = MONTHS.find((m) => m.value === endNum) || MONTHS[11];

    const getMName = (v: number) => {
      const obj = MONTHS.find((m) => m.value === v);
      return isArabic ? obj?.nameAr : obj?.nameEn;
    };

    const q1Start = startNum;
    const q2Start = ((startNum + 2) % 12) + 1;
    const q3Start = ((startNum + 5) % 12) + 1;
    const q4Start = ((startNum + 8) % 12) + 1;

    const endDay = endNum === 2 ? "28" : [4, 6, 9, 11].includes(endNum) ? "30" : "31";

    return {
      startMonthName: isArabic ? startM.nameAr : startM.nameEn,
      endMonthName: isArabic ? endM.nameAr : endM.nameEn,
      endDay,
      quarters: [
        { name: isArabic ? "الربع الأول (Q1)" : "Quarter 1 (Q1)", range: `${getMName(q1Start)} - ${getMName(((q1Start + 1) % 12) + 1)}` },
        { name: isArabic ? "الربع الثاني (Q2)" : "Quarter 2 (Q2)", range: `${getMName(q2Start)} - ${getMName(((q2Start + 1) % 12) + 1)}` },
        { name: isArabic ? "الربع الثالث (Q3)" : "Quarter 3 (Q3)", range: `${getMName(q3Start)} - ${getMName(((q3Start + 1) % 12) + 1)}` },
        { name: isArabic ? "الربع الرابع (Q4)" : "Quarter 4 (Q4)", range: `${getMName(q4Start)} - ${getMName(((q4Start + 1) % 12) + 1)}` },
      ],
    };
  }, [formData.fiscalYearStartMonth, isArabic]);

  // Date preview helper
  const datePreview = useMemo(() => {
    switch (formData.dateFormat) {
      case "MM/DD/YYYY": return "10/20/2026";
      case "DD/MM/YYYY": return "20/10/2026";
      case "YYYY-MM-DD": return "2026-10-20";
      case "DD-MM-YYYY": return "20-10-2026";
      case "MMM DD, YYYY": return isArabic ? "20 أكتوبر 2026" : "Oct 20, 2026";
      case "DD MMM YYYY": return isArabic ? "20 أكتوبر 2026" : "20 Oct 2026";
      case "YYYY/MM/DD": return "2026/10/20";
      default: return "10/20/2026";
    }
  }, [formData.dateFormat, isArabic]);

  const selectedMonth = MONTHS.find((m) => m.value.toString() === formData.fiscalYearStartMonth);
  const selectedCurrency = CURRENCIES.find((c) => c.code === formData.currency);

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
          <div className="p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-lg flex items-start gap-3 text-sm animate-in fade-in">
            <AlertCircle className="w-5 h-5 shrink-0" />
            <p>{error}</p>
          </div>
        )}
        {success && (
          <div className="p-4 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400 rounded-lg flex items-start gap-3 text-sm animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <p>{t("saved")}</p>
          </div>
        )}
        {migrationSuccessMsg && (
          <div className="p-4 bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 text-purple-700 dark:text-purple-300 rounded-xl flex items-start gap-3 text-sm animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 shrink-0 text-purple-600 dark:text-purple-400" />
            <p className="font-medium">{migrationSuccessMsg}</p>
          </div>
        )}

        {/* Business Settings Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden shadow-sm">
          <div className="p-6 border-b border-gray-200 dark:border-gray-600 flex items-center justify-between">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {t("general.businessSettings")}
            </h3>
            {isDirty && (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20 animate-pulse">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                {isArabic ? "تعديلات غير محفوظة" : "Unsaved changes"}
              </span>
            )}
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

              {/* Currency Dropdown with Real-Time Conversion Modal */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.currency")}</Label>
                  <span className="text-[11px] font-semibold text-purple-600 dark:text-purple-400 bg-purple-500/10 px-2 py-0.5 rounded-full border border-purple-500/20">
                    Live FX Engine
                  </span>
                </div>
                <Select
                  value={formData.currency}
                  onValueChange={(val) => {
                    if (val !== formData.currency) {
                      setPendingCurrency(val);
                      setIsMigrationModalOpen(true);
                    }
                  }}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Currency">
                      {selectedCurrency ? getLocalizedCurrencyOption(selectedCurrency, locale) : formData.currency}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {CURRENCIES.map((curr) => (
                      <SelectItem key={curr.code} value={curr.code}>
                        {getLocalizedCurrencyOption(curr, locale)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-[11px] text-gray-500 dark:text-gray-400">
                  {locale === "ar" 
                    ? "عند تغيير العملة، سيعرض النظام معاينة حية لسعر الصرف وخيار تحويل كافة المعاملات السابقة."
                    : "Changing base currency prompts live market rate preview with option to convert previous transactions."}
                </p>
              </div>

              {/* Timezone Dropdown with Scroll */}
              <div className="space-y-2">
                <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.timezone")}</Label>
                <Select
                  value={formData.timezone}
                  onValueChange={(val) => setFormData({ ...formData, timezone: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Timezone">
                      {getLocalizedTimezone(formData.timezone, locale) || formData.timezone}
                    </SelectValue>
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

              {/* Fiscal Year Start Dropdown with Rich Working Period Breakdown */}
              <div className="space-y-3 md:col-span-2">
                <div className="flex items-center justify-between">
                  <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.fiscalYearStart")}</Label>
                  <span className="text-[11px] font-semibold text-purple-600 dark:text-purple-400 bg-purple-500/10 px-2 py-0.5 rounded-full border border-purple-500/20">
                    {isArabic ? "دورة محاسبية نشطة" : "Active Accounting Cycle"}
                  </span>
                </div>
                <Select
                  value={formData.fiscalYearStartMonth}
                  onValueChange={(val) => setFormData({ ...formData, fiscalYearStartMonth: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white w-full md:w-80">
                    <SelectValue placeholder="Select Month">
                      {selectedMonth
                        ? `${isArabic ? selectedMonth.nameAr : selectedMonth.nameEn} (${isArabic ? `الشهر ${selectedMonth.value}` : `Month ${selectedMonth.value}`})`
                        : formData.fiscalYearStartMonth}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    {MONTHS.map((m) => (
                      <SelectItem key={m.value} value={m.value.toString()}>
                        {m.value} - {isArabic ? m.nameAr : m.nameEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                {/* Rich Real Working Fiscal Year Breakdown Card */}
                <div className="p-4 rounded-xl border border-purple-100 dark:border-purple-900/40 bg-purple-50/40 dark:bg-purple-950/20 space-y-3">
                  <div className="flex items-center gap-2 text-xs font-semibold text-purple-800 dark:text-purple-300">
                    <Calendar className="w-4 h-4 text-purple-600 dark:text-purple-400 shrink-0" />
                    <span>
                      {isArabic
                        ? `تمتد السنة المالية من 1 ${fiscalYearDetails.startMonthName} إلى ${fiscalYearDetails.endDay} ${fiscalYearDetails.endMonthName}`
                        : `Fiscal year spans from ${fiscalYearDetails.startMonthName} 1 to ${fiscalYearDetails.endMonthName} ${fiscalYearDetails.endDay}`}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1">
                    {fiscalYearDetails.quarters.map((q, idx) => (
                      <div 
                        key={idx} 
                        className="p-2 rounded-lg bg-white/80 dark:bg-gray-800/80 border border-purple-200/50 dark:border-purple-800/40 text-center"
                      >
                        <p className="text-[10px] uppercase font-bold text-purple-600 dark:text-purple-400">
                          {q.name}
                        </p>
                        <p className="text-xs font-semibold text-gray-800 dark:text-gray-200 mt-0.5">
                          {q.range}
                        </p>
                      </div>
                    ))}
                  </div>

                  <p className="text-[11px] text-gray-500 dark:text-gray-400">
                    {t("general.fiscalYearHelper")}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Regional Formats Card: Date Format & Number Format Side-by-Side */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 overflow-hidden shadow-sm">
          <div className="p-6 border-b border-gray-200 dark:border-gray-600 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="bg-[#8b5cf6]/10 p-2 rounded-lg text-[#8b5cf6]">
                <CalendarDays className="w-5 h-5" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{t("general.regionalFormats")}</h3>
            </div>
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
              {isArabic ? "تخصيص العرض المالي والتواريخ" : "Display & Formatting Rules"}
            </span>
          </div>
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

              {/* Date Format Scrollable Select */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.dateFormat")}</Label>
                  <span className="text-[11px] text-gray-400">
                    {isArabic ? "معاينة:" : "Preview:"}{" "}
                    <span className="font-mono font-bold text-[#8b5cf6]">{datePreview}</span>
                  </span>
                </div>
                <Select
                  value={formData.dateFormat}
                  onValueChange={(val) => setFormData({ ...formData, dateFormat: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Date Format">
                      {getLocalizedDateFormat(formData.dateFormat, locale) || formData.dateFormat}
                    </SelectValue>
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
                <div className="flex items-center justify-between">
                  <Label className="text-gray-700 dark:text-gray-300 font-semibold">{t("general.numberFormat")}</Label>
                  <span className="text-[11px] text-gray-400">
                    {isArabic ? "معاينة:" : "Preview:"}{" "}
                    <span className="font-mono font-bold text-emerald-600 dark:text-emerald-400">
                      {formatCurrency(1234567.89, formData.currency, formData.numberFormat)}
                    </span>
                  </span>
                </div>
                <Select
                  value={formData.numberFormat}
                  onValueChange={(val) => setFormData({ ...formData, numberFormat: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Number Format">
                      {getLocalizedNumberFormat(formData.numberFormat, locale) || formData.numberFormat}
                    </SelectValue>
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

        {/* Action Buttons: Cancel and Save Changes with Real Dirty State */}
        <div className="flex justify-end gap-3 mt-8 pt-4">
          <Button 
            type="button"
            variant="outline" 
            onClick={handleCancel}
            disabled={!isDirty || isLoading}
            className="min-w-[120px] border-gray-200 dark:border-gray-600 text-gray-700 dark:text-gray-300 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
          >
            <RotateCcw className="w-4 h-4 ltr:mr-1.5 rtl:ml-1.5 opacity-70" />
            {t("general.cancel")}
          </Button>
          <Button
            type="button"
            onClick={handleSave}
            disabled={!isDirty || isLoading}
            className="bg-[#8b5cf6] hover:bg-[#7c3aed] text-white min-w-[140px] disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-md shadow-purple-500/20"
          >
            {isLoading ? (
              <AfabLoader size="sm" />
            ) : (
              <>
                <Check className="w-4 h-4 ltr:mr-1.5 rtl:ml-1.5" />
                {t("saveChanges")}
              </>
            )}
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

      {/* Real-Time Currency Migration Modal */}
      {pendingCurrency && (
        <CurrencyMigrationModal
          isOpen={isMigrationModalOpen}
          oldCurrency={formData.currency}
          newCurrency={pendingCurrency}
          onClose={() => {
            setIsMigrationModalOpen(false);
            setPendingCurrency(null);
          }}
          onSuccess={handleMigrationSuccess}
        />
      )}
    </div>
  );
}
