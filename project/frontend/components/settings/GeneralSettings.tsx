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
import { PageHeader } from "@/components/dashboard/PageHeader";
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
import { EditProfileModal } from "./EditProfileModal";
import { DeleteAccountModal } from "./DeleteAccountModal";

export function GeneralSettings({
  profile,
  business,
  onRefresh,
}: {
  profile: any;
  business: any;
  onRefresh?: () => Promise<void>;
}) {
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
  const isReadOnly = business?.editable === false;
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [isMigrationModalOpen, setIsMigrationModalOpen] = useState(false);
  const [pendingCurrency, setPendingCurrency] = useState<string | null>(null);
  const [migrationSuccessMsg, setMigrationSuccessMsg] = useState<string | null>(null);

  // Account card & Other Settings states
  const [isEditProfileOpen, setIsEditProfileOpen] = useState(false);
  const [isDeleteAccountOpen, setIsDeleteAccountOpen] = useState(false);
  const [isExportingData, setIsExportingData] = useState(false);
  const [exportStatusMsg, setExportStatusMsg] = useState<string | null>(null);
  const [exportErrorMsg, setExportErrorMsg] = useState<string | null>(null);
  const [profileUpdatedMsg, setProfileUpdatedMsg] = useState<string | null>(null);

  const handleProfileSaved = async () => {
    if (onRefresh) {
      await onRefresh();
    }
    setProfileUpdatedMsg(
      isArabic
        ? "تم تحديث الملف الشخصي بنجاح!"
        : "Your profile has been updated successfully!"
    );
    setTimeout(() => setProfileUpdatedMsg(null), 4000);
  };

  const handleExportMyData = async () => {
    if (isExportingData) return;
    setIsExportingData(true);
    setExportErrorMsg(null);
    setExportStatusMsg(null);
    try {
      const result = await SettingsService.exportMyData();
      setExportStatusMsg(
        isArabic
          ? `تم تنزيل ${result.filename} (${result.summary.businessesCount} شركات، ${result.summary.transactionsCount} معاملات)`
          : `Downloaded ${result.filename} (${result.summary.businessesCount} workspaces, ${result.summary.transactionsCount} transactions)`
      );
      setTimeout(() => setExportStatusMsg(null), 7000);
    } catch (err: unknown) {
      setExportErrorMsg(
        err instanceof Error
          ? err.message
          : isArabic
          ? "تعذر تصدير البيانات حالياً. يرجى المحاولة لاحقاً."
          : "Failed to export account data. Please try again."
      );
    } finally {
      setIsExportingData(false);
    }
  };

  const handleMigrationSuccess = (newCurr: string, _count: number) => {
    setFormData((prev) => ({ ...prev, currency: newCurr }));
    setBaselineFormData((prev) => ({ ...prev, currency: newCurr }));
    setMigrationSuccessMsg(
      locale === "ar"
        ? `تم تحديث العملة الأساسية بنجاح إلى ${newCurr} للمعاملات المستقبلية مع الحفاظ على سجل المعاملات التاريخية.`
        : `Updated base currency to ${newCurr} for future transactions while preserving all historical FX snapshots.`
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
        <PageHeader
          title={t("general.title")}
          subtitle={t("general.subtitle")}
        />

        {error && (
          <div className="p-4 rounded-xl border border-red-500/20 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-start gap-3 text-sm animate-in fade-in">
            <AlertCircle className="w-5 h-5 shrink-0" />
            <p>{error}</p>
          </div>
        )}
        {success && (
          <div className="p-4 rounded-xl border border-emerald-500/20 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-start gap-3 text-sm animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <p>{t("saved")}</p>
          </div>
        )}
        {migrationSuccessMsg && (
          <div className="p-4 rounded-xl border border-[var(--primary)]/30 bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)] flex items-start gap-3 text-sm animate-in fade-in">
            <CheckCircle2 className="w-5 h-5 shrink-0 text-[var(--primary-hover)] dark:text-[var(--primary)]" />
            <p className="font-medium">{migrationSuccessMsg}</p>
          </div>
        )}

        {/* Business Settings Card */}
        <div className="afab-card overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-800/60 flex flex-wrap items-center justify-between gap-2">
            <h3 className="afab-card-title">
              {t("general.businessSettings")}
            </h3>
            {isDirty && (
              <span className="afab-badge afab-badge-warning animate-pulse">
                <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
                {isArabic ? "تعديلات غير محفوظة" : "Unsaved changes"}
              </span>
            )}
          </div>
          <div className="p-6 space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label className="afab-label">{t("general.businessName")}</Label>
                <Input
                  className="afab-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="afab-label">{t("general.businessEmail")}</Label>
                <Input
                  className="afab-input"
                  type="email"
                  value={formData.businessEmail}
                  onChange={(e) => setFormData({ ...formData, businessEmail: e.target.value })}
                  placeholder="billing@example.com"
                />
              </div>

              {/* Currency Dropdown with Real-Time Conversion Modal */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <Label className="afab-label mb-0">{t("general.currency")}</Label>
                  <span className="afab-badge afab-badge-primary">
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
                  <SelectTrigger className="afab-input">
                    <SelectValue placeholder="Select Currency">
                      {selectedCurrency ? getLocalizedCurrencyOption(selectedCurrency, locale) : formData.currency}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
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
                <Label className="afab-label">{t("general.timezone")}</Label>
                <Select
                  value={formData.timezone}
                  onValueChange={(val) => setFormData({ ...formData, timezone: val })}
                >
                  <SelectTrigger className="afab-input">
                    <SelectValue placeholder="Select Timezone">
                      {getLocalizedTimezone(formData.timezone, locale) || formData.timezone}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
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
                  <Label className="afab-label mb-0">{t("general.fiscalYearStart")}</Label>
                  <span className="afab-badge afab-badge-primary">
                    {isArabic ? "دورة محاسبية نشطة" : "Active Accounting Cycle"}
                  </span>
                </div>
                <Select
                  value={formData.fiscalYearStartMonth}
                  onValueChange={(val) => setFormData({ ...formData, fiscalYearStartMonth: val })}
                >
                  <SelectTrigger className="afab-input w-full md:w-80">
                    <SelectValue placeholder="Select Month">
                      {selectedMonth
                        ? `${isArabic ? selectedMonth.nameAr : selectedMonth.nameEn} (${isArabic ? `الشهر ${selectedMonth.value}` : `Month ${selectedMonth.value}`})`
                        : formData.fiscalYearStartMonth}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
                    {MONTHS.map((m) => (
                      <SelectItem key={m.value} value={m.value.toString()}>
                        {m.value} - {isArabic ? m.nameAr : m.nameEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>

                {/* Rich Real Working Fiscal Year Breakdown Card */}
                <div className="afab-inset p-4 space-y-3">
                  <div className="flex items-center gap-2 text-xs font-semibold text-[var(--primary-hover)] dark:text-[var(--primary)]">
                    <Calendar className="w-4 h-4 text-[var(--primary)] shrink-0" />
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
                        className="p-2.5 rounded-xl bg-white dark:bg-[#0c101c] border border-gray-200 dark:border-gray-800/60 text-center"
                      >
                        <p className="text-[10px] uppercase font-bold text-[var(--primary-hover)] dark:text-[var(--primary)]">
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
        <div className="afab-card overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-800/60 flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)]">
                <CalendarDays className="w-5 h-5" />
              </div>
              <h3 className="afab-card-title">{t("general.regionalFormats")}</h3>
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
                  <Label className="afab-label mb-0">{t("general.dateFormat")}</Label>
                  <span className="text-[11px] text-gray-500 dark:text-gray-400">
                    {isArabic ? "معاينة:" : "Preview:"}{" "}
                    <span className="font-mono font-bold text-[var(--primary-hover)] dark:text-[var(--primary)]">{datePreview}</span>
                  </span>
                </div>
                <Select
                  value={formData.dateFormat}
                  onValueChange={(val) => setFormData({ ...formData, dateFormat: val })}
                >
                  <SelectTrigger className="afab-input">
                    <SelectValue placeholder="Select Date Format">
                      {getLocalizedDateFormat(formData.dateFormat, locale) || formData.dateFormat}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
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
                  <Label className="afab-label mb-0">{t("general.numberFormat")}</Label>
                  <span className="text-[11px] text-gray-500 dark:text-gray-400">
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
                  <SelectTrigger className="afab-input">
                    <SelectValue placeholder="Select Number Format">
                      {getLocalizedNumberFormat(formData.numberFormat, locale) || formData.numberFormat}
                    </SelectValue>
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
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
        <div className="flex flex-wrap justify-end gap-3 mt-8 pt-4">
          <Button 
            type="button"
            variant="outline" 
            onClick={handleCancel}
            disabled={!isDirty || isLoading}
            className="afab-btn-secondary min-w-[120px]"
          >
            <RotateCcw className="w-4 h-4 me-1.5 opacity-70" />
            {t("general.cancel")}
          </Button>
          <Button
            type="button"
            onClick={handleSave}
            disabled={!isDirty || isLoading || isReadOnly}
            className="afab-btn-primary min-w-[140px]"
          >
            {isLoading ? (
              <AfabLoader size="sm" />
            ) : (
              <>
                <Check className="w-4 h-4 me-1.5" />
                {t("saveChanges")}
              </>
            )}
          </Button>
        </div>
      </div>

      {/* Account & Preferences */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        {/* Account Card */}
        <div className="afab-card overflow-hidden relative">
          <div className="h-24 bg-gray-50/80 dark:bg-[#080c18] border-b border-gray-100 dark:border-gray-800/60"></div>
          <div className="px-6 pb-6 text-center -mt-12 relative z-10">
            <Avatar className="w-24 h-24 mx-auto mb-4 border-4 border-white dark:border-[#0c101c] shadow-sm bg-white dark:bg-[#0c101c]">
              <AvatarImage src={profile?.avatarUrl} />
              <AvatarFallback className="text-2xl bg-[var(--primary)]/10 text-[var(--primary-hover)] dark:text-[var(--primary)] font-bold">
                {getInitials(profile?.firstName, profile?.lastName)}
              </AvatarFallback>
            </Avatar>
            <h3 className="afab-card-title">
              {profile?.firstName} {profile?.lastName}
            </h3>
            <p className="text-gray-500 dark:text-gray-400 text-sm mb-1">{profile?.email}</p>
            {profile?.phoneNumber && (
              <p className="text-gray-400 dark:text-gray-500 text-xs font-mono mb-4">
                {profile.phoneNumber}
              </p>
            )}
            {!profile?.phoneNumber && <div className="mb-5" />}
            {profileUpdatedMsg && (
              <div className="mb-3 px-3 py-2 rounded-xl border border-emerald-500/25 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 text-xs flex items-center justify-center gap-1.5 animate-in fade-in">
                <CheckCircle2 className="w-3.5 h-3.5 shrink-0" />
                <span>{profileUpdatedMsg}</span>
              </div>
            )}
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsEditProfileOpen(true)}
              className="afab-btn-secondary w-full"
            >
              {t("account.editProfile")}
            </Button>
          </div>
        </div>

        {/* Preferences */}
        <div className="afab-card p-6">
          <h3 className="afab-card-title mb-6">{t("preferences.title")}</h3>
          <div className="space-y-6">
            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.aiInsights")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("preferences.aiInsightsDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.enableAiInsights} 
                onCheckedChange={(c) => handlePrefChange('enableAiInsights', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.compactMode")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("preferences.compactModeDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.compactMode} 
                onCheckedChange={(c) => handlePrefChange('compactMode', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.autoCategorie")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("preferences.autoCategorieDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.autoCategorizeTransactions} 
                onCheckedChange={(c) => handlePrefChange('autoCategorizeTransactions', c)} 
              />
            </div>

            <div className="flex items-center justify-between gap-4">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("preferences.showTips")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("preferences.showTipsDesc")}</p>
              </div>
              <Switch 
                checked={userPrefs.showTips} 
                onCheckedChange={(c) => handlePrefChange('showTips', c)} 
              />
            </div>
          </div>
        </div>

        {/* Other Settings */}
        <div className="afab-card p-6 flex flex-col justify-between">
          <div>
            <h3 className="afab-card-title mb-4">{t("otherSettings.title")}</h3>
            <div className="space-y-1">
              <button
                type="button"
                onClick={handleExportMyData}
                disabled={isExportingData}
                className="w-full flex items-center justify-between group cursor-pointer p-3 hover:bg-gray-50 dark:hover:bg-white/[0.04] rounded-xl transition-colors text-start disabled:opacity-60 disabled:cursor-wait"
              >
                <div className="flex items-center gap-3 text-gray-700 dark:text-gray-300 min-w-0">
                  {isExportingData ? (
                    <AfabLoader size="xs" />
                  ) : (
                    <Download className="w-5 h-5 shrink-0 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)] transition-colors" />
                  )}
                  <div className="min-w-0">
                    <p className="text-sm font-medium group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)] transition-colors">
                      {isExportingData
                        ? isArabic
                          ? "جاري تصدير بياناتك..."
                          : "Exporting Your Data..."
                        : t("otherSettings.exportData")}
                    </p>
                    <p className="text-[11px] text-gray-400 dark:text-gray-500 truncate">
                      {t("otherSettings.exportDataDesc")}
                    </p>
                  </div>
                </div>
                <ChevronRight className="w-4 h-4 shrink-0 text-gray-400 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)] transition-colors rtl:rotate-180" />
              </button>

              <button
                type="button"
                onClick={() => setIsDeleteAccountOpen(true)}
                className="w-full flex items-center justify-between group cursor-pointer p-3 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors text-start"
              >
                <div className="flex items-center gap-3 text-red-600 dark:text-red-400 min-w-0">
                  <Trash2 className="w-5 h-5 shrink-0" />
                  <div className="min-w-0">
                    <p className="text-sm font-medium">{t("otherSettings.deleteAccount")}</p>
                    <p className="text-[11px] text-red-500/70 dark:text-red-400/70 truncate">
                      {t("otherSettings.deleteAccountDesc")}
                    </p>
                  </div>
                </div>
                <ChevronRight className="w-4 h-4 shrink-0 text-red-400 opacity-60 group-hover:opacity-100 transition-opacity rtl:rotate-180" />
              </button>
            </div>
          </div>

          {(exportStatusMsg || exportErrorMsg) && (
            <div className="mt-4 pt-3 border-t border-gray-100 dark:border-gray-800/60">
              {exportStatusMsg && (
                <div className="p-3 rounded-xl border border-emerald-500/25 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-start gap-2 text-xs animate-in fade-in">
                  <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{exportStatusMsg}</span>
                </div>
              )}
              {exportErrorMsg && (
                <div className="p-3 rounded-xl border border-red-500/25 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-start gap-2 text-xs animate-in fade-in">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{exportErrorMsg}</span>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Edit Profile Modal */}
      {isEditProfileOpen && (
        <EditProfileModal
          open={isEditProfileOpen}
          onOpenChange={setIsEditProfileOpen}
          profile={profile}
          onSuccess={handleProfileSaved}
        />
      )}

      {/* GitHub-Style Delete Account Modal (Export First -> Warning -> Type Phrase) */}
      <DeleteAccountModal
        open={isDeleteAccountOpen}
        onOpenChange={setIsDeleteAccountOpen}
        profile={profile}
        business={business}
      />

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
