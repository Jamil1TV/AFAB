package com.afab.ai.gateway;

import com.afab.ai.config.AiProperties;
import com.afab.ai.exception.AiServiceUnavailableException;
import com.afab.security.LogSanitizer;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Local-first Ollama HTTP adapter with VRAM concurrency throttling and strict timeouts.
 * Never logs raw prompts, completions, or customer financial payloads.
 */
@Service
public class OllamaModelGateway implements AiModelGateway {

    private static final Logger log = LoggerFactory.getLogger(OllamaModelGateway.class);

    private final AiProperties properties;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final HttpClient httpClient;
    private final Semaphore gpuSemaphore;

    private volatile CachedHealth cachedHealth;

    private record CachedHealth(GatewayHealth health, Instant expiresAt) {}

    public OllamaModelGateway(AiProperties properties) {
        this.properties = properties;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.gpuSemaphore = new Semaphore(Math.max(1, properties.getMaxConcurrentRequests()), true);
    }

    @Override
    public GatewayHealth checkHealth() {
        return checkHealth(false);
    }

    @Override
    public GatewayHealth checkHealth(boolean bypassCache) {
        Instant now = Instant.now();
        boolean isBusy = gpuSemaphore.availablePermits() == 0;
        if (!properties.isEnabled()) {
            return new GatewayHealth(false, false, false, false, isBusy, 0L, now, List.of());
        }
        CachedHealth current = this.cachedHealth;
        if (!bypassCache && current != null && current.expiresAt().isAfter(now)) {
            GatewayHealth h = current.health();
            return new GatewayHealth(
                    h.reachable(), h.chatModelReady(), h.embedModelReady(),
                    h.chatModelLoaded(), isBusy, h.latencyMs(), h.checkedAt(), h.availableModels()
            );
        }

        long startNs = System.nanoTime();
        try {
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl() + "/api/tags"))
                    .timeout(Duration.ofSeconds(3))
                    .GET()
                    .build();
            HttpResponse<String> res = httpClient.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            long latencyMs = Math.max(1L, (System.nanoTime() - startNs) / 1_000_000L);
            if (res.statusCode() < 200 || res.statusCode() >= 300) {
                GatewayHealth down = new GatewayHealth(false, false, false, false, isBusy, latencyMs, Instant.now(), List.of());
                this.cachedHealth = new CachedHealth(down, Instant.now().plusSeconds(3));
                return down;
            }

            JsonNode root = objectMapper.readTree(res.body());
            List<String> models = new ArrayList<>();
            if (root.has("models") && root.get("models").isArray()) {
                for (JsonNode m : root.get("models")) {
                    String name = m.path("name").asText("");
                    if (!name.isBlank()) {
                        models.add(name);
                    }
                }
            }

            boolean chatReady = matchesModel(models, properties.getChatModel());
            boolean embedReady = matchesModel(models, properties.getEmbedModel());
            boolean chatLoaded = chatReady && isModelLoadedInMemory(properties.getChatModel());

            GatewayHealth up = new GatewayHealth(
                    true, chatReady, embedReady, chatLoaded, isBusy, latencyMs, Instant.now(), List.copyOf(models)
            );
            this.cachedHealth = new CachedHealth(up, Instant.now().plusSeconds(3));
            return up;
        } catch (Exception e) {
            long latencyMs = Math.max(1L, (System.nanoTime() - startNs) / 1_000_000L);
            GatewayHealth down = new GatewayHealth(false, false, false, false, isBusy, latencyMs, Instant.now(), List.of());
            this.cachedHealth = new CachedHealth(down, Instant.now().plusSeconds(3));
            return down;
        }
    }

    private boolean isModelLoadedInMemory(String targetModel) {
        try {
            HttpRequest psReq = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl() + "/api/ps"))
                    .timeout(Duration.ofSeconds(2))
                    .GET()
                    .build();
            HttpResponse<String> psRes = httpClient.send(psReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (psRes.statusCode() < 200 || psRes.statusCode() >= 300) {
                return false;
            }
            JsonNode root = objectMapper.readTree(psRes.body());
            List<String> running = new ArrayList<>();
            if (root.has("models") && root.get("models").isArray()) {
                for (JsonNode m : root.get("models")) {
                    String name = m.path("name").asText("");
                    if (!name.isBlank()) {
                        running.add(name);
                    }
                }
            }
            return matchesModel(running, targetModel);
        } catch (Exception ignored) {
            return false;
        }
    }

    @Override
    public float[] embed(String text) {
        assertEnabled();
        if (text == null || text.isBlank()) {
            throw new IllegalArgumentException("Embedding input text cannot be empty.");
        }

        try {
            Map<String, Object> payload = Map.of(
                    "model", properties.getEmbedModel(),
                    "input", text
            );
            String json = objectMapper.writeValueAsString(payload);
            HttpRequest req = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl() + "/api/embed"))
                    .timeout(Duration.ofSeconds(Math.min(30, Math.max(10, properties.getTimeoutSeconds()))))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> res = httpClient.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() < 200 || res.statusCode() >= 300) {
                throw new AiServiceUnavailableException("Ollama embedding request failed with status " + res.statusCode());
            }

            JsonNode root = objectMapper.readTree(res.body());
            JsonNode vecNode = root.path("embeddings").isArray() && !root.path("embeddings").isEmpty()
                    ? root.path("embeddings").get(0)
                    : root.path("embedding");

            if (!vecNode.isArray() || vecNode.isEmpty()) {
                throw new AiServiceUnavailableException("Ollama returned an empty embedding vector.");
            }

            int expectedDim = properties.getEmbeddingDimension();
            if (vecNode.size() != expectedDim) {
                throw new AiServiceUnavailableException(
                        "Embedding dimension mismatch: expected " + expectedDim + ", got " + vecNode.size()
                );
            }

            float[] vector = new float[vecNode.size()];
            for (int i = 0; i < vecNode.size(); i++) {
                vector[i] = (float) vecNode.get(i).asDouble();
            }
            return vector;
        } catch (AiServiceUnavailableException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Ollama embed unavailable: {}", LogSanitizer.sanitizeMessage(e.getMessage()));
            throw new AiServiceUnavailableException("Local embedding model is unreachable.", e);
        }
    }

    @Override
    public GatewayChatResponse chat(GatewayChatRequest request) {
        assertEnabled();
        acquireGpuPermit();
        try {
            String body = buildChatPayload(request, false);
            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl() + "/api/chat"))
                    .timeout(Duration.ofSeconds(Math.max(15, properties.getTimeoutSeconds())))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<String> res = httpClient.send(httpReq, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            if (res.statusCode() < 200 || res.statusCode() >= 300) {
                throw new AiServiceUnavailableException("Ollama chat request returned HTTP " + res.statusCode());
            }

            JsonNode root = objectMapper.readTree(res.body());
            JsonNode msg = root.path("message");
            String content = msg.path("content").asText("");
            String thinking = msg.path("thinking").asText("");
            List<GatewayToolCall> toolCalls = parseToolCalls(msg.path("tool_calls"));
            int promptTokens = root.path("prompt_eval_count").asInt(0);
            int completionTokens = root.path("eval_count").asInt(0);
            String usedModel = root.path("model").asText(request.model());

            return new GatewayChatResponse(content, toolCalls, promptTokens, completionTokens, usedModel, thinking);
        } catch (AiServiceUnavailableException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Ollama chat failed: {}", LogSanitizer.sanitizeMessage(e.getMessage()));
            throw new AiServiceUnavailableException(
                    "Local AI runtime (Ollama) is not reachable or timed out. Make sure Ollama is running with model '"
                            + properties.getChatModel() + "'.", e
            );
        } finally {
            gpuSemaphore.release();
        }
    }

    @Override
    public GatewayChatResponse chatStream(GatewayChatRequest request, Consumer<String> onDelta) {
        return chatStream(request, onDelta, null);
    }

    @Override
    public GatewayChatResponse chatStream(
            GatewayChatRequest request,
            Consumer<String> onDelta,
            Consumer<String> onThought
    ) {
        assertEnabled();
        acquireGpuPermit();
        try {
            String body = buildChatPayload(request, true);
            HttpRequest httpReq = HttpRequest.newBuilder()
                    .uri(URI.create(baseUrl() + "/api/chat"))
                    .timeout(Duration.ofSeconds(Math.max(20, properties.getTimeoutSeconds())))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8))
                    .build();

            HttpResponse<InputStream> res = httpClient.send(httpReq, HttpResponse.BodyHandlers.ofInputStream());
            if (res.statusCode() < 200 || res.statusCode() >= 300) {
                throw new AiServiceUnavailableException("Ollama streaming chat returned HTTP " + res.statusCode());
            }

            StringBuilder fullContent = new StringBuilder();
            StringBuilder fullThinking = new StringBuilder();
            List<GatewayToolCall> toolCalls = new ArrayList<>();
            int promptTokens = 0;
            int completionTokens = 0;
            String usedModel = request.model();

            try (BufferedReader reader = new BufferedReader(new InputStreamReader(res.body(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.isBlank()) continue;
                    JsonNode chunk = objectMapper.readTree(line);
                    if (chunk.has("error")) {
                        throw new AiServiceUnavailableException("Ollama error: " + chunk.path("error").asText());
                    }
                    JsonNode msg = chunk.path("message");
                    String thoughtDelta = msg.path("thinking").asText("");
                    if (!thoughtDelta.isEmpty()) {
                        fullThinking.append(thoughtDelta);
                        if (onThought != null) {
                            onThought.accept(thoughtDelta);
                        }
                    }
                    String delta = msg.path("content").asText("");
                    if (!delta.isEmpty()) {
                        fullContent.append(delta);
                        if (onDelta != null) {
                            onDelta.accept(delta);
                        }
                    }
                    List<GatewayToolCall> chunkCalls = parseToolCalls(msg.path("tool_calls"));
                    if (!chunkCalls.isEmpty()) {
                        toolCalls.addAll(chunkCalls);
                    }
                    if (chunk.path("done").asBoolean(false)) {
                        promptTokens = chunk.path("prompt_eval_count").asInt(promptTokens);
                        completionTokens = chunk.path("eval_count").asInt(completionTokens);
                        usedModel = chunk.path("model").asText(usedModel);
                    }
                }
            }

            return new GatewayChatResponse(
                    fullContent.toString(), toolCalls, promptTokens, completionTokens, usedModel, fullThinking.toString()
            );
        } catch (AiServiceUnavailableException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Ollama streaming failed: {}", LogSanitizer.sanitizeMessage(e.getMessage()));
            throw new AiServiceUnavailableException(
                    "Local AI runtime (Ollama) is not reachable or interrupted during streaming.", e
            );
        } finally {
            gpuSemaphore.release();
        }
    }

    private String buildChatPayload(GatewayChatRequest request, boolean stream) throws Exception {
        Map<String, Object> root = new LinkedHashMap<>();
        root.put("model", request.model());
        root.put("stream", stream);
        root.put("think", request.thinkingEnabled() || properties.isThinkingEnabled());
        root.put("keep_alive", "15m");

        List<Map<String, Object>> msgList = new ArrayList<>();
        for (GatewayMessage m : request.messages()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("role", m.role());
            item.put("content", m.content() != null ? m.content() : "");
            if (m.toolName() != null && !m.toolName().isBlank()) {
                item.put("tool_name", m.toolName());
            }
            if (m.images() != null && !m.images().isEmpty()) {
                item.put("images", m.images());
            }
            if (m.toolCalls() != null && !m.toolCalls().isEmpty()) {
                List<Map<String, Object>> tcList = new ArrayList<>();
                for (GatewayToolCall tc : m.toolCalls()) {
                    tcList.add(Map.of(
                            "type", "function",
                            "function", Map.of(
                                    "name", tc.name(),
                                    "arguments", tc.arguments() != null ? tc.arguments() : Map.of()
                            )
                    ));
                }
                item.put("tool_calls", tcList);
            }
            msgList.add(item);
        }
        root.put("messages", msgList);

        if (request.tools() != null && !request.tools().isEmpty()) {
            List<Map<String, Object>> tools = new ArrayList<>();
            for (GatewayToolDefinition def : request.tools()) {
                tools.add(Map.of(
                        "type", "function",
                        "function", Map.of(
                                "name", def.name(),
                                "description", def.description(),
                                "parameters", def.parametersSchema()
                        )
                ));
            }
            root.put("tools", tools);
        }

        Map<String, Object> options = new LinkedHashMap<>();
        options.put("num_ctx", request.numCtx() > 0 ? request.numCtx() : properties.getNumCtx());
        options.put("num_predict", request.maxTokens() > 0 ? request.maxTokens() : properties.getMaxOutputTokens());
        options.put("temperature", 0.2);
        root.put("options", options);

        return objectMapper.writeValueAsString(root);
    }

    @SuppressWarnings("unchecked")
    private List<GatewayToolCall> parseToolCalls(JsonNode callsNode) {
        if (callsNode == null || !callsNode.isArray() || callsNode.isEmpty()) {
            return List.of();
        }
        List<GatewayToolCall> calls = new ArrayList<>();
        for (JsonNode entry : callsNode) {
            JsonNode fn = entry.has("function") ? entry.get("function") : entry;
            String name = fn.path("name").asText("");
            if (name.isBlank()) continue;

            Map<String, Object> args = Map.of();
            JsonNode argsNode = fn.get("arguments");
            if (argsNode != null) {
                try {
                    if (argsNode.isObject()) {
                        args = objectMapper.convertValue(argsNode, Map.class);
                    } else if (argsNode.isTextual() && !argsNode.asText().isBlank()) {
                        args = objectMapper.readValue(argsNode.asText(), Map.class);
                    }
                } catch (Exception ignored) {
                    args = Map.of();
                }
            }
            calls.add(new GatewayToolCall(name, args != null ? args : Map.of()));
        }
        return calls;
    }

    private void assertEnabled() {
        if (!properties.isEnabled()) {
            throw new AiServiceUnavailableException("AFAB AI Copilot is disabled by configuration.");
        }
    }

    private void acquireGpuPermit() {
        try {
            long waitSeconds = Math.max(10L, properties.getTimeoutSeconds());
            if (!gpuSemaphore.tryAcquire(waitSeconds, TimeUnit.SECONDS)) {
                throw new AiServiceUnavailableException("AI worker queue is busy. Please try again in a few seconds.");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new AiServiceUnavailableException("Interrupted while waiting for AI runtime slot.", e);
        }
    }

    private boolean matchesModel(List<String> available, String expected) {
        if (expected == null || expected.isBlank()) return false;
        String target = expected.trim().toLowerCase(Locale.ROOT);
        for (String name : available) {
            String lower = name.trim().toLowerCase(Locale.ROOT);
            if (lower.equals(target) || (!target.contains(":") && lower.equals(target + ":latest"))) {
                return true;
            }
        }
        return false;
    }

    private String baseUrl() {
        String url = properties.getOllamaBaseUrl();
        if (url == null || url.isBlank()) {
            return "http://localhost:11434";
        }
        return url.replaceAll("/+$", "");
    }
}
