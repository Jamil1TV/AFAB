"use client";

import { useTranslations, useLocale } from "next-intl";
import { useState } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { AlertCircle, CheckCircle2, Upload, MapPin, Building2, Calendar, Globe, Building } from "lucide-react";
import Image from "next/image";
import {
  INDUSTRIES,
  getLocalizedCountry,
  getLocalizedIndustry,
  getLocalizedTimezone,
} from "@/lib/constants/business-data";

export function BusinessProfile({ business }: { business: any }) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isArabic = locale === "ar";

  const [formData, setFormData] = useState({
    name: business?.name || "",
    industry: business?.industry || "",
    businessEmail: business?.businessEmail || "",
    phoneNumber: business?.phoneNumber || "",
    website: business?.website || "",
    taxId: business?.taxId || "",
    addressLine: business?.addressLine || "",
    city: business?.city || "",
    state: business?.state || "",
    postalCode: business?.postalCode || "",
    country: business?.country || "",
    description: business?.description || "",
    logoUrl: business?.logoUrl || `https://api.dicebear.com/7.x/initials/svg?seed=${business?.name || "Business"}`,
  });

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);

  const handleSave = async () => {
    setIsLoading(true);
    setError("");
    setSuccess(false);

    try {
      await SettingsService.updateBusiness(business.id, formData);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err: any) {
      setError(err.message || "Failed to update business profile");
    } finally {
      setIsLoading(false);
    }
  };

  const memberSince = new Date(business?.createdAt || new Date()).getFullYear();

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
      {/* Left Form Content */}
      <div className="xl:col-span-2 space-y-8">
        <PageHeader
          title={t("businessProfile.title")}
          subtitle={t("businessProfile.subtitle")}
        />

        <div className="afab-card p-6 space-y-8">
          {error && (
            <div className="p-4 rounded-xl border border-red-500/20 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-start gap-3 text-sm">
              <AlertCircle className="w-5 h-5 shrink-0" />
              <p>{error}</p>
            </div>
          )}
          {success && (
            <div className="p-4 rounded-xl border border-emerald-500/20 bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-start gap-3 text-sm">
              <CheckCircle2 className="w-5 h-5 shrink-0" />
              <p>{t("saved")}</p>
            </div>
          )}

          {/* Logo Upload */}
          <div>
            <Label className="afab-label mb-3">{t("businessProfile.logo")}</Label>
            <div className="flex flex-wrap items-center gap-6">
              <div className="relative w-24 h-24 rounded-2xl border-2 border-dashed border-gray-200 dark:border-gray-800 overflow-hidden flex items-center justify-center bg-gray-50/50 dark:bg-[#080c18]">
                <Image src={formData.logoUrl} alt="Logo" fill className="object-cover" unoptimized />
              </div>
              <div className="space-y-2">
                <input
                  type="file"
                  id="logo-upload-input"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) {
                      const reader = new FileReader();
                      reader.onloadend = () => {
                        if (typeof reader.result === "string") {
                          setFormData(prev => ({ ...prev, logoUrl: reader.result as string }));
                        }
                      };
                      reader.readAsDataURL(file);
                    }
                  }}
                />
                <Button
                  type="button"
                  variant="outline"
                  className="afab-btn-secondary"
                  onClick={() => document.getElementById("logo-upload-input")?.click()}
                >
                  <Upload className="w-4 h-4" />
                  {t("businessProfile.uploadLogo")}
                </Button>
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.logoHelper")}</p>
              </div>
            </div>
          </div>

          <div className="border-t border-gray-100 dark:border-gray-800/60"></div>

          {/* Business Info */}
          <div className="space-y-6">
            <h3 className="afab-card-title">{t("businessProfile.businessInfo")}</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.businessName")}</Label>
                <Input
                  className="afab-input"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.industry")}</Label>
                <Select
                  value={formData.industry || "Software"}
                  onValueChange={(val) => setFormData({ ...formData, industry: val })}
                >
                  <SelectTrigger className="afab-input">
                    <SelectValue placeholder="Select Industry" />
                  </SelectTrigger>
                  <SelectContent className="afab-popover max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer text-gray-900 dark:text-white">
                    {INDUSTRIES.map((ind) => (
                      <SelectItem key={ind.id} value={ind.nameEn}>
                        {isArabic ? ind.nameAr : ind.nameEn}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.businessEmail")}</Label>
                <Input
                  className="afab-input"
                  type="email"
                  value={formData.businessEmail}
                  onChange={(e) => setFormData({ ...formData, businessEmail: e.target.value })}
                  placeholder="contact@example.com"
                />
              </div>
              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.phoneNumber")}</Label>
                <Input
                  className="afab-input"
                  value={formData.phoneNumber}
                  onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                  placeholder="+1 (555) 000-0000"
                />
              </div>

              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.website")}</Label>
                <Input
                  className="afab-input"
                  value={formData.website}
                  onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                  placeholder="https://example.com"
                />
              </div>
              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.taxId")}</Label>
                <Input
                  className="afab-input"
                  value={formData.taxId}
                  onChange={(e) => setFormData({ ...formData, taxId: e.target.value })}
                  placeholder="Optional"
                />
              </div>

              <div className="space-y-2 md:col-span-2">
                <Label className="afab-label">{t("businessProfile.address")}</Label>
                <Input
                  className="afab-input"
                  value={formData.addressLine}
                  onChange={(e) => setFormData({ ...formData, addressLine: e.target.value })}
                  placeholder="123 Business St, Suite 100"
                />
              </div>

              <div className="space-y-2">
                <Label className="afab-label">{t("businessProfile.city")}</Label>
                <Input
                  className="afab-input"
                  value={formData.city}
                  onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                />
              </div>
              <div className="space-y-2 grid grid-cols-2 gap-4">
                <div>
                  <Label className="afab-label">{t("businessProfile.state")}</Label>
                  <Input
                    className="afab-input"
                    value={formData.state}
                    onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                  />
                </div>
                <div>
                  <Label className="afab-label">{t("businessProfile.postalCode")}</Label>
                  <Input
                    className="afab-input"
                    value={formData.postalCode}
                    onChange={(e) => setFormData({ ...formData, postalCode: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-2 md:col-span-2">
                <div className="flex items-center justify-between">
                  <Label className="afab-label">{t("businessProfile.description")}</Label>
                  <span className="text-xs text-gray-500 dark:text-gray-400">
                    {t("businessProfile.descriptionCounter", { count: formData.description.length })}
                  </span>
                </div>
                <Textarea
                  className="afab-input resize-none"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value.substring(0, 500) })}
                  placeholder="Briefly describe your business..."
                  rows={4}
                />
              </div>
            </div>
          </div>

          <div className="border-t border-gray-100 dark:border-gray-800/60 pt-6 flex flex-wrap justify-end gap-3">
            <Button variant="outline" className="afab-btn-secondary min-w-[120px]">{t("businessProfile.cancel") || "Cancel"}</Button>
            <Button
              onClick={handleSave}
              disabled={isLoading}
              className="afab-btn-primary min-w-[140px]"
            >
              {isLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
            </Button>
          </div>
        </div>
      </div>

      {/* Right Sidebar Content */}
      <div className="space-y-6">
        {/* Business Summary Card */}
        <div className="afab-card p-6">
          <h3 className="afab-card-title mb-1">{t("businessProfile.summary")}</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-6">{t("businessProfile.summarySubtitle")}</p>

          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-sky-500/10 flex items-center justify-center shrink-0">
                <Building2 className="w-4 h-4 text-sky-600 dark:text-sky-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.summaryName")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{formData.name}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#8b5cf6]/10 flex items-center justify-center shrink-0">
                <Building className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa]" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.summaryIndustry")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {getLocalizedIndustry(formData.industry || "Software", locale)}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-emerald-500/10 flex items-center justify-center shrink-0">
                <Calendar className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.summaryMemberSince")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{memberSince}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-amber-500/10 flex items-center justify-center shrink-0">
                <MapPin className="w-4 h-4 text-amber-600 dark:text-amber-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.summaryLocation")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {formData.city 
                    ? `${formData.city}, ${getLocalizedCountry(formData.country || business?.country || "US", locale)}`
                    : getLocalizedCountry(business?.country || formData.country || "US", locale)}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#8b5cf6]/10 flex items-center justify-center shrink-0">
                <Globe className="w-4 h-4 text-[#7c3aed] dark:text-[#a78bfa]" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.summaryTimezone")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {getLocalizedTimezone(business?.timezone || "UTC", locale)}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Documents Card */}
        <div className="afab-card p-6">
          <div className="flex flex-wrap items-center justify-between gap-3 mb-6">
            <div>
              <h3 className="afab-card-title">{t("businessProfile.documents") || "Document Uploads"}</h3>
              <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.documentsSubtitle") || "Manage your business verification files"}</p>
            </div>
            <Button variant="outline" size="sm" className="afab-btn-secondary">
              <Upload className="w-4 h-4" /> Upload
            </Button>
          </div>

          <div className="space-y-4">
            <div className="afab-inset flex items-center justify-between p-3.5 hover:border-gray-300 dark:hover:border-gray-700 transition-colors group">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-10 h-10 rounded-xl bg-red-500/10 flex items-center justify-center shrink-0">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-red-600 dark:text-red-400"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium text-gray-900 dark:text-white truncate">tax_certificate_2026.pdf</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">2.4 MB • Uploaded Jun 12, 2026</p>
                </div>
              </div>
              <Button variant="ghost" size="icon" className="afab-icon-btn h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
              </Button>
            </div>

            <div className="afab-inset flex items-center justify-between p-3.5 hover:border-gray-300 dark:hover:border-gray-700 transition-colors group">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-10 h-10 rounded-xl bg-red-500/10 flex items-center justify-center shrink-0">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-red-600 dark:text-red-400"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium text-gray-900 dark:text-white truncate">business_license.pdf</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">1.1 MB • Uploaded May 04, 2026</p>
                </div>
              </div>
              <Button variant="ghost" size="icon" className="afab-icon-btn h-8 w-8 opacity-0 group-hover:opacity-100 transition-opacity">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
