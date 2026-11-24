"use client";

import { useState, useEffect } from "react";
import { useTranslations, useLocale } from "next-intl";
import { useTheme } from "next-themes";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import {
  Sun,
  Moon,
  Check,
  RotateCcw,
  Sparkles,
  Eye,
  Sliders,
  Palette,
  TrendingUp,
  Maximize2,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  Type,
  ALargeSmall,
} from "lucide-react";
import {
  AppearanceSettings as IAppearanceSettings,
  ThemeMode,
  AccentPresetId,
  RadiusPresetId,
  DensityId,
  FontFamilyId,
  FontSizeId,
  ACCENT_PRESETS,
  RADIUS_PRESETS,
  FONT_FAMILY_PRESETS,
  FONT_SIZE_PRESETS,
  DEFAULT_APPEARANCE_SETTINGS,
  getStoredAppearance,
  applyAppearance,
  resetAppearance,
  resolveAccentColors,
} from "@/lib/appearance";
import { SettingsService } from "@/lib/api/settings";

interface AppearanceSettingsProps {
  profile?: any;
  onRefresh?: () => Promise<void>;
}

export function AppearanceSettings({ profile, onRefresh }: AppearanceSettingsProps) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isArabic = locale === "ar";
  const { theme, setTheme } = useTheme();

  // Load initial settings
  const [settings, setSettings] = useState<IAppearanceSettings>(DEFAULT_APPEARANCE_SETTINGS);
  const [mounted, setMounted] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [customHexInput, setCustomHexInput] = useState("#8b5cf6");
  const [previewTab, setPreviewTab] = useState<"day" | "week" | "month">("month");

  // Synchronize on mount
  useEffect(() => {
    const stored = getStoredAppearance();
    setSettings(stored);
    setCustomHexInput(stored.customPrimaryColor || "#8b5cf6");
    setMounted(true);
  }, []);

  // Update theme mode if next-themes changes out-of-band
  useEffect(() => {
    if (mounted && theme && (theme === "light" || theme === "dark" || theme === "system")) {
      if (theme !== settings.themeMode) {
        setSettings((prev) => ({ ...prev, themeMode: theme as ThemeMode }));
      }
    }
  }, [theme, mounted]);

  // Handler to update setting and immediately apply live
  const updateSetting = <K extends keyof IAppearanceSettings>(
    key: K,
    value: IAppearanceSettings[K]
  ) => {
    const nextSettings: IAppearanceSettings = {
      ...settings,
      [key]: value,
    };
    setSettings(nextSettings);
    applyAppearance(nextSettings, setTheme);
  };

  // Theme mode selection
  const handleThemeModeChange = (mode: ThemeMode) => {
    updateSetting("themeMode", mode);
  };

  // Accent color preset selection
  const handleAccentPresetChange = (presetId: AccentPresetId) => {
    const nextSettings: IAppearanceSettings = {
      ...settings,
      accentPreset: presetId,
    };
    if (presetId !== "custom") {
      const preset = ACCENT_PRESETS.find((p) => p.id === presetId);
      if (preset) {
        nextSettings.customPrimaryColor = preset.primary;
        setCustomHexInput(preset.primary);
      }
    }
    setSettings(nextSettings);
    applyAppearance(nextSettings, setTheme);
  };

  // Custom hex color selection
  const handleCustomHexChange = (hex: string) => {
    setCustomHexInput(hex);
    if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
      const nextSettings: IAppearanceSettings = {
        ...settings,
        accentPreset: "custom",
        customPrimaryColor: hex,
      };
      setSettings(nextSettings);
      applyAppearance(nextSettings, setTheme);
    }
  };

  // Border radius selection (Pill option removed as requested)
  const handleRadiusChange = (radiusId: RadiusPresetId) => {
    updateSetting("radius", radiusId);
  };

  // Font family selection (Visually distinct styles)
  const handleFontFamilyChange = (fontId: FontFamilyId) => {
    updateSetting("fontFamily", fontId);
  };

  // Font size selection
  const handleFontSizeChange = (sizeId: FontSizeId) => {
    updateSetting("fontSize", sizeId);
  };

  // Density change
  const handleDensityChange = (densityId: DensityId) => {
    updateSetting("density", densityId);
  };

  // Reset to default settings
  const handleReset = () => {
    const defaultSettings = resetAppearance(setTheme);
    setSettings(defaultSettings);
    setCustomHexInput(defaultSettings.customPrimaryColor);
    setSuccessMessage(t("appearance.resetSuccess"));
    setTimeout(() => setSuccessMessage(null), 4000);
  };

  // Save preferences
  const handleSave = async () => {
    setIsSaving(true);
    setErrorMessage(null);
    try {
      applyAppearance(settings, setTheme);

      // Persist to user profile backend if available
      try {
        await SettingsService.updateProfile({
          appearanceSettings: settings,
          compactMode: settings.density === "compact",
        });
        if (onRefresh) {
          await onRefresh();
        }
      } catch (backendErr) {
        console.warn("Backend profile appearance sync optional notice:", backendErr);
      }

      setSuccessMessage(t("appearance.saveSuccess"));
      setTimeout(() => setSuccessMessage(null), 5000);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to save appearance settings"
      );
    } finally {
      setIsSaving(false);
    }
  };

  const resolvedColors = resolveAccentColors(settings.accentPreset, settings.customPrimaryColor);
  const currentFont = FONT_FAMILY_PRESETS.find((f) => f.id === settings.fontFamily) || FONT_FAMILY_PRESETS[0];
  const currentSize = FONT_SIZE_PRESETS.find((s) => s.id === settings.fontSize) || FONT_SIZE_PRESETS[1];

  return (
    <div className="space-y-6 sm:space-y-8">
      {/* ── Page Header ── */}
      <PageHeader
        title={t("appearance.title")}
        subtitle={t("appearance.subtitle")}
        actions={
          <div className="flex items-center gap-2 sm:gap-2.5 w-full sm:w-auto">
            <Button
              variant="outline"
              size="sm"
              onClick={handleReset}
              className="gap-1.5 sm:gap-2 text-xs font-semibold rounded-xl flex-1 sm:flex-initial justify-center"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>{t("appearance.resetDefaults")}</span>
            </Button>
            <Button
              size="sm"
              onClick={handleSave}
              disabled={isSaving}
              className="afab-btn-primary gap-1.5 sm:gap-2 flex-1 sm:flex-initial justify-center"
            >
              {isSaving ? (
                <div className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <Check className="w-3.5 h-3.5" />
              )}
              <span>{t("appearance.savePreferences")}</span>
            </Button>
          </div>
        }
      />

      {/* ── Notification Banners ── */}
      {successMessage && (
        <div className="flex items-center gap-3 rounded-2xl border border-emerald-500/20 bg-emerald-500/10 p-3.5 sm:p-4 text-xs sm:text-sm font-medium text-emerald-600 dark:text-emerald-400 animate-in fade-in slide-in-from-top-2 duration-200">
          <CheckCircle2 className="w-4 h-4 sm:w-5 sm:h-5 shrink-0" />
          <span>{successMessage}</span>
        </div>
      )}

      {errorMessage && (
        <div className="flex items-center gap-3 rounded-2xl border border-red-500/20 bg-red-500/10 p-3.5 sm:p-4 text-xs sm:text-sm font-medium text-red-600 dark:text-red-400 animate-in fade-in slide-in-from-top-2 duration-200">
          <AlertCircle className="w-4 h-4 sm:w-5 sm:h-5 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      {/* ── Main Responsive Grid (Desktop 2-Col 7/5, Tablet/Mobile Stacked) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-8 items-start">
        
        {/* Left Column: Form Controls (7 cols on Desktop, 12 cols on Tablet/Mobile) */}
        <div className="lg:col-span-7 space-y-6 sm:space-y-8">

          {/* 1. Theme Mode Section */}
          <div className="afab-card p-4 sm:p-6">
            <div className="mb-4 sm:mb-5">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Sun className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.themeMode.title")}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("appearance.themeMode.subtitle")}
              </p>
            </div>

            <div className="grid grid-cols-3 gap-2 sm:gap-3">
              {/* Light Mode Card */}
              <button
                type="button"
                onClick={() => handleThemeModeChange("light")}
                className={`relative flex flex-col rounded-2xl border p-2.5 sm:p-4 text-start transition-all cursor-pointer ${
                  settings.themeMode === "light"
                    ? "border-[var(--primary)] bg-[var(--primary)]/5 shadow-md shadow-[var(--primary)]/10 ring-2 ring-[var(--primary)]"
                    : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                }`}
              >
                {settings.themeMode === "light" && (
                  <span className="absolute top-2 sm:top-3 end-2 sm:end-3 flex h-4 w-4 sm:h-5 sm:w-5 items-center justify-center rounded-full bg-[var(--primary)] text-white shadow-sm">
                    <Check className="w-2.5 h-2.5 sm:w-3 sm:h-3 stroke-[3]" />
                  </span>
                )}
                {/* Visual miniature */}
                <div className="mb-2 sm:mb-3.5 flex h-14 sm:h-20 w-full items-center justify-center rounded-xl border border-gray-200 bg-[#f8f9fb] p-2 sm:p-2.5">
                  <div className="w-full h-full rounded-lg bg-white border border-gray-200 shadow-xs p-1.5 sm:p-2 flex flex-col justify-between">
                    <div className="flex items-center gap-1.5">
                      <div className="w-2 h-2 rounded-full bg-amber-400" />
                      <div className="w-6 sm:w-8 h-1.5 rounded-full bg-gray-200" />
                    </div>
                    <div className="space-y-1">
                      <div className="w-full h-1 sm:h-1.5 rounded bg-gray-100" />
                      <div className="w-2/3 h-1 sm:h-1.5 rounded bg-[var(--primary)]" />
                    </div>
                  </div>
                </div>
                <span className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white truncate">
                  {t("appearance.themeMode.light")}
                </span>
                <span className="text-[10px] sm:text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug line-clamp-2">
                  {t("appearance.themeMode.lightDesc")}
                </span>
              </button>

              {/* Dark Mode Card */}
              <button
                type="button"
                onClick={() => handleThemeModeChange("dark")}
                className={`relative flex flex-col rounded-2xl border p-2.5 sm:p-4 text-start transition-all cursor-pointer ${
                  settings.themeMode === "dark"
                    ? "border-[var(--primary)] bg-[var(--primary)]/5 shadow-md shadow-[var(--primary)]/10 ring-2 ring-[var(--primary)]"
                    : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                }`}
              >
                {settings.themeMode === "dark" && (
                  <span className="absolute top-2 sm:top-3 end-2 sm:end-3 flex h-4 w-4 sm:h-5 sm:w-5 items-center justify-center rounded-full bg-[var(--primary)] text-white shadow-sm">
                    <Check className="w-2.5 h-2.5 sm:w-3 sm:h-3 stroke-[3]" />
                  </span>
                )}
                {/* Visual miniature */}
                <div className="mb-2 sm:mb-3.5 flex h-14 sm:h-20 w-full items-center justify-center rounded-xl border border-gray-800 bg-[#060813] p-2 sm:p-2.5">
                  <div className="w-full h-full rounded-lg bg-[#0c101c] border border-gray-800 shadow-xs p-1.5 sm:p-2 flex flex-col justify-between">
                    <div className="flex items-center gap-1.5">
                      <div className="w-2 h-2 rounded-full bg-indigo-400" />
                      <div className="w-6 sm:w-8 h-1.5 rounded-full bg-gray-700" />
                    </div>
                    <div className="space-y-1">
                      <div className="w-full h-1 sm:h-1.5 rounded bg-gray-800" />
                      <div className="w-2/3 h-1 sm:h-1.5 rounded bg-[var(--primary)]" />
                    </div>
                  </div>
                </div>
                <span className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white truncate">
                  {t("appearance.themeMode.dark")}
                </span>
                <span className="text-[10px] sm:text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug line-clamp-2">
                  {t("appearance.themeMode.darkDesc")}
                </span>
              </button>

              {/* System Mode Card */}
              <button
                type="button"
                onClick={() => handleThemeModeChange("system")}
                className={`relative flex flex-col rounded-2xl border p-2.5 sm:p-4 text-start transition-all cursor-pointer ${
                  settings.themeMode === "system"
                    ? "border-[var(--primary)] bg-[var(--primary)]/5 shadow-md shadow-[var(--primary)]/10 ring-2 ring-[var(--primary)]"
                    : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                }`}
              >
                {settings.themeMode === "system" && (
                  <span className="absolute top-2 sm:top-3 end-2 sm:end-3 flex h-4 w-4 sm:h-5 sm:w-5 items-center justify-center rounded-full bg-[var(--primary)] text-white shadow-sm">
                    <Check className="w-2.5 h-2.5 sm:w-3 sm:h-3 stroke-[3]" />
                  </span>
                )}
                {/* Visual miniature: half light, half dark */}
                <div className="mb-2 sm:mb-3.5 flex h-14 sm:h-20 w-full items-center justify-center rounded-xl border border-gray-300 dark:border-gray-800 overflow-hidden">
                  <div className="w-1/2 h-full bg-[#f8f9fb] p-1.5 sm:p-2 flex flex-col justify-center border-e border-gray-200 dark:border-gray-800">
                    <div className="w-5 sm:w-6 h-1 sm:h-1.5 rounded-full bg-gray-300 mb-1" />
                    <div className="w-3 sm:w-4 h-1 sm:h-1.5 rounded-full bg-[var(--primary)]" />
                  </div>
                  <div className="w-1/2 h-full bg-[#060813] p-1.5 sm:p-2 flex flex-col justify-center">
                    <div className="w-5 sm:w-6 h-1 sm:h-1.5 rounded-full bg-gray-700 mb-1" />
                    <div className="w-3 sm:w-4 h-1 sm:h-1.5 rounded-full bg-[var(--primary)]" />
                  </div>
                </div>
                <span className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white truncate">
                  {t("appearance.themeMode.system")}
                </span>
                <span className="text-[10px] sm:text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug line-clamp-2">
                  {t("appearance.themeMode.systemDesc")}
                </span>
              </button>
            </div>
          </div>

          {/* 2. Brand Accent Color Section */}
          <div className="afab-card p-4 sm:p-6">
            <div className="mb-4 sm:mb-5">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Palette className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.accentColor.title")}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("appearance.accentColor.subtitle")}
              </p>
            </div>

            {/* Presets Swatches */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
              {ACCENT_PRESETS.map((preset) => {
                const isSelected = settings.accentPreset === preset.id;
                return (
                  <button
                    key={preset.id}
                    type="button"
                    onClick={() => handleAccentPresetChange(preset.id)}
                    className={`relative flex items-center gap-2.5 sm:gap-3 p-2.5 sm:p-3 rounded-2xl border text-start transition-all cursor-pointer ${
                      isSelected
                        ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                        : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                    }`}
                  >
                    <div
                      className="w-6 h-6 sm:w-7 sm:h-7 rounded-full shrink-0 flex items-center justify-center text-white shadow-xs"
                      style={{ backgroundColor: preset.primary }}
                    >
                      {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-[11px] sm:text-xs font-bold text-gray-900 dark:text-white truncate">
                        {isArabic ? preset.nameAr : preset.nameEn}
                      </p>
                      <span className="text-[9px] sm:text-[10px] text-gray-400 font-mono block truncate">
                        {preset.primary}
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Custom Hex Color Picker */}
            <div className="mt-4 sm:mt-5 pt-4 sm:pt-5 border-t border-gray-100 dark:border-gray-800/80">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <span className="text-xs font-bold text-gray-900 dark:text-white">
                    {t("appearance.accentColor.custom")}
                  </span>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">
                    {isArabic
                      ? "أدخل كود اللون السداسي (Hex) للعلامة التجارية لشركتك"
                      : "Input custom brand hex code (e.g. #8b5cf6, #0ea5e9)"}
                  </p>
                </div>

                <div className="flex items-center gap-2 w-full sm:w-auto">
                  <div className="relative flex items-center justify-center shrink-0">
                    <input
                      type="color"
                      id="customColorPicker"
                      value={
                        /^#[0-9A-Fa-f]{6}$/.test(customHexInput)
                          ? customHexInput
                          : "#8b5cf6"
                      }
                      onChange={(e) => handleCustomHexChange(e.target.value)}
                      className="opacity-0 absolute inset-0 w-full h-full cursor-pointer"
                    />
                    <div
                      className="w-8 h-8 sm:w-9 sm:h-9 rounded-xl border border-gray-300 dark:border-gray-700 shadow-sm cursor-pointer transition-transform hover:scale-105"
                      style={{
                        backgroundColor: /^#[0-9A-Fa-f]{6}$/.test(customHexInput)
                          ? customHexInput
                          : "#8b5cf6",
                      }}
                      title={t("appearance.accentColor.customColorLabel")}
                    />
                  </div>

                  <div className="relative flex-1 sm:w-32">
                    <Input
                      type="text"
                      maxLength={7}
                      value={customHexInput}
                      onChange={(e) => handleCustomHexChange(e.target.value)}
                      placeholder={t("appearance.accentColor.customPlaceholder")}
                      className="font-mono text-xs uppercase"
                    />
                  </div>

                  {settings.accentPreset === "custom" && (
                    <span className="afab-badge-primary text-[10px] sm:text-[11px] px-2 py-1 shrink-0">
                      {isArabic ? "مفعل" : "Active"}
                    </span>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* 3. Typography & Distinct Font Personalities Section */}
          <div className="afab-card p-4 sm:p-6">
            <div className="mb-4 sm:mb-5">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Type className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.fontFamily.title")}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("appearance.fontFamily.subtitle")}
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 sm:gap-3">
              {FONT_FAMILY_PRESETS.map((font) => {
                const isSelected = settings.fontFamily === font.id;
                return (
                  <button
                    key={font.id}
                    type="button"
                    onClick={() => handleFontFamilyChange(font.id)}
                    className={`flex flex-col p-3.5 sm:p-4 rounded-2xl border text-start transition-all cursor-pointer ${
                      isSelected
                        ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                        : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                    }`}
                  >
                    <div className="flex items-center justify-between w-full mb-1">
                      <div className="flex items-center gap-2 min-w-0">
                        <span
                          className="text-xs font-bold text-gray-900 dark:text-white truncate"
                          style={{ fontFamily: font.cssFamilyHeading }}
                        >
                          {isArabic ? font.nameAr : font.nameEn}
                        </span>
                      </div>
                      {isSelected && (
                        <span className="flex h-4 w-4 items-center justify-center rounded-full bg-[var(--primary)] text-white shrink-0">
                          <Check className="w-2.5 h-2.5 stroke-[3]" />
                        </span>
                      )}
                    </div>

                    <div className="mb-2">
                      <span className="inline-block rounded-md bg-gray-100 dark:bg-white/5 border border-gray-200/60 dark:border-gray-800 px-2 py-0.5 text-[9px] sm:text-[10px] font-semibold text-gray-600 dark:text-gray-300">
                        {isArabic ? font.categoryAr : font.categoryEn}
                      </span>
                    </div>

                    <p className="text-[10px] sm:text-[11px] text-gray-500 dark:text-gray-400 leading-snug mb-3 line-clamp-2">
                      {isArabic ? font.descAr : font.descEn}
                    </p>

                    {/* Live rendered typography preview box demonstrating exact visual style */}
                    <div
                      className="mt-auto rounded-xl border border-gray-200/80 dark:border-gray-800 bg-gray-50/80 dark:bg-[#0c101c] p-2 sm:p-2.5 text-start shadow-2xs"
                      style={{ fontFamily: font.cssFamilyBody }}
                    >
                      <p className="text-[11px] sm:text-xs font-bold text-gray-900 dark:text-gray-100 truncate">
                        {font.sampleEn}
                      </p>
                      <p className="text-[10px] sm:text-[11px] text-gray-700 dark:text-gray-300 mt-1 truncate font-medium">
                        {font.sampleAr}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 4. Writing & Interface Font Size Section */}
          <div className="afab-card p-4 sm:p-6">
            <div className="mb-4 sm:mb-5">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <ALargeSmall className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.fontSize.title")}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("appearance.fontSize.subtitle")}
              </p>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 sm:gap-3">
              {FONT_SIZE_PRESETS.map((size) => {
                const isSelected = settings.fontSize === size.id;
                return (
                  <button
                    key={size.id}
                    type="button"
                    onClick={() => handleFontSizeChange(size.id)}
                    className={`flex flex-col items-center justify-between p-3 sm:p-4 rounded-2xl border text-center transition-all cursor-pointer min-h-[110px] sm:min-h-[130px] ${
                      isSelected
                        ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                        : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                    }`}
                  >
                    {/* Visual scaled letter preview */}
                    <div
                      className="flex items-center justify-center font-bold text-gray-900 dark:text-white"
                      style={{ fontSize: `${Math.min(size.basePx * 1.4, 28)}px` }}
                    >
                      Aa
                    </div>

                    <div className="w-full mt-2">
                      <div className="flex items-center justify-center gap-1">
                        <span className="text-[11px] sm:text-xs font-bold text-gray-900 dark:text-white truncate">
                          {isArabic ? size.nameAr : size.nameEn}
                        </span>
                        {isSelected && (
                          <Check className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-[var(--primary)] stroke-[3]" />
                        )}
                      </div>
                      <span className="text-[9px] sm:text-[10px] text-gray-400 mt-0.5 block font-mono">
                        {size.scalePercent} ({size.basePx}px)
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 5. Corner Rounding (Border Radius) — 3-Tier Grid */}
          <div className="afab-card p-4 sm:p-6">
            <div className="mb-4 sm:mb-5">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Maximize2 className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.borderRadius.title")}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {t("appearance.borderRadius.subtitle")}
              </p>
            </div>

            <div className="grid grid-cols-3 gap-2 sm:gap-3">
              {RADIUS_PRESETS.map((radius) => {
                const isSelected = settings.radius === radius.id;
                return (
                  <button
                    key={radius.id}
                    type="button"
                    onClick={() => handleRadiusChange(radius.id)}
                    className={`flex flex-col items-center justify-center p-2.5 sm:p-4 rounded-2xl border text-center transition-all cursor-pointer ${
                      isSelected
                        ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                        : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                    }`}
                  >
                    {/* Visual corner illustration */}
                    <div
                      className="w-8 h-8 sm:w-10 sm:h-10 mb-1.5 sm:mb-2 border-2 border-[var(--primary)] bg-[var(--primary)]/10"
                      style={{ borderRadius: radius.valueRem }}
                    />
                    <span className="text-[11px] sm:text-xs font-bold text-gray-900 dark:text-white truncate">
                      {isArabic ? radius.nameAr : radius.nameEn}
                    </span>
                    <span className="text-[9px] sm:text-[10px] text-gray-400 mt-0.5">
                      {radius.pxValue}px
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* 6. Interface Density & Visual Effects */}
          <div className="afab-card p-4 sm:p-6 space-y-5 sm:space-y-6">
            {/* Density */}
            <div>
              <div className="mb-3.5 sm:mb-4">
                <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                  <Sliders className="w-4 h-4 text-[var(--primary)]" />
                  {t("appearance.density.title")}
                </h2>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {t("appearance.density.subtitle")}
                </p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 sm:gap-3">
                {/* Comfortable */}
                <button
                  type="button"
                  onClick={() => handleDensityChange("comfortable")}
                  className={`p-3.5 sm:p-4 rounded-2xl border text-start transition-all cursor-pointer ${
                    settings.density === "comfortable"
                      ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                      : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                  }`}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white">
                      {t("appearance.density.comfortable")}
                    </span>
                    {settings.density === "comfortable" && (
                      <Check className="w-4 h-4 text-[var(--primary)] stroke-[3]" />
                    )}
                  </div>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 leading-snug">
                    {t("appearance.density.comfortableDesc")}
                  </p>
                </button>

                {/* Compact */}
                <button
                  type="button"
                  onClick={() => handleDensityChange("compact")}
                  className={`p-3.5 sm:p-4 rounded-2xl border text-start transition-all cursor-pointer ${
                    settings.density === "compact"
                      ? "border-[var(--primary)] bg-[var(--primary)]/5 ring-2 ring-[var(--primary)] shadow-sm"
                      : "border-gray-200 bg-white hover:border-gray-300 dark:border-gray-800 dark:bg-[#080c18] dark:hover:border-gray-700"
                  }`}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white">
                      {t("appearance.density.compact")}
                    </span>
                    {settings.density === "compact" && (
                      <Check className="w-4 h-4 text-[var(--primary)] stroke-[3]" />
                    )}
                  </div>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 leading-snug">
                    {t("appearance.density.compactDesc")}
                  </p>
                </button>
              </div>
            </div>

            {/* Micro-effects Toggles */}
            <div className="pt-4 sm:pt-5 border-t border-gray-100 dark:border-gray-800/80 space-y-4">
              <h2 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-[var(--primary)]" />
                {t("appearance.visualEffects.title")}
              </h2>

              {/* Ambient Glow */}
              <div className="flex items-center justify-between gap-3 sm:gap-4">
                <div className="min-w-0">
                  <Label htmlFor="ambient-glow" className="text-xs font-bold text-gray-900 dark:text-white cursor-pointer block">
                    {t("appearance.visualEffects.ambientGlow")}
                  </Label>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                    {t("appearance.visualEffects.ambientGlowDesc")}
                  </p>
                </div>
                <Switch
                  id="ambient-glow"
                  checked={settings.enableGlow}
                  onCheckedChange={(checked) => updateSetting("enableGlow", checked)}
                  className="shrink-0"
                />
              </div>

              {/* Smooth Transitions */}
              <div className="flex items-center justify-between gap-3 sm:gap-4">
                <div className="min-w-0">
                  <Label htmlFor="smooth-transitions" className="text-xs font-bold text-gray-900 dark:text-white cursor-pointer block">
                    {t("appearance.visualEffects.smoothTransitions")}
                  </Label>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400 mt-0.5 leading-snug">
                    {t("appearance.visualEffects.smoothTransitionsDesc")}
                  </p>
                </div>
                <Switch
                  id="smooth-transitions"
                  checked={settings.smoothTransitions}
                  onCheckedChange={(checked) => updateSetting("smoothTransitions", checked)}
                  className="shrink-0"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Sticky Live Interactive Preview (5 cols on Desktop, bottom on Tablet/Mobile) */}
        <div id="appearance-live-preview" className="lg:col-span-5 lg:sticky lg:top-6 space-y-4 w-full">
          <div className="afab-card p-4 sm:p-6 shadow-xl border-gray-200 dark:border-gray-800">
            <div className="flex items-center justify-between mb-4 pb-3 border-b border-gray-100 dark:border-gray-800/80">
              <div className="flex items-center gap-2">
                <Eye className="w-4 h-4 text-[var(--primary)]" />
                <h3 className="text-sm font-bold text-gray-900 dark:text-white">
                  {t("appearance.livePreview.title")}
                </h3>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="afab-badge-primary text-[9px] sm:text-[10px] uppercase tracking-wider px-2 py-0.5">
                  {isArabic ? currentFont.categoryAr : currentFont.categoryEn}
                </span>
                <span className="text-[9px] sm:text-[10px] font-mono text-gray-400 bg-gray-100 dark:bg-white/5 px-1.5 py-0.5 rounded">
                  {currentSize.basePx}px
                </span>
              </div>
            </div>

            <p className="text-xs text-gray-500 dark:text-gray-400 mb-4 sm:mb-5">
              {t("appearance.livePreview.subtitle")}
            </p>

            {/* Sandbox Mockup Card */}
            <div className="rounded-2xl border border-gray-200 dark:border-gray-800/80 bg-gray-50/50 dark:bg-[#080c18] p-3.5 sm:p-4 space-y-3.5 sm:space-y-4">
              
              {/* Header with verified badge */}
              <div className="flex items-center justify-between gap-2">
                <div>
                  <span className="text-[10px] sm:text-[11px] font-semibold text-gray-400 uppercase tracking-wider">
                    {t("appearance.livePreview.netWorth")}
                  </span>
                  <div className="text-lg sm:text-xl font-bold text-gray-900 dark:text-white font-mono mt-0.5">
                    $124,850.00
                  </div>
                </div>
                <div className="flex items-center gap-1 sm:gap-1.5 rounded-full bg-emerald-500/10 px-2 sm:px-2.5 py-0.5 sm:py-1 text-[11px] sm:text-xs font-bold text-emerald-600 dark:text-emerald-400 shrink-0">
                  <TrendingUp className="w-3 h-3 sm:w-3.5 sm:h-3.5" />
                  <span>{t("appearance.livePreview.monthlyGrowth")}</span>
                </div>
              </div>

              {/* Dynamic Sparkline SVG colored with live accent */}
              <div className="h-14 sm:h-16 w-full flex items-end pt-1 sm:pt-2">
                <svg className="w-full h-full overflow-visible" viewBox="0 0 240 60">
                  <defs>
                    <linearGradient id="previewSparklineGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="var(--primary)" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="var(--primary)" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>
                  <path
                    d="M0 45 Q 30 25, 60 38 T 120 20 T 180 32 T 240 10 L 240 60 L 0 60 Z"
                    fill="url(#previewSparklineGrad)"
                  />
                  <path
                    d="M0 45 Q 30 25, 60 38 T 120 20 T 180 32 T 240 10"
                    fill="none"
                    stroke="var(--primary)"
                    strokeWidth="3"
                    strokeLinecap="round"
                  />
                  <circle cx="240" cy="10" r="4" fill="var(--primary)" />
                </svg>
              </div>

              {/* Segmented Period Tabs */}
              <div className="afab-segmented">
                {(["day", "week", "month"] as const).map((period) => (
                  <button
                    key={period}
                    type="button"
                    onClick={() => setPreviewTab(period)}
                    className={`afab-segment flex-1 justify-center text-xs ${
                      previewTab === period ? "afab-segment-active" : ""
                    }`}
                  >
                    {t(`appearance.livePreview.${period}`)}
                  </button>
                ))}
              </div>

              {/* Interactive Form Input */}
              <div>
                <label className="afab-label text-[11px] sm:text-xs">
                  {t("appearance.livePreview.inputLabel")}
                </label>
                <input
                  type="text"
                  placeholder={t("appearance.livePreview.inputPlaceholder")}
                  defaultValue="AFAB Intelligence Suite"
                  className="afab-input text-xs"
                />
              </div>

              {/* Themed Buttons */}
              <div className="flex flex-col sm:flex-row gap-2 pt-1">
                <button
                  type="button"
                  className="afab-btn-primary flex-1 py-2 sm:py-2.5 justify-center text-xs"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>{t("appearance.livePreview.primaryBtn")}</span>
                </button>
                <button
                  type="button"
                  className="afab-btn-soft flex-1 py-2 sm:py-2.5 justify-center text-xs"
                >
                  <span>{t("appearance.livePreview.softBtn")}</span>
                </button>
              </div>

              {/* Badge strip */}
              <div className="flex items-center justify-between pt-2 border-t border-gray-200/60 dark:border-gray-800/60">
                <span className="afab-badge-primary text-[10px] sm:text-xs">
                  {t("appearance.livePreview.statusBadge")}
                </span>
                <span className="text-[10px] sm:text-[11px] text-gray-400 font-mono">
                  {resolvedColors.primary}
                </span>
              </div>
            </div>

            {/* Quick Tips */}
            <div className="mt-3.5 sm:mt-4 p-3 rounded-xl bg-purple-500/5 dark:bg-purple-500/10 border border-purple-500/20 text-[10px] sm:text-[11px] text-gray-500 dark:text-gray-400 flex items-start gap-2">
              <HelpCircle className="w-4 h-4 text-[var(--primary)] shrink-0 mt-0.5" />
              <span className="leading-relaxed">
                {isArabic
                  ? "يتم تطبيق جميع تعديلات المظهر وشخصيات الخطوط وأحجام النصوص فورياً في المتصفح وتُحفظ محلياً لجميع صفحات الموقع."
                  : "All appearance changes, font personalities, and text sizing are applied instantaneously across every page of the website and persisted across sessions."}
              </span>
            </div>
          </div>
        </div>

      </div>

      {/* Floating Mobile/Tablet Quick Preview Shortcut Button */}
      <div className="fixed bottom-5 end-5 z-40 lg:hidden">
        <button
          type="button"
          onClick={() => {
            const previewEl = document.getElementById("appearance-live-preview");
            if (previewEl) {
              previewEl.scrollIntoView({ behavior: "smooth" });
            }
          }}
          className="afab-btn-primary rounded-full px-4 py-2.5 shadow-2xl flex items-center gap-2 text-xs font-bold border border-white/20 hover:scale-105 active:scale-95 transition-all"
        >
          <Eye className="w-3.5 h-3.5" />
          <span>{isArabic ? "معاينة حية" : "Live Preview"}</span>
        </button>
      </div>
    </div>
  );
}
