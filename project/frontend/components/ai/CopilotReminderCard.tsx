"use client";

import { useState } from "react";
import { Check, Copy, Mail, MessageCircle } from "lucide-react";
import { useTranslations } from "next-intl";
import { AiActionDraft } from "@/lib/api/ai";
import { toast } from "sonner";

export function CopilotReminderCard({ draft }: { draft: AiActionDraft }) {
  const t = useTranslations("AI.reminder");
  const p = draft.payload || {};
  const [channel, setChannel] = useState<"email" | "whatsapp">("email");
  const [subject, setSubject] = useState(String(p.emailSubject || ""));
  const [emailBody, setEmailBody] = useState(String(p.emailBody || ""));
  const [waBody, setWaBody] = useState(String(p.whatsappBody || ""));
  const [copied, setCopied] = useState(false);

  const customerEmail = String(p.customerEmail || "");
  const customerPhone = String(p.customerPhone || "").replace(/[^0-9+]/g, "");

  const handleCopy = async () => {
    const text = channel === "email" ? `${subject}\n\n${emailBody}` : waBody;
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      toast.success(t("copied"));
      setTimeout(() => setCopied(false), 1800);
    } catch {
      // ignore
    }
  };

  const mailtoHref = `mailto:${encodeURIComponent(customerEmail)}?subject=${encodeURIComponent(
    subject
  )}&body=${encodeURIComponent(emailBody)}`;
  const waHref = `https://wa.me/${encodeURIComponent(customerPhone.replace(/^\+/, ""))}?text=${encodeURIComponent(
    waBody
  )}`;

  return (
    <div className="rounded-2xl border border-[var(--primary)]/30 bg-[var(--surface-inset)] p-4 space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <h4 className="text-xs font-bold text-gray-900 dark:text-white">
            {draft.title}
          </h4>
          <p className="text-[11px] text-gray-500 dark:text-gray-400">
            {draft.summary}
          </p>
        </div>
        <div className="inline-flex rounded-xl border border-gray-200 dark:border-gray-800 bg-[var(--card)] p-0.5 text-[11px]">
          <button
            type="button"
            onClick={() => setChannel("email")}
            className={`inline-flex items-center gap-1 rounded-lg px-2.5 py-1 font-semibold transition-colors ${
              channel === "email"
                ? "bg-[var(--primary)] text-white"
                : "text-gray-600 dark:text-gray-300"
            }`}
          >
            <Mail className="h-3 w-3" />
            <span>Email</span>
          </button>
          <button
            type="button"
            onClick={() => setChannel("whatsapp")}
            className={`inline-flex items-center gap-1 rounded-lg px-2.5 py-1 font-semibold transition-colors ${
              channel === "whatsapp"
                ? "bg-emerald-600 text-white"
                : "text-gray-600 dark:text-gray-300"
            }`}
          >
            <MessageCircle className="h-3 w-3" />
            <span>WhatsApp</span>
          </button>
        </div>
      </div>

      {channel === "email" ? (
        <div className="space-y-2">
          <input
            type="text"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            className="afab-input py-1.5 text-xs font-semibold"
          />
          <textarea
            rows={5}
            value={emailBody}
            onChange={(e) => setEmailBody(e.target.value)}
            className="afab-input py-2 text-xs leading-relaxed resize-y"
          />
        </div>
      ) : (
        <textarea
          rows={4}
          value={waBody}
          onChange={(e) => setWaBody(e.target.value)}
          className="afab-input py-2 text-xs leading-relaxed resize-y"
        />
      )}

      <div className="flex flex-wrap items-center justify-end gap-2">
        <button
          type="button"
          onClick={handleCopy}
          className="afab-btn-secondary px-3 py-1.5 text-xs"
        >
          {copied ? <Check className="h-3.5 w-3.5 text-emerald-500" /> : <Copy className="h-3.5 w-3.5" />}
          <span>{copied ? t("copied") : t("copy")}</span>
        </button>

        {channel === "email" ? (
          <a href={mailtoHref} className="afab-btn-primary px-3.5 py-1.5 text-xs">
            <Mail className="h-3.5 w-3.5" />
            <span>{t("openEmail")}</span>
          </a>
        ) : (
          <a
            href={waHref}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 px-3.5 py-1.5 text-xs font-bold text-white transition-colors"
          >
            <MessageCircle className="h-3.5 w-3.5" />
            <span>{t("openWhatsapp")}</span>
          </a>
        )}
      </div>
    </div>
  );
}
