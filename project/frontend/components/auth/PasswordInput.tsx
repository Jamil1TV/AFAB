"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Eye, EyeOff } from "lucide-react";

interface PasswordInputProps {
  id: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export function PasswordInput({ id, value, onChange, placeholder }: PasswordInputProps) {
  const t = useTranslations("Auth.login");
  const [visible, setVisible] = useState(false);

  return (
    <div className="relative">
      <input
        id={id}
        type={visible ? "text" : "password"}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="afab-input py-2.5 ps-3.5 pe-10"
        autoComplete="current-password"
      />
      <button
        type="button"
        onClick={() => setVisible(!visible)}
        className="afab-icon-btn absolute end-2 top-1/2 -translate-y-1/2"
        aria-label={visible ? t("hidePassword") : t("showPassword")}
      >
        {visible ? (
          <EyeOff className="h-4 w-4" />
        ) : (
          <Eye className="h-4 w-4" />
        )}
      </button>
    </div>
  );
}
