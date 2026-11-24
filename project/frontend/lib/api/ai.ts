import { fetchClient, fetchRawClient, ApiError } from "./client";
import { AuthStore } from "@/lib/auth-store";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

export interface AiEvidenceItem {
  type: "TRANSACTION" | "INVOICE" | "CUSTOMER" | "BUDGET" | "RECURRING" | "MEMORY" | "SUMMARY" | "REPORT" | string;
  id: string;
  title: string;
  subtitle?: string | null;
  amount?: number | null;
  currency?: string | null;
  date?: string | null;
  href?: string | null;
}

export interface AiTokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  monthlyTokensUsed: number;
  monthlyTokensLimit: number;
  monthlyTokensRemaining: number;
  monthlyQueriesUsed: number;
  monthlyQueriesLimit: number;
  monthlyQueriesRemaining: number;
  planSlug: string;
  planName: string;
}

export interface AiStatusResponse {
  enabled: boolean;
  ollamaReachable: boolean;
  chatModel: string;
  chatModelReady: boolean;
  embedModel: string;
  embedModelReady: boolean;
  indexedChunks: number;
  approvedMemories: number;
  quota: AiTokenUsage;
}

export interface AiChatResponse {
  conversationId: string;
  conversationTitle: string;
  messageId: string;
  content: string;
  evidence: AiEvidenceItem[];
  toolsUsed: string[];
  dataCoverage: string;
  modelId: string;
  latencyMs: number;
  tokenUsage: AiTokenUsage;
  suggestedFollowUps: string[];
  createdAt: string;
}

export interface AiConversationSummary {
  id: string;
  title: string;
  locale: string;
  createdAt: string;
  updatedAt: string;
  messageCount: number;
}

export interface AiMessageItem {
  id: string;
  role: "user" | "assistant" | string;
  content: string;
  evidence: AiEvidenceItem[];
  toolsUsed: string[];
  dataCoverage?: string | null;
  modelId?: string | null;
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  latencyMs?: number | null;
  createdAt: string;
}

export interface AiConversationDetail {
  id: string;
  title: string;
  locale: string;
  createdAt: string;
  updatedAt: string;
  messages: AiMessageItem[];
}

export interface BusinessMemoryItem {
  id: string;
  memoryType:
    | "BUSINESS_PROFILE"
    | "TRANSACTION_CONTEXT"
    | "SUPPLIER_PATTERN"
    | "CATEGORIZATION_PREFERENCE"
    | "DECISION_HISTORY"
    | "OPERATIONAL_CONSTRAINT";
  title: string;
  content: string;
  sourceType: string;
  sourceId?: string | null;
  status: "PROPOSED" | "APPROVED" | "EXPIRED" | string;
  visibility: string;
  modelId?: string | null;
  hasVector: boolean;
  expiresAt?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AiIndexSyncResponse {
  indexedCount: number;
  skippedUnchanged: number;
  embeddingsGenerated: number;
  embeddingAvailable: boolean;
  message: string;
}

export interface StreamHandlers {
  onDelta?: (text: string) => void;
  onToolStart?: (tool: string) => void;
  onToolDone?: (tool: string, evidenceCount: number) => void;
  onDone?: (response: AiChatResponse) => void;
  signal?: AbortSignal;
}

export class AiService {
  static async getStatus(): Promise<AiStatusResponse> {
    return fetchClient("/ai/status");
  }

  static async syncIndex(): Promise<AiIndexSyncResponse> {
    return fetchClient("/ai/index/sync", { method: "POST" });
  }

  static async listConversations(): Promise<AiConversationSummary[]> {
    return fetchClient("/ai/conversations");
  }

  static async getConversation(id: string): Promise<AiConversationDetail> {
    return fetchClient(`/ai/conversations/${id}`);
  }

  static async deleteConversation(id: string): Promise<void> {
    return fetchClient(`/ai/conversations/${id}`, { method: "DELETE" });
  }

  static async sendChat(payload: {
    message: string;
    conversationId?: string | null;
    locale?: string;
  }): Promise<AiChatResponse> {
    return fetchClient("/ai/chat", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async streamChat(
    payload: { message: string; conversationId?: string | null; locale?: string },
    handlers: StreamHandlers
  ): Promise<AiChatResponse | null> {
    const response = await fetchRawClient("/ai/chat/stream", {
      method: "POST",
      headers: { Accept: "text/event-stream" },
      body: JSON.stringify(payload),
      signal: handlers.signal,
    });

    if (!response.ok) {
      let errorCode = "UNKNOWN_ERROR";
      let errorMsg = `Request failed (${response.status})`;
      let errorDetails: Record<string, unknown> | undefined;

      try {
        const text = await response.text();
        const parsed = JSON.parse(text) as Record<string, unknown>;
        errorDetails = parsed;
        if (typeof parsed.code === "string") errorCode = parsed.code;
        if (typeof parsed.message === "string") errorMsg = parsed.message;
      } catch {
        // ignore parse errors
      }

      if (response.status === 403 && errorCode === "PLAN_LIMIT_REACHED" && typeof window !== "undefined") {
        window.dispatchEvent(
          new CustomEvent("afab:plan-limit-reached", {
            detail: {
              feature: errorDetails?.feature,
              limit: errorDetails?.limit,
              used: errorDetails?.used,
              upgradeTo: errorDetails?.upgradeTo,
              message: errorMsg,
            },
          })
        );
      }

      if (response.status === 403 && errorCode === "BUSINESS_READ_ONLY" && typeof window !== "undefined") {
        const currentBizId = AuthStore.getActiveBusinessId();
        if (currentBizId && (!errorDetails?.businessId || errorDetails.businessId === currentBizId)) {
          AuthStore.setActiveBusinessId(null);
        }
        window.dispatchEvent(
          new CustomEvent("afab:business-read-only", {
            detail: {
              businessId: errorDetails?.businessId,
              businessName: errorDetails?.businessName,
              message: errorMsg,
            },
          })
        );
      }
      throw new ApiError(errorMsg, errorCode, response.status, errorDetails);
    }

    if (!response.body) {
      throw new ApiError("Empty response stream from server", "EMPTY_STREAM", 502);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let finalPayload: AiChatResponse | null = null;

    const processFrame = (rawFrame: string) => {
      const lines = rawFrame.split(/\r?\n/);
      let eventName = "message";
      const dataLines: string[] = [];

      for (const line of lines) {
        if (line.startsWith("event:")) {
          eventName = line.slice(6).trim();
        } else if (line.startsWith("data:")) {
          dataLines.push(line.slice(5).trim());
        }
      }

      if (dataLines.length === 0) return;
      const rawJson = dataLines.join("\n");
      const parsed = JSON.parse(rawJson);

      if (eventName === "delta") {
        if (typeof parsed?.text === "string") {
          handlers.onDelta?.(parsed.text);
        }
      } else if (eventName === "tool_start") {
        if (typeof parsed?.tool === "string") {
          handlers.onToolStart?.(parsed.tool);
        }
      } else if (eventName === "tool_done") {
        if (typeof parsed?.tool === "string") {
          handlers.onToolDone?.(parsed.tool, Number(parsed?.evidenceCount || 0));
        }
      } else if (eventName === "done") {
        finalPayload = parsed as AiChatResponse;
        handlers.onDone?.(finalPayload);
      } else if (eventName === "error") {
        throw new ApiError(
          typeof parsed?.message === "string" ? parsed.message : "AI stream error",
          typeof parsed?.code === "string" ? parsed.code : "AI_ERROR",
          503
        );
      }
    };

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });

      let sepIdx: number;
      while ((sepIdx = buffer.search(/\r?\n\r?\n/)) !== -1) {
        const frame = buffer.slice(0, sepIdx);
        const match = buffer.slice(sepIdx).match(/^\r?\n\r?\n/);
        buffer = buffer.slice(sepIdx + (match ? match[0].length : 2));
        if (frame.trim()) {
          processFrame(frame);
        }
      }
    }

    if (buffer.trim()) {
      processFrame(buffer);
    }

    if (!finalPayload && !handlers.signal?.aborted) {
      throw new ApiError(
        "Copilot stream ended unexpectedly before completing. Please try again.",
        "INCOMPLETE_STREAM",
        502
      );
    }

    return finalPayload;
  }

  static async listMemory(status: string = "ALL"): Promise<BusinessMemoryItem[]> {
    const q = encodeURIComponent(status);
    return fetchClient(`/ai/memory?status=${q}`);
  }

  static async createMemory(payload: {
    memoryType: BusinessMemoryItem["memoryType"];
    title: string;
    content: string;
    status?: string;
  }): Promise<BusinessMemoryItem> {
    return fetchClient("/ai/memory", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  static async updateMemory(
    id: string,
    payload: Partial<{
      memoryType: BusinessMemoryItem["memoryType"];
      title: string;
      content: string;
      status: string;
    }>
  ): Promise<BusinessMemoryItem> {
    return fetchClient(`/ai/memory/${id}`, {
      method: "PATCH",
      body: JSON.stringify(payload),
    });
  }

  static async deleteMemory(id: string): Promise<void> {
    return fetchClient(`/ai/memory/${id}`, { method: "DELETE" });
  }
}

export const AI_API_BASE_URL = API_BASE_URL;
