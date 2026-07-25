"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { AlertCircle, CheckCircle2, Upload, MapPin, Building2, Calendar, Globe, Building } from "lucide-react";
import Image from "next/image";

export function BusinessProfile({ business }: { business: any }) {
  const t = useTranslations("settings");

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
        <div>
          <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-1">
            {t("businessProfile.title")}
          </h2>
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            {t("businessProfile.subtitle")}
          </p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 p-6 space-y-8 shadow-sm">
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

          {/* Logo Upload */}
          <div>
            <Label className="mb-4 block font-semibold text-gray-900 dark:text-white">{t("businessProfile.logo")}</Label>
            <div className="flex items-center gap-6">
              <div className="relative w-24 h-24 rounded-xl border-2 border-dashed border-gray-200 dark:border-gray-600 overflow-hidden flex items-center justify-center bg-gray-50 dark:bg-gray-900/60">
                <Image src={formData.logoUrl} alt="Logo" fill className="object-cover" unoptimized />
              </div>
              <div className="space-y-2">
                <Button variant="outline" className="gap-2 border-gray-200 dark:border-gray-600">
                  <Upload className="w-4 h-4" />
                  {t("businessProfile.uploadDocument")}
                </Button>
                <p className="text-xs text-gray-500 dark:text-gray-400">{t("businessProfile.logoHelper")}</p>
              </div>
            </div>
          </div>

          <div className="border-t border-gray-200 dark:border-gray-600"></div>

          {/* Business Info */}
          <div className="space-y-6">
            <h3 className="font-semibold text-lg text-gray-900 dark:text-white">{t("businessProfile.businessInfo")}</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.businessName")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.industry")}</Label>
                <Select
                  value={formData.industry || "Software"}
                  onValueChange={(val) => setFormData({ ...formData, industry: val })}
                >
                  <SelectTrigger className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white">
                    <SelectValue placeholder="Select Industry" />
                  </SelectTrigger>
                  <SelectContent className="max-h-64 min-w-[300px] p-2 space-y-1 overflow-y-auto cursor-pointer border-gray-200 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-xl rounded-xl">
                    <SelectItem value="Software">Software & IT</SelectItem>
                    <SelectItem value="Retail">Retail & E-commerce</SelectItem>
                    <SelectItem value="Consulting">Consulting & Professional Services</SelectItem>
                    <SelectItem value="Finance">Finance & Investment</SelectItem>
                    <SelectItem value="Healthcare">Healthcare & Wellness</SelectItem>
                    <SelectItem value="Education">Education & Training</SelectItem>
                    <SelectItem value="Manufacturing">Manufacturing & Supply Chain</SelectItem>
                    <SelectItem value="Real Estate">Real Estate & Construction</SelectItem>
                    <SelectItem value="Other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.businessEmail")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  type="email"
                  value={formData.businessEmail}
                  onChange={(e) => setFormData({ ...formData, businessEmail: e.target.value })}
                  placeholder="contact@example.com"
                />
              </div>
              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.phoneNumber")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.phoneNumber}
                  onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                  placeholder="+1 (555) 000-0000"
                />
              </div>

              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.website")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.website}
                  onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                  placeholder="https://example.com"
                />
              </div>
              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.taxId")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.taxId}
                  onChange={(e) => setFormData({ ...formData, taxId: e.target.value })}
                  placeholder="Optional"
                />
              </div>

              <div className="space-y-2 md:col-span-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.address")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.addressLine}
                  onChange={(e) => setFormData({ ...formData, addressLine: e.target.value })}
                  placeholder="123 Business St, Suite 100"
                />
              </div>

              <div className="space-y-2">
                <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.city")}</Label>
                <Input
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                  value={formData.city}
                  onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                />
              </div>
              <div className="space-y-2 grid grid-cols-2 gap-4">
                <div>
                  <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.state")}</Label>
                  <Input
                    className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                    value={formData.state}
                    onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                  />
                </div>
                <div>
                  <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.postalCode")}</Label>
                  <Input
                    className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6]"
                    value={formData.postalCode}
                    onChange={(e) => setFormData({ ...formData, postalCode: e.target.value })}
                  />
                </div>
              </div>

              <div className="space-y-2 md:col-span-2">
                <div className="flex items-center justify-between">
                  <Label className="font-semibold text-gray-700 dark:text-gray-300">{t("businessProfile.description")}</Label>
                  <span className="text-xs text-gray-500">
                    {t("businessProfile.descriptionCounter", { count: formData.description.length })}
                  </span>
                </div>
                <Textarea
                  className="border-gray-200 dark:border-gray-600 dark:bg-gray-900/60 dark:text-white focus:border-[#8b5cf6] resize-none"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value.substring(0, 500) })}
                  placeholder="Briefly describe your business..."
                  rows={4}
                />
              </div>
            </div>
          </div>

          <div className="border-t border-gray-200 dark:border-gray-600 pt-6 flex justify-end gap-4">
            <Button variant="outline" className="min-w-[120px] border-gray-200 dark:border-gray-600">Cancel</Button>
            <Button
              onClick={handleSave}
              disabled={isLoading}
              className="bg-[#8b5cf6] hover:bg-[#7c3aed] text-white min-w-[140px]"
            >
              {isLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
            </Button>
          </div>
        </div>
      </div>

      {/* Right Sidebar Content */}
      <div className="space-y-6">
        {/* Business Summary Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 p-6 shadow-sm">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{t("businessProfile.summary")}</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-6">{t("businessProfile.summarySubtitle")}</p>

          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center shrink-0">
                <Building2 className="w-4 h-4 text-blue-600 dark:text-blue-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500">{t("businessProfile.summaryName")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{formData.name}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-purple-50 dark:bg-purple-900/20 flex items-center justify-center shrink-0">
                <Building className="w-4 h-4 text-purple-600 dark:text-purple-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500">{t("businessProfile.summaryIndustry")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{formData.industry || "Software & IT"}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-green-50 dark:bg-green-900/20 flex items-center justify-center shrink-0">
                <Calendar className="w-4 h-4 text-green-600 dark:text-green-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500">{t("businessProfile.summaryMemberSince")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{memberSince}</p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-orange-50 dark:bg-orange-900/20 flex items-center justify-center shrink-0">
                <MapPin className="w-4 h-4 text-orange-600 dark:text-orange-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500">{t("businessProfile.summaryLocation")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                  {formData.city ? `${formData.city}, ${formData.country || "USA"}` : business?.country || "USA"}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-full bg-indigo-50 dark:bg-indigo-900/20 flex items-center justify-center shrink-0">
                <Globe className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-500">{t("businessProfile.summaryTimezone")}</p>
                <p className="text-sm font-medium text-gray-900 dark:text-white truncate">{business?.timezone || "UTC"}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Documents Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-600 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="font-semibold text-gray-900 dark:text-white text-lg">{t("businessProfile.documents") || "Document Uploads"}</h3>
              <p className="text-xs text-gray-500">{t("businessProfile.documentsSubtitle") || "Manage your business verification files"}</p>
            </div>
            <Button variant="outline" size="sm" className="gap-2 border-gray-200 dark:border-gray-600">
              <Upload className="w-4 h-4" /> Upload
            </Button>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-600 rounded-lg hover:border-gray-300 transition-colors group">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-red-50 dark:bg-red-900/20 flex items-center justify-center shrink-0">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-red-500"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">tax_certificate_2026.pdf</p>
                  <p className="text-xs text-gray-500">2.4 MB • Uploaded Jun 12, 2026</p>
                </div>
              </div>
              <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
              </Button>
            </div>

            <div className="flex items-center justify-between p-3 border border-gray-200 dark:border-gray-600 rounded-lg hover:border-gray-300 transition-colors group">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-red-50 dark:bg-red-900/20 flex items-center justify-center shrink-0">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-red-500"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900 dark:text-white">business_license.pdf</p>
                  <p className="text-xs text-gray-500">1.1 MB • Uploaded May 04, 2026</p>
                </div>
              </div>
              <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="1"></circle><circle cx="12" cy="5" r="1"></circle><circle cx="12" cy="19" r="1"></circle></svg>
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
