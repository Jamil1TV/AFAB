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
            String toolName,
            List<String> images
    ) {
        public GatewayMessage(String role, String content, List<GatewayToolCall> toolCalls, String toolName) {
            this(role, content, toolCalls, toolName, null);
        }

        public static GatewayMessage system(String content) {
            return new GatewayMessage("system", content, null, null, null);
        }

        public static GatewayMessage user(String content) {
            return new GatewayMessage("user", content, null, null, null);
        }

        public static GatewayMessage user(String content, List<String> images) {
            return new GatewayMessage("user", content, null, null, images);
        }

        public static GatewayMessage assistant(String content, List<GatewayToolCall> toolCalls) {
            return new GatewayMessage("assistant", content, toolCalls, null, null);
        }

        public static GatewayMessage tool(String toolName, String content) {
            return new GatewayMessage("tool", content, null, toolName, null);
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
            int maxTokens,
            boolean thinkingEnabled
    ) {
        public GatewayChatRequest(
                String model,
                List<GatewayMessage> messages,
                List<GatewayToolDefinition> tools,
                int numCtx,
                int maxTokens
        ) {
            this(model, messages, tools, numCtx, maxTokens, false);
        }
    }

    record GatewayChatResponse(
            String content,
            List<GatewayToolCall> toolCalls,
            int promptTokens,
            int completionTokens,
            String model,
            String thinkingContent
    ) {
        public GatewayChatResponse(
                String content,
                List<GatewayToolCall> toolCalls,
                int promptTokens,
                int completionTokens,
                String model
        ) {
            this(content, toolCalls, promptTokens, completionTokens, model, "");
        }
    }

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

    default GatewayChatResponse chatStream(
            GatewayChatRequest request,
            Consumer<String> onDelta,
            Consumer<String> onThought
    ) {
        return chatStream(request, onDelta);
    }
}
