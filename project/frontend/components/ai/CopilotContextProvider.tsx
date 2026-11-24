"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from "react";
import { usePathname } from "@/i18n/routing";
import { AiReasoningMode } from "@/lib/api/ai";

export interface OpenCopilotOptions {
  prompt?: string;
  autoSend?: boolean;
  screenContext?: Record<string, string>;
  reasoningMode?: AiReasoningMode;
}

interface CopilotLaunchRequest extends OpenCopilotOptions {
  nonce: number;
}

interface CopilotContextValue {
  isOpen: boolean;
  launchRequest: CopilotLaunchRequest | null;
  openCopilot: (options?: OpenCopilotOptions) => void;
  closeCopilot: () => void;
  clearLaunchRequest: () => void;
}

const CopilotContext = createContext<CopilotContextValue>({
  isOpen: false,
  launchRequest: null,
  openCopilot: () => {},
  closeCopilot: () => {},
  clearLaunchRequest: () => {},
});

export function useCopilot() {
  return useContext(CopilotContext);
}

export function CopilotContextProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);
  const [launchRequest, setLaunchRequest] = useState<CopilotLaunchRequest | null>(null);

  const openCopilot = useCallback((options: OpenCopilotOptions = {}) => {
    setIsOpen(true);
    if (options.prompt || options.screenContext || options.reasoningMode) {
      setLaunchRequest({ ...options, nonce: Date.now() });
    }
  }, []);

  const closeCopilot = useCallback(() => {
    setIsOpen(false);
  }, []);

  const clearLaunchRequest = useCallback(() => {
    setLaunchRequest(null);
  }, []);

  // Global Ctrl+K / Cmd+K shortcut across dashboard routes
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        // When already inside the full Copilot workspace, let the page keep focus
        if (pathname?.startsWith("/dashboard/ai")) {
          return;
        }
        e.preventDefault();
        setIsOpen((prev) => !prev);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [pathname]);

  return (
    <CopilotContext.Provider
      value={{ isOpen, launchRequest, openCopilot, closeCopilot, clearLaunchRequest }}
    >
      {children}
    </CopilotContext.Provider>
  );
}
