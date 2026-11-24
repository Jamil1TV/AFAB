package com.afab.ai.gateway;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

/**
 * Replaceable private inference boundary (Ollama default; adaptable to Spring AI / vLLM).
 */
public interface AiModelGateway {

    record GatewayToolCall(
            String name,
            Map<String, Object> arguments
    ) {}

    record GatewayMessage(
            String role,
            String content,
            List<GatewayToolCall> toolCalls,
            String toolName
    ) {
        public static GatewayMessage system(String content) {
            return new GatewayMessage("system", content, null, null);
        }

        public static GatewayMessage user(String content) {
            return new GatewayMessage("user", content, null, null);
        }

        public static GatewayMessage assistant(String content, List<GatewayToolCall> toolCalls) {
            return new GatewayMessage("assistant", content, toolCalls, null);
        }

        public static GatewayMessage tool(String toolName, String content) {
            return new GatewayMessage("tool", content, null, toolName);
        }
    }

    record GatewayToolDefinition(
            String name,
            String description,
            Map<String, Object> parametersSchema
    ) {}

    record GatewayChatRequest(
            String model,
            List<GatewayMessage> messages,
            List<GatewayToolDefinition> tools,
            int numCtx,
            int maxTokens
    ) {}

    record GatewayChatResponse(
            String content,
            List<GatewayToolCall> toolCalls,
            int promptTokens,
            int completionTokens,
            String model
    ) {}

    record GatewayHealth(
            boolean reachable,
            boolean chatModelReady,
            boolean embedModelReady,
            boolean chatModelLoaded,
            boolean busy,
            long latencyMs,
            Instant checkedAt,
            List<String> availableModels
    ) {
        public GatewayHealth(
                boolean reachable,
                boolean chatModelReady,
                boolean embedModelReady,
                List<String> availableModels
        ) {
            this(reachable, chatModelReady, embedModelReady, false, false, 0L, Instant.now(), availableModels);
        }
    }

    GatewayHealth checkHealth();

    default GatewayHealth checkHealth(boolean bypassCache) {
        return checkHealth();
    }

    float[] embed(String text);

    GatewayChatResponse chat(GatewayChatRequest request);

    GatewayChatResponse chatStream(GatewayChatRequest request, Consumer<String> onDelta);
}
