"use client";

import { useEffect, useRef, useState } from "react";
import { Mic, MicOff } from "lucide-react";
import { useTranslations } from "next-intl";
import { toast } from "sonner";

type SpeechLangOption = {
  code: string;
  label: string;
};

const SPEECH_LANGS: SpeechLangOption[] = [
  { code: "en-US", label: "EN" },
  { code: "fr-FR", label: "FR" },
  { code: "ar-TN", label: "TN" },
];

interface SpeechRecognitionInstance {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  onresult: ((event: { results: ArrayLike<{ isFinal: boolean; 0: { transcript: string } }> }) => void) | null;
  onerror: ((event: { error: string }) => void) | null;
  onend: (() => void) | null;
  start: () => void;
  stop: () => void;
  abort?: () => void;
}

interface VoiceDictationButtonProps {
  defaultLocale?: string;
  disabled?: boolean;
  onTranscript: (finalText: string) => void;
  onInterimChange?: (interimText: string) => void;
}

export function VoiceDictationButton({
  defaultLocale = "en",
  disabled = false,
  onTranscript,
  onInterimChange,
}: VoiceDictationButtonProps) {
  const t = useTranslations("AI.voice");
  const [supported, setSupported] = useState(false);
  const [listening, setListening] = useState(false);
  const [langCode, setLangCode] = useState<string>(
    defaultLocale === "ar" ? "ar-TN" : defaultLocale === "fr" ? "fr-FR" : "en-US"
  );
  const recognitionRef = useRef<SpeechRecognitionInstance | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const w = window as unknown as {
      SpeechRecognition?: new () => SpeechRecognitionInstance;
      webkitSpeechRecognition?: new () => SpeechRecognitionInstance;
    };
    setSupported(Boolean(w.SpeechRecognition || w.webkitSpeechRecognition));
    return () => {
      try {
        recognitionRef.current?.abort?.();
      } catch {
        // ignore
      }
    };
  }, []);

  if (!supported) {
    return null;
  }

  const stopListening = () => {
    try {
      recognitionRef.current?.stop();
    } catch {
      // ignore
    }
    setListening(false);
    onInterimChange?.("");
  };

  const toggleListening = () => {
    if (disabled) return;
    if (listening) {
      stopListening();
      return;
    }

    const w = window as unknown as {
      SpeechRecognition?: new () => SpeechRecognitionInstance;
      webkitSpeechRecognition?: new () => SpeechRecognitionInstance;
    };
    const Ctor = w.SpeechRecognition || w.webkitSpeechRecognition;
    if (!Ctor) return;

    try {
      const rec = new Ctor();
      rec.continuous = true;
      rec.interimResults = true;
      rec.lang = langCode;

      rec.onresult = (event) => {
        let interim = "";
        const finalizedChunks: string[] = [];
        for (let i = 0; i < event.results.length; i++) {
          const res = event.results[i];
          const text = res?.[0]?.transcript || "";
          if (!text) continue;
          if (res.isFinal) {
            finalizedChunks.push(text.trim());
          } else {
            interim += `${text} `;
          }
        }
        onInterimChange?.(interim.trim());
        if (finalizedChunks.length > 0) {
          onTranscript(finalizedChunks.join(" "));
          stopListening();
        }
      };

      rec.onerror = (event) => {
        setListening(false);
        onInterimChange?.("");
        if (event.error === "not-allowed" || event.error === "service-not-allowed") {
          toast.error(t("permissionDenied"));
        } else if (event.error !== "aborted" && event.error !== "no-speech") {
          toast.error(t("error"));
        }
      };

      rec.onend = () => {
        setListening(false);
        onInterimChange?.("");
      };

      recognitionRef.current = rec;
      setListening(true);
      rec.start();
    } catch {
      setListening(false);
      toast.error(t("error"));
    }
  };

  const cycleLang = () => {
    if (listening) return;
    const idx = SPEECH_LANGS.findIndex((s) => s.code === langCode);
    const next = SPEECH_LANGS[(idx + 1) % SPEECH_LANGS.length];
    setLangCode(next.code);
  };

  const activeLabel = SPEECH_LANGS.find((s) => s.code === langCode)?.label || "EN";

  return (
    <div className="inline-flex items-center rounded-xl border border-gray-200 dark:border-gray-800 bg-[var(--card)] p-0.5 shrink-0">
      <button
        type="button"
        onClick={cycleLang}
        disabled={listening || disabled}
        title={t("switchLang")}
        className="px-1.5 py-1 text-[10px] font-bold text-gray-500 dark:text-gray-400 hover:text-[var(--primary)] disabled:opacity-50 rounded-lg transition-colors"
      >
        {activeLabel}
      </button>
      <button
        type="button"
        onClick={toggleListening}
        disabled={disabled}
        title={listening ? t("stop") : t("start")}
        aria-label={listening ? t("stop") : t("start")}
        className={`relative flex h-8 w-8 items-center justify-center rounded-lg transition-all ${
          listening
            ? "bg-red-500 text-white shadow-sm shadow-red-500/30 animate-pulse"
            : "text-gray-500 dark:text-gray-400 hover:bg-[var(--primary)]/10 hover:text-[var(--primary)]"
        }`}
      >
        {listening ? <MicOff className="h-3.5 w-3.5" /> : <Mic className="h-3.5 w-3.5" />}
      </button>
    </div>
  );
}
