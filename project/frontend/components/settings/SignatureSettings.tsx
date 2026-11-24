"use client";

import { useState, useEffect, useRef } from "react";
import { useTranslations, useLocale } from "next-intl";
import { 
  PenTool, 
  Upload, 
  Trash2, 
  CheckCircle2, 
  Download, 
  RotateCcw, 
  FileSignature, 
  ShieldCheck, 
  Stamp, 
  UserCheck, 
  Eye, 
  Check, 
  Eraser,
  Edit3,
  Plus,
  Tag,
  X,
  Layers,
  Sparkles
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { toast } from "sonner";
import { 
  getAllSignatures,
  getActiveSignature,
  setActiveSignature,
  saveSignatureItem,
  deleteSignatureItem,
  setSignatureAutoApply,
  getSignatureRegistry,
  processSignatureFile,
  StoredSignatureItem,
  SignatureRegistry
} from "@/lib/signature-utils";

export function SignatureSettings({
  profile,
  business,
}: {
  profile: any;
  business: any;
}) {
  const t = useTranslations("settings");
  const locale = useLocale();
  const isAr = locale === "ar";

  const businessId = business?.id;
  const defaultSignerName = 
    profile?.fullName || 
    (profile?.firstName ? `${profile.firstName} ${profile.lastName || ""}`.trim() : "") || 
    business?.name || 
    "Authorized Officer";

  // ── Registry & Multi-Signature State ──
  const [signatures, setSignatures] = useState<StoredSignatureItem[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [autoApply, setAutoApply] = useState<boolean>(true);

  // ── Form & Edit Mode State ──
  const [editingId, setEditingId] = useState<string | null>(null);
  const [signatureLabel, setSignatureLabel] = useState<string>("");
  const [signatoryName, setSignatoryName] = useState<string>(defaultSignerName);
  const [signatoryTitle, setSignatoryTitle] = useState<string>("Authorized Signatory");
  const [signatureData, setSignatureData] = useState<string | null>(null);
  const [makeDefaultOnSave, setMakeDefaultOnSave] = useState<boolean>(true);
  
  // ── Capture Mode State ──
  const [activeMode, setActiveMode] = useState<"upload" | "draw">("upload");
  const [makeTransparent, setMakeTransparent] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  // ── Canvas Drawing State ──
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [hasCanvasStrokes, setHasCanvasStrokes] = useState(false);
  const [strokeColor, setStrokeColor] = useState<string>("#0f172a");

  // Load registry on mount and whenever business changes
  const refreshRegistry = () => {
    const reg: SignatureRegistry = getSignatureRegistry(businessId);
    setSignatures(reg.signatures || []);
    setActiveId(reg.activeId);
    setAutoApply(reg.autoApply !== false);
  };

  useEffect(() => {
    refreshRegistry();
  }, [businessId]);

  // Set default label based on count when not editing
  useEffect(() => {
    if (!editingId) {
      const nextNum = signatures.length + 1;
      setSignatureLabel(
        signatures.length === 0 
          ? (isAr ? "التوقيع الرئيسي" : "Primary Signature")
          : (isAr ? `توقيع معتمد #${nextNum}` : `Authorized Signature #${nextNum}`)
      );
    }
  }, [editingId, signatures.length, isAr]);

  // File Upload Handler
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.match(/^image\/(png|jpeg|jpg)$/i)) {
      toast.error(isAr ? "يرجى اختيار صورة بصيغة PNG أو JPEG" : "Please upload a PNG or JPEG image.");
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      toast.error(isAr ? "حجم الصورة كبير جداً (الحد الأقصى 5 ميجابايت)" : "File size too large (max 5MB).");
      return;
    }

    setIsProcessing(true);
    try {
      const processedUrl = await processSignatureFile(file, makeTransparent);
      setSignatureData(processedUrl);
      toast.success(isAr ? "تم تجهيز صورة التوقيع بنجاح!" : "Wet signature image processed successfully!");
    } catch (err: any) {
      console.error(err);
      toast.error(err.message || (isAr ? "فشل تجهيز التوقيع" : "Failed to process image."));
    } finally {
      setIsProcessing(false);
      e.target.value = "";
    }
  };

  // Canvas Drawing Handlers
  const startDrawing = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    setIsDrawing(true);
    const rect = canvas.getBoundingClientRect();
    const x = "touches" in e ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = "touches" in e ? e.touches[0].clientY - rect.top : e.clientY - rect.top;

    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
  };

  const draw = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    if (!isDrawing) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = "touches" in e ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = "touches" in e ? e.touches[0].clientY - rect.top : e.clientY - rect.top;

    ctx.lineTo(x, y);
    ctx.stroke();
    setHasCanvasStrokes(true);
  };

  const stopDrawing = () => {
    setIsDrawing(false);
  };

  const clearCanvas = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    setHasCanvasStrokes(false);
  };

  const applyCanvasDrawing = () => {
    const canvas = canvasRef.current;
    if (!canvas || !hasCanvasStrokes) return;
    const dataUrl = canvas.toDataURL("image/png");
    setSignatureData(dataUrl);
    toast.success(isAr ? "تم اعتماد التوقيع المرسوم!" : "Drawn signature applied!");
  };

  // Switch Active Signature (Choose one of them)
  const handleSelectActive = (id: string) => {
    setActiveSignature(id, businessId);
    refreshRegistry();
    const selected = signatures.find((s) => s.id === id);
    toast.success(
      isAr 
        ? `تم تعيين "${selected?.label || "التوقيع"}" كتوقيع نشط ومعتمد!`
        : `"${selected?.label || "Signature"}" is now set as the active signature!`
    );
  };

  // Start Editing an Existing Signature
  const handleStartEdit = (sig: StoredSignatureItem) => {
    setEditingId(sig.id);
    setSignatureLabel(sig.label || "");
    setSignatoryName(sig.signatoryName || "");
    setSignatoryTitle(sig.signatoryTitle || "");
    setSignatureData(sig.dataUrl);
    setMakeDefaultOnSave(sig.isDefault || sig.id === activeId);
    clearCanvas();

    // Scroll to editor smoothly
    const editorEl = document.getElementById("signature-editor-card");
    if (editorEl) {
      editorEl.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  // Cancel Editing Mode
  const handleCancelEdit = () => {
    setEditingId(null);
    setSignatureData(null);
    setSignatoryName(defaultSignerName);
    setSignatoryTitle("Authorized Signatory");
    clearCanvas();
  };

  // Delete a Signature
  const handleDelete = (id: string, label: string) => {
    if (confirm(isAr ? `هل أنت متأكد من حذف توقيع "${label}"؟` : `Are you sure you want to delete signature "${label}"?`)) {
      deleteSignatureItem(id, businessId);
      refreshRegistry();
      if (editingId === id) {
        handleCancelEdit();
      }
      toast.info(isAr ? `تم حذف توقيع "${label}"` : `Signature "${label}" removed.`);
    }
  };

  // Save Signature (Create New or Update Existing)
  const handleSave = () => {
    if (!signatureData) {
      toast.error(isAr ? "يرجى تحميل أو رسم التوقيع أولاً" : "Please upload or draw a signature first.");
      return;
    }

    try {
      const isInitial = signatures.length === 0;
      saveSignatureItem(
        {
          id: editingId || undefined,
          label: signatureLabel.trim() || (isAr ? "توقيع معتمد" : "Authorized Signature"),
          dataUrl: signatureData,
          signatoryName: signatoryName.trim() || defaultSignerName,
          signatoryTitle: signatoryTitle.trim() || "Authorized Signatory",
          isDefault: makeDefaultOnSave || isInitial,
        },
        businessId
      );

      refreshRegistry();
      const savedLabel = signatureLabel.trim() || "Signature";
      const isEditing = !!editingId;
      handleCancelEdit();

      toast.success(
        isEditing
          ? (isAr ? `تم تحديث توقيع "${savedLabel}" بنجاح!` : `Updated "${savedLabel}" successfully!`)
          : (isAr ? `تم حفظ "${savedLabel}" وإضافته لسجل التواقيع المعتمدة!` : `Saved "${savedLabel}" to your signature vault!`)
      );
    } catch (e) {
      console.error(e);
      toast.error(isAr ? "فشل حفظ التوقيع" : "Failed to save signature.");
    }
  };

  // Toggle Auto-Apply
  const handleToggleAutoApply = (enabled: boolean) => {
    setAutoApply(enabled);
    setSignatureAutoApply(enabled, businessId);
    toast.success(
      enabled
        ? (isAr ? "تم تفعيل الإدراج التلقائي للتوقيع في الفواتير والتقارير." : "Auto-apply enabled for Invoices & Exports.")
        : (isAr ? "تم تعطيل الإدراج التلقائي للتوقيع." : "Auto-apply disabled for Invoices & Exports.")
    );
  };

  // Download Transparent PNG Copy
  const handleDownloadCopy = (sig: StoredSignatureItem) => {
    if (!sig.dataUrl) return;
    const a = document.createElement("a");
    a.href = sig.dataUrl;
    a.download = `AFAB_Signature_${sig.label.replace(/\s+/g, "_")}.png`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    toast.success(isAr ? "تم تنزيل نسخة التوقيع" : "Downloaded signature copy.");
  };

  // Active or previewed signature object
  const activeSignature = signatures.find((s) => s.id === activeId || s.isDefault) || signatures[0] || null;
  const previewSignatureData = signatureData || activeSignature?.dataUrl || null;
  const previewName = signatoryName || activeSignature?.signatoryName || defaultSignerName;
  const previewTitle = signatoryTitle || activeSignature?.signatoryTitle || "Authorized Signatory";

  return (
    <div className="space-y-8 pb-12">
      {/* ── Top Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2">
        <div className="flex items-center gap-3.5">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#070a14] shadow-sm p-2 text-[var(--primary)]">
            <FileSignature className="h-6 w-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl sm:text-2xl font-extrabold text-gray-900 dark:text-white">
                {isAr ? "إدارة التواقيع الحية والأختام" : "Wet Signatures & Signatory Vault"}
              </h1>
              <span className="rounded-full bg-purple-500/10 border border-purple-500/20 px-2.5 py-0.5 text-[11px] font-semibold text-[var(--primary)] inline-flex items-center gap-1">
                <Layers className="w-3 h-3" />
                {signatures.length} {isAr ? "تواقيع محفوظة" : "Saved"}
              </span>
            </div>
            <p className="text-xs sm:text-sm text-gray-500 dark:text-gray-400 mt-0.5">
              {isAr
                ? "احفظ عدة تواقيع رسمية، اختر التوقيع النشط المعتمد، وقم بتعديله أو حذفه بكل سهولة ليُدمج في الفواتير وصادرات إكسل و PDF."
                : "Save multiple wet signatures, choose which one is active, edit details, or delete. The active signature certifies invoices and exports."}
            </p>
          </div>
        </div>

        {signatures.length > 0 && (
          <Button
            type="button"
            onClick={() => {
              handleCancelEdit();
              const el = document.getElementById("signature-editor-card");
              el?.scrollIntoView({ behavior: "smooth" });
            }}
            className="self-start sm:self-auto bg-[var(--primary)] hover:bg-[var(--primary-hover,#7c3aed)] text-white text-xs font-semibold rounded-xl h-9 px-4 gap-1.5 shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>{isAr ? "إضافة توقيع جديد" : "Add New Signature"}</span>
          </Button>
        )}
      </div>

      {/* ── SECTION 1: SAVED SIGNATURES VAULT (GALLERY & SELECTOR) ── */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-sm font-bold text-gray-900 dark:text-white">
            <Stamp className="w-4 h-4 text-[var(--primary)]" />
            <span>{isAr ? "سجل التواقيع المحفوظة (اختر التوقيع المعتمد)" : "Saved Signatures Vault (Choose Active)"}</span>
          </div>
          <span className="text-xs text-gray-500 dark:text-gray-400">
            {isAr ? "انقر على أي توقيع لتعيينه كنشط" : "Click any signature to set it active"}
          </span>
        </div>

        {signatures.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-gray-300 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] p-8 text-center space-y-3">
            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-purple-500/10 text-[var(--primary)]">
              <FileSignature className="h-6 w-6" />
            </div>
            <h3 className="text-sm font-bold text-gray-900 dark:text-white">
              {isAr ? "لا يوجد تواقيع محفوظة بعد" : "No signatures saved yet"}
            </h3>
            <p className="text-xs text-gray-500 dark:text-gray-400 max-w-sm mx-auto">
              {isAr
                ? "قم برفع صورة توقيعك أو ارسمه مباشرة باستخدام اللوحة أدناه لحفظه في سجلك المعتمد."
                : "Upload or draw your signature below to save it in your registry and certify documents."}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {signatures.map((sig) => {
              const isActive = sig.id === activeId || (sig.isDefault && !activeId);
              const isBeingEdited = editingId === sig.id;

              return (
                <div
                  key={sig.id}
                  className={`group relative flex flex-col justify-between rounded-3xl border transition-all p-5 bg-white dark:bg-[#0c101c] shadow-xs ${
                    isActive
                      ? "border-emerald-500/60 dark:border-emerald-500/50 ring-2 ring-emerald-500/20"
                      : isBeingEdited
                      ? "border-purple-500/60 dark:border-purple-500/50 ring-2 ring-purple-500/20"
                      : "border-gray-200 dark:border-gray-800/80 hover:border-gray-300 dark:hover:border-gray-700"
                  }`}
                >
                  {/* Top Header of Card */}
                  <div className="flex items-start justify-between gap-2 pb-3 border-b border-gray-100 dark:border-gray-800/70">
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5">
                        <Tag className="w-3.5 h-3.5 text-[var(--primary)] shrink-0" />
                        <h4 className="text-xs sm:text-sm font-bold text-gray-900 dark:text-white truncate">
                          {sig.label}
                        </h4>
                      </div>
                      <p className="text-[11px] text-gray-500 dark:text-gray-400 truncate mt-0.5">
                        {sig.signatoryName} • {sig.signatoryTitle}
                      </p>
                    </div>

                    {/* Active Badge */}
                    {isActive ? (
                      <span className="shrink-0 rounded-full bg-emerald-500/10 border border-emerald-500/30 px-2 py-0.5 text-[10px] font-semibold text-emerald-600 dark:text-emerald-400 inline-flex items-center gap-1">
                        <CheckCircle2 className="w-3 h-3" />
                        <span>{isAr ? "النشط والمعتمد" : "Active & In Use"}</span>
                      </span>
                    ) : (
                      <button
                        type="button"
                        onClick={() => handleSelectActive(sig.id)}
                        className="shrink-0 text-[11px] font-semibold text-gray-500 hover:text-[var(--primary)] hover:underline flex items-center gap-1 transition-colors"
                      >
                        <Check className="w-3 h-3" />
                        <span>{isAr ? "تعيين كنشط" : "Set as Active"}</span>
                      </button>
                    )}
                  </div>

                  {/* Signature Visual Canvas Display */}
                  <div 
                    onClick={() => !isActive && handleSelectActive(sig.id)}
                    className="cursor-pointer my-3 rounded-2xl border border-gray-100 dark:border-gray-800/60 bg-gray-50/60 dark:bg-white/[0.02] p-3 flex items-center justify-center h-28 overflow-hidden hover:bg-gray-100/50 dark:hover:bg-white/[0.04] transition-colors"
                    title={isActive ? (isAr ? "التوقيع النشط حالياً" : "Currently Active") : (isAr ? "انقر لتعيينه كنشط" : "Click to set as active")}
                  >
                    <img
                      src={sig.dataUrl}
                      alt={sig.label}
                      className="max-h-full max-w-full object-contain filter contrast-125 transition-transform group-hover:scale-105"
                    />
                  </div>

                  {/* Card Actions Footer */}
                  <div className="pt-2 flex items-center justify-between border-t border-gray-100 dark:border-gray-800/70">
                    <div className="flex items-center gap-1">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => handleStartEdit(sig)}
                        className={`rounded-xl text-xs h-8 px-2.5 gap-1 ${
                          isBeingEdited
                            ? "bg-purple-50 dark:bg-purple-950/30 text-[var(--primary)] font-bold"
                            : "text-gray-600 dark:text-gray-300 hover:text-gray-900"
                        }`}
                        title={isAr ? "تعديل هذا التوقيع" : "Edit signature details"}
                      >
                        <Edit3 className="w-3.5 h-3.5" />
                        <span>{isAr ? "تعديل" : "Edit"}</span>
                      </Button>

                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDownloadCopy(sig)}
                        className="rounded-xl text-xs h-8 px-2 text-gray-600 dark:text-gray-300 hover:text-gray-900"
                        title={isAr ? "تنزيل صورة التوقيع بصيغة PNG" : "Download PNG"}
                      >
                        <Download className="w-3.5 h-3.5" />
                      </Button>
                    </div>

                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDelete(sig.id, sig.label)}
                      className="rounded-xl text-xs h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950/20"
                      title={isAr ? "حذف التوقيع" : "Delete signature"}
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </Button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* ── SECTION 2: ADD OR EDIT SIGNATURE WORKSPACE ── */}
      <div id="signature-editor-card" className="grid grid-cols-1 lg:grid-cols-12 gap-8 pt-4 border-t border-gray-200 dark:border-gray-800/60">
        {/* Left Column: Form and Capture Controls (7 cols) */}
        <div className="lg:col-span-7 space-y-6">
          {/* Active Edit Mode Banner */}
          {editingId ? (
            <div className="flex items-center justify-between p-3.5 rounded-2xl bg-purple-50/80 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-800/60">
              <div className="flex items-center gap-2.5">
                <div className="flex h-8 w-8 items-center justify-center rounded-xl bg-[var(--primary)] text-white">
                  <Edit3 className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-gray-900 dark:text-white">
                    {isAr ? `أنت تقوم بتعديل: ${signatureLabel}` : `Editing Signature: ${signatureLabel}`}
                  </h4>
                  <p className="text-[11px] text-gray-500 dark:text-gray-400">
                    {isAr ? "يمكنك تحديث الاسم، المسمى، التسمية، أو رفع/رسم حبر جديد." : "Update the label, signatory details, or re-upload/draw new ink."}
                  </p>
                </div>
              </div>
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleCancelEdit}
                className="rounded-xl text-xs h-8 px-3 border-purple-300 dark:border-purple-800 text-purple-700 dark:text-purple-300 gap-1"
              >
                <X className="w-3.5 h-3.5" />
                <span>{isAr ? "إلغاء التعديل" : "Cancel"}</span>
              </Button>
            </div>
          ) : (
            <div className="flex items-center gap-2 text-sm font-bold text-gray-900 dark:text-white pb-1">
              <Plus className="w-4 h-4 text-[var(--primary)]" />
              <span>{isAr ? "إضافة توقيع حي جديد" : "Add a New Wet Signature"}</span>
            </div>
          )}

          {/* Mode Switcher Tabs */}
          <div className="flex items-center p-1 rounded-2xl bg-gray-100 dark:bg-white/[0.04] border border-gray-200 dark:border-gray-800/80">
            <button
              type="button"
              onClick={() => setActiveMode("upload")}
              className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-xl text-xs font-semibold transition-all ${
                activeMode === "upload"
                  ? "bg-white dark:bg-[#0c101c] text-gray-900 dark:text-white shadow-xs"
                  : "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
              }`}
            >
              <Upload className="w-4 h-4" />
              <span>{isAr ? "رفع صورة (PNG أو JPEG)" : "Upload Image (PNG/JPEG)"}</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveMode("draw")}
              className={`flex-1 flex items-center justify-center gap-2 py-2 px-3 rounded-xl text-xs font-semibold transition-all ${
                activeMode === "draw"
                  ? "bg-white dark:bg-[#0c101c] text-gray-900 dark:text-white shadow-xs"
                  : "text-gray-500 hover:text-gray-700 dark:hover:text-gray-300"
              }`}
            >
              <PenTool className="w-4 h-4" />
              <span>{isAr ? "رسم التوقيع مباشرة" : "Draw Signature Pad"}</span>
            </button>
          </div>

          {/* Capture Option 1: File Upload */}
          {activeMode === "upload" && (
            <div className="rounded-3xl border-2 border-dashed border-gray-300 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-6 sm:p-8 text-center space-y-4 hover:border-[var(--primary)]/60 transition-colors">
              <input
                id="signature-file-input"
                type="file"
                accept="image/png, image/jpeg, image/jpg"
                onChange={handleFileUpload}
                className="hidden"
              />

              <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-purple-500/10 text-[var(--primary)] shadow-sm">
                <Upload className="h-6 w-6" />
              </div>

              <div>
                <h3 className="text-sm sm:text-base font-bold text-gray-900 dark:text-white">
                  {isAr ? "اسحب وأفلت صورة توقيعك هنا" : "Drop your signature image here"}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 max-w-sm mx-auto">
                  {isAr
                    ? "يدعم صيغ PNG أو JPEG حتى 5 ميجابايت. يُفضل توقيع بخط واضح على ورقة بيضاء."
                    : "Supports PNG or JPEG up to 5MB. A photo or scan of your signature on white paper works great."}
                </p>
              </div>

              <div className="pt-2 flex flex-wrap items-center justify-center gap-3">
                <Button
                  type="button"
                  onClick={() => document.getElementById("signature-file-input")?.click()}
                  disabled={isProcessing}
                  className="bg-[var(--primary)] hover:bg-[var(--primary-hover,#7c3aed)] text-white text-xs font-semibold rounded-xl h-10 px-5 gap-2 shadow-sm"
                >
                  <Upload className="w-4 h-4" />
                  <span>{isProcessing ? (isAr ? "جاري المعالجة..." : "Processing...") : (isAr ? "استعراض الملفات..." : "Browse Files...")}</span>
                </Button>
              </div>

              {/* Background transparency option */}
              <div className="pt-3 border-t border-gray-100 dark:border-gray-800/80 flex items-center justify-center gap-2">
                <input
                  id="make-transparent-check"
                  type="checkbox"
                  checked={makeTransparent}
                  onChange={(e) => setMakeTransparent(e.target.checked)}
                  className="rounded text-[var(--primary)] focus:ring-[var(--primary)] h-4 w-4"
                />
                <label htmlFor="make-transparent-check" className="text-xs text-gray-600 dark:text-gray-300 font-medium cursor-pointer">
                  {isAr ? "إزالة خلفية الورقة تلقائياً (حبر شفاف نقي)" : "Auto-remove paper background (Pure transparent ink)"}
                </label>
              </div>
            </div>
          )}

          {/* Capture Option 2: Live Drawing Pad */}
          {activeMode === "draw" && (
            <div className="rounded-3xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-5 shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <PenTool className="w-4 h-4 text-[var(--primary)]" />
                  <span className="text-xs font-bold text-gray-900 dark:text-white">
                    {isAr ? "لوحة رسم التوقيع الحي" : "Sign Live with Touch, Mouse or Pen"}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setStrokeColor("#0f172a")}
                    className={`w-5 h-5 rounded-full border ${strokeColor === "#0f172a" ? "ring-2 ring-purple-500" : ""} bg-slate-900`}
                    title="Black / Dark Ink"
                  />
                  <button
                    type="button"
                    onClick={() => setStrokeColor("#1d4ed8")}
                    className={`w-5 h-5 rounded-full border ${strokeColor === "#1d4ed8" ? "ring-2 ring-purple-500" : ""} bg-blue-700`}
                    title="Royal Blue Ink"
                  />
                  <button
                    type="button"
                    onClick={clearCanvas}
                    className="p-1 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
                    title={isAr ? "مسح اللوحة" : "Clear Canvas"}
                  >
                    <Eraser className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Canvas Container */}
              <div className="relative rounded-2xl border-2 border-dashed border-gray-200 dark:border-gray-800 bg-gray-50/70 dark:bg-white/[0.02] overflow-hidden flex items-center justify-center h-48 cursor-crosshair">
                <canvas
                  ref={canvasRef}
                  width={600}
                  height={200}
                  onMouseDown={startDrawing}
                  onMouseMove={draw}
                  onMouseUp={stopDrawing}
                  onMouseLeave={stopDrawing}
                  onTouchStart={startDrawing}
                  onTouchMove={draw}
                  onTouchEnd={stopDrawing}
                  className="w-full h-full touch-none"
                />
                {!hasCanvasStrokes && (
                  <div className="absolute pointer-events-none text-center text-xs text-gray-400">
                    <PenTool className="w-5 h-5 mx-auto mb-1 opacity-40" />
                    <span>{isAr ? "وقع هنا بإصبعك أو بالفأرة" : "Sign here with finger or mouse"}</span>
                  </div>
                )}
              </div>

              <div className="flex items-center justify-end gap-2.5">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={clearCanvas}
                  className="rounded-xl text-xs h-9 px-3 gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>{isAr ? "إعادة تعيين" : "Reset Pad"}</span>
                </Button>
                <Button
                  type="button"
                  size="sm"
                  onClick={applyCanvasDrawing}
                  disabled={!hasCanvasStrokes}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-xl h-9 px-4 gap-1.5"
                >
                  <Check className="w-3.5 h-3.5" />
                  <span>{isAr ? "اعتماد هذا التوقيع" : "Use This Drawing"}</span>
                </Button>
              </div>
            </div>
          )}

          {/* ── Metadata & Configuration Card ── */}
          <div className="rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 shadow-xs space-y-4">
            <div className="flex items-center gap-2 text-sm font-bold text-gray-900 dark:text-white">
              <UserCheck className="w-4 h-4 text-[var(--primary)]" />
              <span>{isAr ? "تفاصيل التوقيع والمفوض" : "Signature & Signatory Metadata"}</span>
            </div>

            <div className="space-y-4">
              {/* Signature Label */}
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                  {isAr ? "اسم / وصف التوقيع للتمييز:" : "Signature Label / Identifier:"}
                </label>
                <Input
                  type="text"
                  value={signatureLabel}
                  onChange={(e) => setSignatureLabel(e.target.value)}
                  placeholder={isAr ? "مثال: توقيع المدير العام، ختم المحاسبة، توقيع العقود" : "e.g. CEO Primary, Finance Manager, Operations Seal"}
                  className="rounded-xl text-xs h-10"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Signatory Name */}
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {isAr ? "اسم المفوض بالتوقيع:" : "Full Signatory Name:"}
                  </label>
                  <Input
                    type="text"
                    value={signatoryName}
                    onChange={(e) => setSignatoryName(e.target.value)}
                    placeholder="e.g. John Doe / Ahmed K."
                    className="rounded-xl text-xs h-10"
                  />
                </div>

                {/* Signatory Title */}
                <div>
                  <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1.5">
                    {isAr ? "المسمى الوظيفي / الصفة:" : "Signatory Title / Position:"}
                  </label>
                  <Input
                    type="text"
                    value={signatoryTitle}
                    onChange={(e) => setSignatoryTitle(e.target.value)}
                    placeholder="e.g. Managing Director / CEO"
                    className="rounded-xl text-xs h-10"
                  />
                </div>
              </div>

              {/* Set as Active Default Checkbox */}
              <div className="pt-2">
                <label className="flex items-center gap-2.5 text-xs text-gray-700 dark:text-gray-300 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={makeDefaultOnSave}
                    onChange={(e) => setMakeDefaultOnSave(e.target.checked)}
                    className="rounded text-[var(--primary)] focus:ring-[var(--primary)] h-4 w-4"
                  />
                  <span className="font-semibold">
                    {isAr ? "تعيين هذا التوقيع كنشط ومعتمد فور الحفظ" : "Set this signature as active and certified immediately"}
                  </span>
                </label>
              </div>

              {/* Global Auto-apply Preference */}
              <div className="pt-2">
                <label className="flex items-start gap-3 p-3.5 rounded-2xl bg-purple-50/50 dark:bg-purple-950/20 border border-purple-200/60 dark:border-purple-900/40 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={autoApply}
                    onChange={(e) => handleToggleAutoApply(e.target.checked)}
                    className="rounded text-[var(--primary)] focus:ring-[var(--primary)] h-4 w-4 mt-0.5"
                  />
                  <div>
                    <span className="text-xs font-bold text-gray-900 dark:text-white block">
                      {isAr ? "تضمين التوقيع النشط تلقائياً في الفواتير وصادرات البيانات" : "Automatically stamp active signature onto Invoices & Data Exports"}
                    </span>
                    <span className="text-[11px] text-gray-500 dark:text-gray-400 block mt-0.5 leading-relaxed">
                      {isAr
                        ? "عند التفعيل، سيظهر توقيعك النشط مع ختم المصادقة في فواتير العملاء وصادرات إكسل وملفات PDF المعتمدة."
                        : "When enabled, your active signature and seal are stamped onto invoices, PDF reports, and Excel workbooks."}
                    </span>
                  </div>
                </label>
              </div>
            </div>

            {/* Action buttons */}
            <div className="pt-3 border-t border-gray-100 dark:border-gray-800 flex items-center justify-end gap-3">
              {editingId && (
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleCancelEdit}
                  className="rounded-xl text-xs h-10 px-4 border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300"
                >
                  {isAr ? "إلغاء التعديل" : "Cancel"}
                </Button>
              )}

              <Button
                type="button"
                onClick={handleSave}
                disabled={!signatureData}
                className="bg-[var(--primary)] hover:bg-[var(--primary-hover,#7c3aed)] text-white font-semibold rounded-xl text-xs h-10 px-6 gap-2 shadow-sm shadow-purple-500/20"
              >
                <Check className="w-4 h-4" />
                <span>
                  {editingId
                    ? (isAr ? "تحديث التوقيع" : "Update Signature")
                    : (isAr ? "حفظ وإضافة إلى السجل" : "Save Signature to Vault")}
                </span>
              </Button>
            </div>
          </div>
        </div>

        {/* ── Right Column: Live Certified Document Preview (5 cols) ── */}
        <div className="lg:col-span-5 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold text-gray-700 dark:text-gray-300">
              <Eye className="w-4 h-4 text-[var(--primary)]" />
              <span>{isAr ? "معاينة الوثيقة المعتمدة بالتوقيع النشط" : "Live Certified Document Preview"}</span>
            </div>
            <span className="text-[10px] text-gray-400">
              {isAr ? "نموذج الفاتورة والتقرير" : "Official Invoice & Report Spec"}
            </span>
          </div>

          {/* Paper Document Card */}
          <div className="relative rounded-3xl border border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 shadow-md overflow-hidden space-y-6">
            {/* Watermark badge */}
            <div className="flex items-center justify-between border-b border-gray-100 dark:border-gray-800 pb-4">
              <div className="flex items-center gap-2.5">
                <div className="h-8 w-8 rounded-lg border border-gray-200 dark:border-gray-800 p-1 flex items-center justify-center bg-white dark:bg-[#070a14]">
                  <img src="/assets/afab-logo-light.png" alt="AFAB Logo" className="h-full w-full object-contain" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-gray-900 dark:text-white">
                    {business?.name || "AFAB Enterprise"}
                  </h4>
                  <p className="text-[10px] text-gray-400">
                    Official Certified Record #849201
                  </p>
                </div>
              </div>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 font-semibold border border-emerald-500/20">
                CERTIFIED
              </span>
            </div>

            {/* Mock voucher content */}
            <div className="space-y-2 text-xs text-gray-500 dark:text-gray-400">
              <div className="flex justify-between text-[11px]">
                <span>Document Status:</span>
                <span className="font-semibold text-gray-900 dark:text-white">Authorized & Verified</span>
              </div>
              <div className="flex justify-between text-[11px]">
                <span>Active Signature Label:</span>
                <span className="font-semibold text-[var(--primary)]">
                  {editingId && signatureLabel ? signatureLabel : activeSignature?.label || "No Active Signature"}
                </span>
              </div>
              <div className="flex justify-between text-[11px]">
                <span>Security Standard:</span>
                <span className="font-semibold text-[var(--primary)]">AFAB 256-Bit Digital Seal</span>
              </div>
            </div>

            {/* Signature Placement Box */}
            <div className="pt-4 border-t-2 border-dashed border-gray-100 dark:border-gray-800">
              <div className="text-[11px] font-bold uppercase tracking-wider text-gray-400 mb-2 flex items-center justify-between">
                <span>{isAr ? "التوقيع الحي المعتمد" : "Authorized Wet Signature"}</span>
                <Stamp className="w-3.5 h-3.5 text-purple-500/60" />
              </div>

              <div className="relative rounded-2xl border border-gray-200/80 dark:border-gray-800 bg-gray-50/50 dark:bg-white/[0.02] p-4 min-h-[110px] flex flex-col justify-end">
                {previewSignatureData ? (
                  <div className="flex flex-col items-start space-y-1">
                    <div className="h-16 w-44 flex items-center justify-start">
                      <img
                        src={previewSignatureData}
                        alt="Wet Signature"
                        className="max-h-full max-w-full object-contain filter contrast-125"
                      />
                    </div>
                    <div className="border-t border-gray-300 dark:border-gray-700 w-44 pt-1">
                      <p className="text-xs font-bold text-gray-900 dark:text-white">
                        {previewName}
                      </p>
                      <p className="text-[10px] text-gray-500 dark:text-gray-400">
                        {previewTitle}
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="h-20 flex flex-col items-center justify-center text-center text-xs text-gray-400 border border-dashed border-gray-200 dark:border-gray-800 rounded-xl p-2">
                    <PenTool className="w-4 h-4 mb-1 opacity-50" />
                    <span>{isAr ? "لم يتم تعيين توقيع حي بعد" : "No signature selected yet"}</span>
                  </div>
                )}
              </div>
            </div>

            {/* Bottom Certification Notice */}
            <div className="rounded-xl bg-purple-50/50 dark:bg-purple-950/20 p-3 border border-purple-200/50 dark:border-purple-900/40 flex items-start gap-2.5">
              <ShieldCheck className="w-4 h-4 text-[var(--primary)] shrink-0 mt-0.5" />
              <p className="text-[10px] text-gray-600 dark:text-gray-300 leading-relaxed">
                {isAr
                  ? "يتم تشفير التوقيع النشط محلياً وختمه بصرياً على جميع الفواتير وصادرات إكسل وتقارير PDF المعتمدة للمنشأة."
                  : "The active signature is encrypted, locally cached, and automatically stamped on customer invoices and financial exports."}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
