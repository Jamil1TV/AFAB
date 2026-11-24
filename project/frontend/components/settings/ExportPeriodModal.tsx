"use client";

import { useState, useEffect } from "react";
import { useLocale } from "next-intl";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  FileSpreadsheet,
  FileText,
  Printer,
  Calendar,
  Clock,
  Filter,
  Check,
  ShieldCheck,
  Loader2,
  CalendarDays,
  Image as ImageIcon,
  FileSignature
} from "lucide-react";
import { PERIOD_PRESETS, calculateDateRange } from "@/lib/export-utils";
import { formatCurrency } from "@/lib/currency";

export type ExportActionType =
  | "master-excel"
  | "master-pdf"
  | "print"
  | "transactions-excel"
  | "transactions-pdf"
  | "customers-excel"
  | "customers-pdf"
  | "invoices-excel"
  | "invoices-pdf"
  | "reports-excel"
  | "reports-pdf";

interface ExportPeriodModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  actionType: ExportActionType | null;
  defaultPeriod?: string;
  defaultCurrency?: string;
  defaultFiscalMatricule?: string;
  defaultBusinessAddress?: string;
  defaultBusinessLogo?: string;
  defaultBusinessPurpose?: string;
  onConfirm: (config: {
    period: string;
    customStart?: string;
    customEnd?: string;
    currency: string;
    includeLogo: boolean;
    includeSignature: boolean;
    fiscalMatricule?: string;
    businessAddress?: string;
    businessLogoUrl?: string;
    businessPurpose?: string;
  }) => Promise<void> | void;
}

export function ExportPeriodModal({
  open,
  onOpenChange,
  actionType,
  defaultPeriod = "all",
  defaultCurrency = "USD",
  defaultFiscalMatricule = "",
  defaultBusinessAddress = "",
  defaultBusinessLogo = "",
  defaultBusinessPurpose = "",
  onConfirm,
}: ExportPeriodModalProps) {
  const locale = useLocale();
  const isAr = locale === "ar";

  const [period, setPeriod] = useState<string>(defaultPeriod);
  const [customStart, setCustomStart] = useState<string>("");
  const [customEnd, setCustomEnd] = useState<string>("");
  const [currency, setCurrency] = useState<string>(defaultCurrency);
  const [fiscalMatricule, setFiscalMatricule] = useState<string>(defaultFiscalMatricule);
  const [businessAddress, setBusinessAddress] = useState<string>(defaultBusinessAddress);
  const [businessLogo, setBusinessLogo] = useState<string>(defaultBusinessLogo);
  const [businessPurpose, setBusinessPurpose] = useState<string>(defaultBusinessPurpose);
  const [includeLogo, setIncludeLogo] = useState<boolean>(true);
  const [includeSignature, setIncludeSignature] = useState<boolean>(true);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  // Sync default period and currency when opened
  useEffect(() => {
    if (open) {
      setPeriod(defaultPeriod || "all");
      setCurrency(defaultCurrency || "USD");
      setFiscalMatricule(
        defaultFiscalMatricule || 
        (typeof window !== "undefined" ? localStorage.getItem("afab_fiscal_matricule") || "" : "")
      );
      setBusinessAddress(
        defaultBusinessAddress ||
        (typeof window !== "undefined" ? localStorage.getItem("afab_business_address") || "" : "")
      );
      setBusinessLogo(
        defaultBusinessLogo ||
        (typeof window !== "undefined" ? localStorage.getItem("afab_business_logo") || "" : "")
      );
      setBusinessPurpose(
        defaultBusinessPurpose ||
        (typeof window !== "undefined" ? localStorage.getItem("afab_business_purpose") || "" : "")
      );
      setIsSubmitting(false);
    }
  }, [open, defaultPeriod, defaultCurrency, defaultFiscalMatricule, defaultBusinessAddress, defaultBusinessLogo, defaultBusinessPurpose]);

  const activeRange = calculateDateRange(period, customStart, customEnd, isAr);

  const isExcel = actionType?.includes("excel");
  const isPdf = actionType?.includes("pdf");
  const isPrint = actionType === "print";

  const getFormatBadge = () => {
    if (isExcel) {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 px-3 py-1 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
          <FileSpreadsheet className="w-3.5 h-3.5" />
          <span>Excel Workbook (.xlsx)</span>
        </span>
      );
    }
    if (isPdf) {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full bg-purple-500/10 border border-purple-500/20 px-3 py-1 text-xs font-semibold text-[var(--primary)]">
          <FileText className="w-3.5 h-3.5" />
          <span>Enterprise PDF (.pdf)</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-sky-500/10 border border-sky-500/20 px-3 py-1 text-xs font-semibold text-sky-600 dark:text-sky-400">
        <Printer className="w-3.5 h-3.5" />
        <span>Print View / Vector PDF</span>
      </span>
    );
  };

  const handleDownload = async () => {
    setIsSubmitting(true);
    try {
      const cleanMf = fiscalMatricule.trim();
      const cleanAddr = businessAddress.trim();
      const cleanPurp = businessPurpose.trim();
      if (typeof window !== "undefined") {
        if (cleanMf) localStorage.setItem("afab_fiscal_matricule", cleanMf);
        if (cleanAddr) localStorage.setItem("afab_business_address", cleanAddr);
        if (cleanPurp) localStorage.setItem("afab_business_purpose", cleanPurp);
        if (businessLogo) localStorage.setItem("afab_business_logo", businessLogo);
      }
      await onConfirm({
        period,
        customStart,
        customEnd,
        currency,
        includeLogo,
        includeSignature,
        fiscalMatricule: cleanMf,
        businessAddress: cleanAddr,
        businessLogoUrl: businessLogo || undefined,
        businessPurpose: cleanPurp || undefined,
      });
      onOpenChange(false);
    } catch (e) {
      console.error(e);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-xl max-h-[88vh] flex flex-col p-0 gap-0 bg-white dark:bg-[#0c101c] border-gray-200 dark:border-gray-800/80 rounded-3xl shadow-2xl overflow-hidden">
        {/* ── Fixed Header ── */}
        <DialogHeader className="p-5 pb-3.5 pe-12 space-y-1.5 text-start border-b border-gray-100 dark:border-gray-800/60 shrink-0">
          <div className="flex items-center justify-between">
            {getFormatBadge()}
          </div>
          <DialogTitle className="text-lg sm:text-xl font-extrabold text-gray-900 dark:text-white">
            {isAr ? "تحديد فترة التصدير والصيغة" : "Choose Export Period & Confirm"}
          </DialogTitle>
          <DialogDescription className="text-xs text-gray-500 dark:text-gray-400">
            {isAr
              ? "حدد النطاق والبيانات الرسمية التي ترغب في تضمينها في ملف التصدير قبل التنزيل."
              : "Select the date range and official business details you wish to include in your export."}
          </DialogDescription>
        </DialogHeader>

        {/* ── Scrollable Body ── */}
        <div className="flex-1 overflow-y-auto p-5 space-y-4">
          {/* ── Period Presets Pills ── */}
          <div>
            <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-2">
              {isAr ? "الفترة الزمنية للبيانات:" : "Data Time Period:"}
            </label>
            <div className="grid grid-cols-3 gap-2">
              {PERIOD_PRESETS.map((p) => {
                const isSelected = period === p.id;
                return (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => setPeriod(p.id)}
                    className={`px-2.5 py-2 rounded-xl text-xs font-medium border text-center transition-all duration-150 cursor-pointer ${
                      isSelected
                        ? "bg-[var(--primary)] text-white border-[var(--primary)] shadow-sm shadow-purple-500/20"
                        : "bg-gray-50 dark:bg-white/[0.03] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-800 hover:border-gray-300 dark:hover:border-gray-700"
                      }`}
                  >
                    {isAr ? p.labelAr : p.labelEn}
                  </button>
                );
              })}
            </div>
          </div>

          {/* ── Custom Date Pickers (if custom selected) ── */}
          {period === "custom" && (
            <div className="p-3.5 rounded-2xl bg-gray-50 dark:bg-white/[0.02] border border-gray-200 dark:border-gray-800 space-y-3">
              <div className="flex items-center gap-2 text-xs font-semibold text-gray-700 dark:text-gray-300">
                <CalendarDays className="w-4 h-4 text-[var(--primary)]" />
                <span>{isAr ? "تحديد نطاق مخصص:" : "Specify Custom Date Range:"}</span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label htmlFor="modal-start-date" className="block text-[11px] text-gray-500 mb-1">
                    {isAr ? "من تاريخ:" : "Start Date:"}
                  </label>
                  <Input
                    id="modal-start-date"
                    type="date"
                    value={customStart}
                    onChange={(e) => setCustomStart(e.target.value)}
                    className="h-9 text-xs rounded-xl"
                  />
                </div>
                <div>
                  <label htmlFor="modal-end-date" className="block text-[11px] text-gray-500 mb-1">
                    {isAr ? "إلى تاريخ:" : "End Date:"}
                  </label>
                  <Input
                    id="modal-end-date"
                    type="date"
                    value={customEnd}
                    onChange={(e) => setCustomEnd(e.target.value)}
                    className="h-9 text-xs rounded-xl"
                  />
                </div>
              </div>
            </div>
          )}

          {/* ── Business Info: Fiscal Matricule & Purpose (2 Columns) ── */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {/* Fiscal Matricule (MF) Input */}
            <div className="p-3 rounded-2xl bg-gray-50 dark:bg-white/[0.02] border border-gray-200 dark:border-gray-800 space-y-1">
              <div className="flex items-center justify-between">
                <label htmlFor="modal-fiscal-matricule" className="block text-xs font-bold text-gray-700 dark:text-gray-300">
                  {isAr ? "المعرف الجبائي (MF):" : "Fiscal Matricule (MF):"}
                </label>
                <span className="text-[10px] text-gray-400">
                  {isAr ? "في الترويسة" : "Headers & seals"}
                </span>
              </div>
              <Input
                id="modal-fiscal-matricule"
                type="text"
                value={fiscalMatricule}
                onChange={(e) => setFiscalMatricule(e.target.value)}
                placeholder={isAr ? "مثال: 1234567/A/B/M/000" : "e.g. 1234567/A/B/M/000"}
                className="h-8.5 text-xs rounded-xl bg-white dark:bg-[#0c101c]"
              />
            </div>

            {/* Business Purpose & Activity Input */}
            <div className="p-3 rounded-2xl bg-gray-50 dark:bg-white/[0.02] border border-gray-200 dark:border-gray-800 space-y-1">
              <div className="flex items-center justify-between">
                <label htmlFor="modal-business-purpose" className="block text-xs font-bold text-gray-700 dark:text-gray-300">
                  {isAr ? "غرض الشركة / النشاط:" : "Purpose & Activity:"}
                </label>
                <span className="text-[10px] text-gray-400">
                  {isAr ? "طبيعة النشاط" : "Business scope"}
                </span>
              </div>
              <Input
                id="modal-business-purpose"
                type="text"
                value={businessPurpose}
                onChange={(e) => setBusinessPurpose(e.target.value)}
                placeholder={isAr ? "مثال: تجارة عامة، برمجيات..." : "e.g. Retail, Software, Consulting..."}
                className="h-8.5 text-xs rounded-xl bg-white dark:bg-[#0c101c]"
              />
            </div>
          </div>

          {/* ── Business Address Input ── */}
          <div className="p-3 rounded-2xl bg-gray-50 dark:bg-white/[0.02] border border-gray-200 dark:border-gray-800 space-y-1">
            <div className="flex items-center justify-between">
              <label htmlFor="modal-business-address" className="block text-xs font-bold text-gray-700 dark:text-gray-300">
                {isAr ? "عنوان مقر الشركة (Business Address):" : "Official Business Address:"}
              </label>
              <span className="text-[10px] text-gray-400">
                {isAr ? "يُدرج في الترويسة" : "Printed on headers"}
              </span>
            </div>
            <Input
              id="modal-business-address"
              type="text"
              value={businessAddress}
              onChange={(e) => setBusinessAddress(e.target.value)}
              placeholder={isAr ? "مثال: شارع الحبيب بورقيبة، تونس / 123 Business Way" : "e.g. Avenue Habib Bourguiba, Tunis / 123 Business Way"}
              className="h-8.5 text-xs rounded-xl bg-white dark:bg-[#0c101c]"
            />
          </div>

          {/* ── Currency & Logo Options ── */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label htmlFor="modal-currency-select" className="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1.5">
                {isAr ? "العملة المعتمدة:" : "Reporting Currency:"}
              </label>
              <select
                id="modal-currency-select"
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="w-full appearance-none rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.03] px-3 py-2 text-xs font-medium text-gray-800 dark:text-gray-200 hover:border-gray-300 focus:outline-hidden focus:ring-2 focus:ring-[var(--primary)] cursor-pointer"
              >
                {["USD", "EUR", "SAR", "AED", "TND", "GBP", "CAD", "KWD"].map((curr) => (
                  <option key={curr} value={curr} className="dark:bg-[#0c101c]">
                    {curr}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1.5">
                {isAr ? "الشعار والعلامة التجارية:" : "Business Logo & Branding:"}
              </label>
              <div className="space-y-1.5">
                <label className="flex items-center gap-2 h-9 px-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.03] cursor-pointer hover:bg-gray-100/60 dark:hover:bg-white/[0.05]">
                  <input
                    type="checkbox"
                    checked={includeLogo}
                    onChange={(e) => setIncludeLogo(e.target.checked)}
                    className="rounded text-[var(--primary)] focus:ring-[var(--primary)] h-4 w-4"
                  />
                  <span className="text-xs font-medium text-gray-700 dark:text-gray-300">
                    {isAr ? "تضمين شعار المؤسسة" : "Include Business Logo"}
                  </span>
                </label>

                {includeLogo && (
                  <div className="flex items-center justify-between gap-3 p-1.5 px-2.5 rounded-xl bg-gray-50/80 dark:bg-white/[0.02] border border-gray-200/80 dark:border-gray-800/80">
                    <div className="flex items-center gap-2 overflow-hidden">
                      <div className="h-7 w-7 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-black/40 flex items-center justify-center p-0.5 overflow-hidden shrink-0">
                        <img
                          src={businessLogo || "/assets/afab-logo-light.png"}
                          alt="Logo Preview"
                          className="max-h-full max-w-full object-contain"
                        />
                      </div>
                      <span className="text-[10px] font-medium text-gray-600 dark:text-gray-400 truncate">
                        {businessLogo
                          ? (isAr ? "شعار مخصص" : "Custom Logo")
                          : (isAr ? "شعار AFAB" : "Default Logo")}
                      </span>
                    </div>

                    <div>
                      <input
                        type="file"
                        id="modal-logo-upload"
                        accept="image/*"
                        className="hidden"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            const reader = new FileReader();
                            reader.onloadend = () => {
                              if (typeof reader.result === "string") {
                                setBusinessLogo(reader.result);
                                if (typeof window !== "undefined") {
                                  localStorage.setItem("afab_business_logo", reader.result);
                                }
                              }
                            };
                            reader.readAsDataURL(file);
                          }
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => document.getElementById("modal-logo-upload")?.click()}
                        className="px-2 py-0.5 text-[10px] font-semibold text-[var(--primary)] border border-purple-200 dark:border-purple-800/80 rounded-lg hover:bg-purple-50 dark:hover:bg-purple-950/30 transition-colors"
                      >
                        {isAr ? "تغيير" : "Change"}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* ── Wet Signature Checkbox ── */}
          <div>
            <label className="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1.5">
              {isAr ? "التوقيع الحي المعتمد:" : "Wet Signature:"}
            </label>
            <label className="flex items-center gap-2 h-9 px-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-white/[0.03] cursor-pointer hover:bg-gray-100/60 dark:hover:bg-white/[0.05]">
              <input
                type="checkbox"
                checked={includeSignature}
                onChange={(e) => setIncludeSignature(e.target.checked)}
                className="rounded text-[var(--primary)] focus:ring-[var(--primary)] h-4 w-4"
              />
              <span className="text-xs font-medium text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                <FileSignature className="w-3.5 h-3.5 text-[var(--primary)]" />
                <span>{isAr ? "تضمين التوقيع الحي" : "Include Wet Signature"}</span>
              </span>
            </label>
          </div>

          {/* ── Active Scope Preview Badge ── */}
          <div className="rounded-2xl border border-purple-200/60 dark:border-purple-900/40 bg-purple-50/50 dark:bg-purple-950/20 p-3 flex items-center justify-between text-xs">
            <div className="flex items-center gap-2 text-gray-700 dark:text-gray-300">
              <Clock className="w-4 h-4 text-[var(--primary)]" />
              <span>{isAr ? "نطاق التصدير الفعلي:" : "Active Export Range:"}</span>
            </div>
            <span className="font-bold text-[var(--primary)] bg-white dark:bg-purple-900/40 px-2.5 py-1 rounded-lg border border-purple-200 dark:border-purple-800/60 shadow-2xs">
              {activeRange.label}
            </span>
          </div>
        </div>

        {/* ── Dialog Action Buttons (Sticky Footer) ── */}
        <div className="p-4 px-5 flex flex-col sm:flex-row items-center justify-end gap-2.5 border-t border-gray-100 dark:border-gray-800/60 bg-gray-50/80 dark:bg-white/[0.02] shrink-0 z-10">
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={isSubmitting}
            className="w-full sm:w-auto rounded-xl text-xs h-10 px-4"
          >
            {isAr ? "إلغاء" : "Cancel"}
          </Button>

          <Button
            type="button"
            onClick={handleDownload}
            disabled={isSubmitting}
            className={`w-full sm:w-auto font-semibold rounded-xl text-xs h-10 px-5 flex items-center justify-center gap-2 shadow-sm ${isExcel
              ? "bg-emerald-600 hover:bg-emerald-700 text-white shadow-emerald-500/20"
              : "bg-[var(--primary)] hover:bg-[var(--primary-hover,#7c3aed)] text-white shadow-purple-500/20"
              }`}
          >
            {isSubmitting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>{isAr ? "جاري التجهيز والتنزيل..." : "Preparing Download..."}</span>
              </>
            ) : (
              <>
                {isExcel && <FileSpreadsheet className="w-4 h-4" />}
                {isPdf && <FileText className="w-4 h-4" />}
                {isPrint && <Printer className="w-4 h-4" />}
                <span>
                  {isAr
                    ? isExcel
                      ? "تنزيل ملف إكسل الآن"
                      : isPdf
                        ? "تنزيل ملف PDF الآن"
                        : "فتح معاينة الطباعة"
                    : isExcel
                      ? "Download Excel (.xlsx) Now"
                      : isPdf
                        ? "Download PDF (.pdf) Now"
                        : "Open Print View"}
                </span>
              </>
            )}
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
