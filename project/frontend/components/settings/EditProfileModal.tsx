"use client";

import { useState, useRef } from "react";
import { useLocale } from "next-intl";
import { SettingsService } from "@/lib/api/settings";
import { AuthStore } from "@/lib/auth-store";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { AfabLoader } from "@/components/ui/afab-loader";
import {
  AlertCircle,
  Camera,
  Check,
  CheckCircle2,
  Lock,
  Mail,
  Phone,
  Sparkles,
  Trash2,
  User,
} from "lucide-react";

interface UserProfileData {
  firstName?: string;
  lastName?: string;
  email?: string;
  phoneNumber?: string | null;
  avatarUrl?: string | null;
  emailVerified?: boolean;
}

interface EditProfileModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  profile: UserProfileData | null;
  onSuccess: (updatedProfile: UserProfileData | null) => Promise<void> | void;
}

function resizeImageToDataUrl(file: File, maxSize = 256): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error("Failed to read image file."));
    reader.onload = () => {
      const img = new Image();
      img.onerror = () => reject(new Error("Invalid image file."));
      img.onload = () => {
        const canvas = document.createElement("canvas");
        const side = Math.min(img.width, img.height);
        const sx = (img.width - side) / 2;
        const sy = (img.height - side) / 2;
        const target = Math.min(maxSize, side);
        canvas.width = target;
        canvas.height = target;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          reject(new Error("Canvas not supported."));
          return;
        }
        ctx.drawImage(img, sx, sy, side, side, 0, 0, target, target);
        resolve(canvas.toDataURL("image/jpeg", 0.85));
      };
      img.src = reader.result as string;
    };
    reader.readAsDataURL(file);
  });
}

export function EditProfileModal({
  open,
  onOpenChange,
  profile,
  onSuccess,
}: EditProfileModalProps) {
  const locale = useLocale();
  const isArabic = locale === "ar";
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [firstName, setFirstName] = useState(profile?.firstName || "");
  const [lastName, setLastName] = useState(profile?.lastName || "");
  const [phoneNumber, setPhoneNumber] = useState(profile?.phoneNumber || "");
  const [avatarUrl, setAvatarUrl] = useState(profile?.avatarUrl || "");
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState("");

  const handleOpenChange = (nextOpen: boolean) => {
    if (nextOpen && profile) {
      setFirstName(profile.firstName || "");
      setLastName(profile.lastName || "");
      setPhoneNumber(profile.phoneNumber || "");
      setAvatarUrl(profile.avatarUrl || "");
      setError("");
    }
    onOpenChange(nextOpen);
  };

  const initials = `${firstName?.[0] || profile?.firstName?.[0] || ""}${
    lastName?.[0] || profile?.lastName?.[0] || ""
  }`.toUpperCase();

  const seed = encodeURIComponent(
    `${firstName || profile?.firstName || "User"} ${lastName || profile?.lastName || ""}`.trim()
  );
  const presetAvatars = [
    `https://api.dicebear.com/9.x/avataaars/svg?seed=${seed}`,
    `https://api.dicebear.com/9.x/notionists/svg?seed=${seed}`,
    `https://api.dicebear.com/9.x/lorelei/svg?seed=${seed}`,
    `https://api.dicebear.com/9.x/thumbs/svg?seed=${seed}`,
    `https://api.dicebear.com/9.x/initials/svg?seed=${seed}&backgroundColor=7c3aed`,
  ];

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      setError(isArabic ? "يرجى اختيار ملف صورة صالح." : "Please select a valid image file.");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setError(
        isArabic
          ? "حجم الصورة يتجاوز الحد الأقصى (5 ميجابايت)."
          : "Image file is too large (max 5 MB)."
      );
      return;
    }
    try {
      setError("");
      const compressed = await resizeImageToDataUrl(file, 256);
      setAvatarUrl(compressed);
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : isArabic
          ? "فشل معالجة الصورة."
          : "Failed to process image."
      );
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmedFirst = firstName.trim();
    const trimmedLast = lastName.trim();

    if (!trimmedFirst || !trimmedLast) {
      setError(
        isArabic
          ? "الاسم الأول واسم العائلة مطلوبان."
          : "First name and last name are required."
      );
      return;
    }

    setIsSaving(true);
    setError("");

    try {
      const updated = await SettingsService.updateProfile({
        firstName: trimmedFirst,
        lastName: trimmedLast,
        phoneNumber: phoneNumber.trim(),
        avatarUrl: avatarUrl.trim(),
      });

      AuthStore.updateUser({
        firstName: updated?.firstName ?? trimmedFirst,
        lastName: updated?.lastName ?? trimmedLast,
        avatarUrl: updated?.avatarUrl ?? (avatarUrl.trim() || undefined),
      });

      await onSuccess(updated);
      onOpenChange(false);
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : isArabic
          ? "فشل تحديث الملف الشخصي."
          : "Failed to update profile."
      );
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="flex flex-col gap-0 w-[calc(100%-2rem)] sm:max-w-[480px] rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-0 overflow-hidden shadow-2xl">
        <div className="w-full min-w-0 p-6 pb-4 pe-12 border-b border-gray-100 dark:border-gray-800/70">
          <DialogHeader>
            <DialogTitle className="afab-card-title flex items-center gap-2 text-lg">
              <User className="w-5 h-5 text-[var(--primary)]" />
              {isArabic ? "تعديل الملف الشخصي" : "Edit Profile"}
            </DialogTitle>
            <DialogDescription className="text-xs text-gray-500 dark:text-gray-400">
              {isArabic
                ? "قم بتحديث صورتك الشخصية واسمك ورقم هاتفك."
                : "Update your personal details, avatar photo, and contact info."}
            </DialogDescription>
          </DialogHeader>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-5">
          {error && (
            <div className="p-3.5 rounded-xl border border-red-500/25 bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400 flex items-start gap-2.5 text-xs">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {/* Avatar Editor */}
          <div className="flex flex-col sm:flex-row items-center gap-5 p-4 rounded-2xl bg-gray-50/80 dark:bg-[#080c18] border border-gray-200/70 dark:border-gray-800/60">
            <div className="relative group shrink-0">
              <Avatar className="w-20 h-20 border-2 border-[var(--primary)]/30 shadow-md bg-white dark:bg-[#0c101c]">
                <AvatarImage src={avatarUrl || undefined} />
                <AvatarFallback className="text-xl bg-[var(--primary)]/15 text-[var(--primary-hover)] dark:text-[var(--primary)] font-bold">
                  {initials || "U"}
                </AvatarFallback>
              </Avatar>
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="absolute inset-0 rounded-full bg-black/55 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white cursor-pointer"
                title={isArabic ? "تغيير الصورة" : "Change photo"}
              >
                <Camera className="w-5 h-5" />
              </button>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                onChange={handleFileSelect}
                className="hidden"
              />
            </div>

            <div className="flex-1 w-full space-y-2.5 text-center sm:text-start">
              <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => fileInputRef.current?.click()}
                  className="afab-btn-secondary h-8 text-xs px-3"
                >
                  <Camera className="w-3.5 h-3.5 me-1.5" />
                  {isArabic ? "رفع صورة" : "Upload Photo"}
                </Button>
                {avatarUrl && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setAvatarUrl("")}
                    className="h-8 text-xs px-2.5 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-500/10"
                  >
                    <Trash2 className="w-3.5 h-3.5 me-1" />
                    {isArabic ? "إزالة" : "Remove"}
                  </Button>
                )}
              </div>

              {/* Quick Avatar Presets */}
              <div className="space-y-1">
                <p className="text-[11px] text-gray-500 dark:text-gray-400 flex items-center justify-center sm:justify-start gap-1">
                  <Sparkles className="w-3 h-3 text-[var(--primary)]" />
                  {isArabic ? "أو اختر صورة رمزية جاهزة:" : "Or pick a preset avatar:"}
                </p>
                <div className="flex items-center justify-center sm:justify-start gap-2">
                  {presetAvatars.map((preset, idx) => {
                    const isSelected = avatarUrl === preset;
                    return (
                      <button
                        key={idx}
                        type="button"
                        onClick={() => setAvatarUrl(preset)}
                        className={`relative w-8 h-8 rounded-full overflow-hidden border-2 transition-all cursor-pointer ${
                          isSelected
                            ? "border-[var(--primary)] ring-2 ring-[var(--primary)]/30 scale-110"
                            : "border-gray-200 dark:border-gray-700 hover:border-[var(--primary)]/60"
                        }`}
                      >
                        <img src={preset} alt={`Avatar preset ${idx + 1}`} className="w-full h-full object-cover" />
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>

          {/* Name Inputs */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label className="afab-label">
                {isArabic ? "الاسم الأول" : "First Name"}
              </Label>
              <Input
                className="afab-input"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
                required
                maxLength={100}
                placeholder={isArabic ? "أدخل الاسم الأول" : "First name"}
              />
            </div>

            <div className="space-y-1.5">
              <Label className="afab-label">
                {isArabic ? "اسم العائلة" : "Last Name"}
              </Label>
              <Input
                className="afab-input"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
                required
                maxLength={100}
                placeholder={isArabic ? "أدخل اسم العائلة" : "Last name"}
              />
            </div>
          </div>

          {/* Phone Number */}
          <div className="space-y-1.5">
            <Label className="afab-label flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5 text-gray-400" />
              {isArabic ? "رقم الهاتف (اختياري)" : "Phone Number (Optional)"}
            </Label>
            <Input
              className="afab-input text-start"
              type="tel"
              dir="ltr"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              maxLength={50}
              placeholder="+216 20 000 000"
            />
          </div>

          {/* Read-Only Email */}
          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <Label className="afab-label mb-0 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-gray-400" />
                {isArabic ? "البريد الإلكتروني للحساب" : "Account Email"}
              </Label>
              {profile?.emailVerified && (
                <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-600 dark:text-emerald-400">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  {isArabic ? "موثق" : "Verified"}
                </span>
              )}
            </div>
            <div className="relative">
              <Input
                className="afab-input pe-9 text-start opacity-75 cursor-not-allowed"
                dir="ltr"
                value={profile?.email || ""}
                readOnly
                disabled
              />
              <Lock className="w-3.5 h-3.5 text-gray-400 absolute end-3 top-1/2 -translate-y-1/2" />
            </div>
          </div>

          {/* Actions */}
          <div className="pt-2 flex items-center justify-end gap-3 border-t border-gray-100 dark:border-gray-800/70">
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isSaving}
              className="afab-btn-secondary"
            >
              {isArabic ? "إلغاء" : "Cancel"}
            </Button>
            <Button
              type="submit"
              disabled={isSaving}
              className="afab-btn-primary min-w-[130px]"
            >
              {isSaving ? (
                <AfabLoader size="sm" />
              ) : (
                <>
                  <Check className="w-4 h-4 me-1.5" />
                  {isArabic ? "حفظ التغييرات" : "Save Profile"}
                </>
              )}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
