package com.afab.ai.rag;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.*;

/**
 * PostgreSQL + pgvector + tsvector Hybrid RRF Repository.
 * Enforces mandatory SQL WHERE business_id = ? BEFORE vector/lexical ranking
 * and re-verifies tenant ownership on every returned row in Java.
 */
@Repository
public class AiVectorRepository {

    public record RetrievedMemory(
            UUID id,
            UUID businessId,
            String memoryType,
            String title,
            String content,
            String sourceType,
            UUID sourceId,
            double score
    ) {}

    public record RetrievedChunk(
            UUID id,
            UUID businessId,
            String sourceType,
            UUID sourceId,
            String title,
            String content,
            double score
    ) {}

    private final JdbcTemplate jdbcTemplate;

    public AiVectorRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public boolean memoryHasVector(UUID memoryId, UUID businessId) {
        Boolean exists = jdbcTemplate.queryForObject(
                "SELECT (embedding IS NOT NULL) FROM business_memory WHERE id = ? AND business_id = ?",
                Boolean.class,
                memoryId, businessId
        );
        return Boolean.TRUE.equals(exists);
    }

    public Set<UUID> findMemoryIdsWithVectors(UUID businessId) {
        List<UUID> ids = jdbcTemplate.query(
                "SELECT id FROM business_memory WHERE business_id = ? AND status = 'APPROVED' AND embedding IS NOT NULL",
                (rs, rowNum) -> UUID.fromString(rs.getString("id")),
                businessId
        );
        return new HashSet<>(ids);
    }

    public void upsertMemoryVector(UUID memoryId, UUID businessId, float[] vector, String modelId, int dim) {
        String literal = toPgVectorLiteral(vector, dim);
        jdbcTemplate.update(
                "UPDATE business_memory SET embedding = CAST(? AS vector), model_id = ?, dimension = ?, updated_at = NOW() " +
                "WHERE id = ? AND business_id = ?",
                literal, modelId, dim, memoryId, businessId
        );
    }

    public String findChunkContentHash(UUID businessId, String sourceType, UUID sourceId) {
        List<String> hashes = jdbcTemplate.query(
                "SELECT content_hash FROM ai_rag_chunks WHERE business_id = ? AND source_type = ? AND source_id = ?",
                (rs, rowNum) -> rs.getString("content_hash"),
                businessId, sourceType, sourceId
        );
        return hashes.isEmpty() ? null : hashes.get(0);
    }

    public boolean chunkHasVector(UUID businessId, String sourceType, UUID sourceId) {
        List<Boolean> flags = jdbcTemplate.query(
                "SELECT (embedding IS NOT NULL) AS has_vec FROM ai_rag_chunks WHERE business_id = ? AND source_type = ? AND source_id = ?",
                (rs, rowNum) -> rs.getBoolean("has_vec"),
                businessId, sourceType, sourceId
        );
        return !flags.isEmpty() && Boolean.TRUE.equals(flags.get(0));
    }

    public void upsertChunk(
            UUID businessId,
            String sourceType,
            UUID sourceId,
            String title,
            String content,
            String contentHash,
            float[] vectorOrNull,
            String modelId,
            Integer dim
    ) {
        if (vectorOrNull != null && dim != null) {
            String literal = toPgVectorLiteral(vectorOrNull, dim);
            jdbcTemplate.update(
                    "INSERT INTO ai_rag_chunks (id, business_id, source_type, source_id, title, content, content_hash, embedding, model_id, dimension, updated_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, CAST(? AS vector), ?, ?, NOW()) " +
                    "ON CONFLICT (business_id, source_type, source_id) DO UPDATE SET " +
                    "title = EXCLUDED.title, content = EXCLUDED.content, content_hash = EXCLUDED.content_hash, " +
                    "embedding = EXCLUDED.embedding, model_id = EXCLUDED.model_id, dimension = EXCLUDED.dimension, updated_at = NOW()",
                    UUID.randomUUID(), businessId, sourceType, sourceId, title, content, contentHash, literal, modelId, dim
            );
        } else {
            jdbcTemplate.update(
                    "INSERT INTO ai_rag_chunks (id, business_id, source_type, source_id, title, content, content_hash, embedding, model_id, dimension, updated_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL, NOW()) " +
                    "ON CONFLICT (business_id, source_type, source_id) DO UPDATE SET " +
                    "title = EXCLUDED.title, content = EXCLUDED.content, content_hash = EXCLUDED.content_hash, updated_at = NOW()",
                    UUID.randomUUID(), businessId, sourceType, sourceId, title, content, contentHash
            );
        }
    }

    public void deleteChunk(UUID businessId, String sourceType, UUID sourceId) {
        jdbcTemplate.update(
                "DELETE FROM ai_rag_chunks WHERE business_id = ? AND source_type = ? AND source_id = ?",
                businessId, sourceType, sourceId
        );
    }

    public long countChunks(UUID businessId) {
        Long count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM ai_rag_chunks WHERE business_id = ?",
                Long.class,
                businessId
        );
        return count != null ? count : 0L;
    }

    public List<RetrievedMemory> searchApprovedMemoriesHybrid(
            UUID businessId,
            float[] queryVectorOrNull,
            String queryText,
            int limit,
            int expectedDim
    ) {
        int safeLimit = Math.min(15, Math.max(1, limit));
        String safeLike = buildLikePattern(queryText);
        String cleanQuery = queryText != null ? queryText.trim() : "";

        List<RetrievedMemory> rows;
        if (queryVectorOrNull != null) {
            String literal = toPgVectorLiteral(queryVectorOrNull, expectedDim);
            String sql = """
                    WITH vec AS (
                        SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> CAST(? AS vector) ASC) AS rn
                        FROM business_memory
                        WHERE business_id = ? AND status = 'APPROVED' AND embedding IS NOT NULL
                          AND (expires_at IS NULL OR expires_at > NOW())
                        ORDER BY embedding <=> CAST(? AS vector) ASC
                        LIMIT 15
                    ),
                    lex AS (
                        SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(to_tsvector('simple', coalesce(title,'') || ' ' || content), plainto_tsquery('simple', ?)) DESC, updated_at DESC) AS rn
                        FROM business_memory
                        WHERE business_id = ? AND status = 'APPROVED'
                          AND (expires_at IS NULL OR expires_at > NOW())
                          AND (
                            to_tsvector('simple', coalesce(title,'') || ' ' || content) @@ plainto_tsquery('simple', ?)
                            OR LOWER(coalesce(title,'') || ' ' || content) LIKE LOWER(?)
                          )
                        LIMIT 15
                    ),
                    fused AS (
                        SELECT COALESCE(vec.id, lex.id) AS id,
                               (COALESCE(1.0 / (60.0 + vec.rn), 0.0) + COALESCE(1.0 / (60.0 + lex.rn), 0.0)) AS rrf_score
                        FROM vec
                        FULL OUTER JOIN lex ON vec.id = lex.id
                    )
                    SELECT m.id, m.business_id, m.memory_type, m.title, m.content, m.source_type, m.source_id, f.rrf_score
                    FROM fused f
                    JOIN business_memory m ON m.id = f.id
                    WHERE m.business_id = ? AND m.status = 'APPROVED'
                    ORDER BY f.rrf_score DESC, m.updated_at DESC
                    LIMIT ?
                    """;
            rows = jdbcTemplate.query(
                    sql,
                    (rs, idx) -> new RetrievedMemory(
                            UUID.fromString(rs.getString("id")),
                            UUID.fromString(rs.getString("business_id")),
                            rs.getString("memory_type"),
                            rs.getString("title"),
                            rs.getString("content"),
                            rs.getString("source_type"),
                            rs.getString("source_id") != null ? UUID.fromString(rs.getString("source_id")) : null,
                            rs.getDouble("rrf_score")
                    ),
                    literal, businessId, literal,
                    cleanQuery, businessId, cleanQuery, safeLike,
                    businessId, safeLimit
            );
        } else {
            String sql = """
                    SELECT id, business_id, memory_type, title, content, source_type, source_id, 1.0 AS score
                    FROM business_memory
                    WHERE business_id = ? AND status = 'APPROVED'
                      AND (expires_at IS NULL OR expires_at > NOW())
                      AND (
                        ? = ''
                        OR to_tsvector('simple', coalesce(title,'') || ' ' || content) @@ plainto_tsquery('simple', ?)
                        OR LOWER(coalesce(title,'') || ' ' || content) LIKE LOWER(?)
                      )
                    ORDER BY updated_at DESC
                    LIMIT ?
                    """;
            rows = jdbcTemplate.query(
                    sql,
                    (rs, idx) -> new RetrievedMemory(
                            UUID.fromString(rs.getString("id")),
                            UUID.fromString(rs.getString("business_id")),
                            rs.getString("memory_type"),
                            rs.getString("title"),
                            rs.getString("content"),
                            rs.getString("source_type"),
                            rs.getString("source_id") != null ? UUID.fromString(rs.getString("source_id")) : null,
                            rs.getDouble("score")
                    ),
                    businessId, cleanQuery, cleanQuery, safeLike, safeLimit
            );
        }

        // Defense-in-depth Java tenant boundary verification
        return rows.stream().filter(r -> businessId.equals(r.businessId())).toList();
    }

    public List<RetrievedChunk> searchRagChunksHybrid(
            UUID businessId,
            float[] queryVectorOrNull,
            String queryText,
            int limit,
            int expectedDim
    ) {
        int safeLimit = Math.min(20, Math.max(1, limit));
        String safeLike = buildLikePattern(queryText);
        String cleanQuery = queryText != null ? queryText.trim() : "";

        List<RetrievedChunk> rows;
        if (queryVectorOrNull != null) {
            String literal = toPgVectorLiteral(queryVectorOrNull, expectedDim);
            String sql = """
                    WITH vec AS (
                        SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> CAST(? AS vector) ASC) AS rn
                        FROM ai_rag_chunks
                        WHERE business_id = ? AND embedding IS NOT NULL
                        ORDER BY embedding <=> CAST(? AS vector) ASC
                        LIMIT 20
                    ),
                    lex AS (
                        SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(to_tsvector('simple', coalesce(title,'') || ' ' || content), plainto_tsquery('simple', ?)) DESC, updated_at DESC) AS rn
                        FROM ai_rag_chunks
                        WHERE business_id = ?
                          AND (
                            to_tsvector('simple', coalesce(title,'') || ' ' || content) @@ plainto_tsquery('simple', ?)
                            OR LOWER(coalesce(title,'') || ' ' || content) LIKE LOWER(?)
                          )
                        LIMIT 20
                    ),
                    fused AS (
                        SELECT COALESCE(vec.id, lex.id) AS id,
                               (COALESCE(1.0 / (60.0 + vec.rn), 0.0) + COALESCE(1.0 / (60.0 + lex.rn), 0.0)) AS rrf_score
                        FROM vec
                        FULL OUTER JOIN lex ON vec.id = lex.id
                    )
                    SELECT c.id, c.business_id, c.source_type, c.source_id, c.title, c.content, f.rrf_score
                    FROM fused f
                    JOIN ai_rag_chunks c ON c.id = f.id
                    WHERE c.business_id = ?
                    ORDER BY f.rrf_score DESC, c.updated_at DESC
                    LIMIT ?
                    """;
            rows = jdbcTemplate.query(
                    sql,
                    (rs, idx) -> new RetrievedChunk(
                            UUID.fromString(rs.getString("id")),
                            UUID.fromString(rs.getString("business_id")),
                            rs.getString("source_type"),
                            UUID.fromString(rs.getString("source_id")),
                            rs.getString("title"),
                            rs.getString("content"),
                            rs.getDouble("rrf_score")
                    ),
                    literal, businessId, literal,
                    cleanQuery, businessId, cleanQuery, safeLike,
                    businessId, safeLimit
            );
        } else {
            String sql = """
                    SELECT id, business_id, source_type, source_id, title, content, 1.0 AS score
                    FROM ai_rag_chunks
                    WHERE business_id = ?
                      AND (
                        ? = ''
                        OR to_tsvector('simple', coalesce(title,'') || ' ' || content) @@ plainto_tsquery('simple', ?)
                        OR LOWER(coalesce(title,'') || ' ' || content) LIKE LOWER(?)
                      )
                    ORDER BY updated_at DESC
                    LIMIT ?
                    """;
            rows = jdbcTemplate.query(
                    sql,
                    (rs, idx) -> new RetrievedChunk(
                            UUID.fromString(rs.getString("id")),
                            UUID.fromString(rs.getString("business_id")),
                            rs.getString("source_type"),
                            UUID.fromString(rs.getString("source_id")),
                            rs.getString("title"),
                            rs.getString("content"),
                            rs.getDouble("score")
                    ),
                    businessId, cleanQuery, cleanQuery, safeLike, safeLimit
            );
        }

        // Defense-in-depth Java tenant boundary verification
        return rows.stream().filter(r -> businessId.equals(r.businessId())).toList();
    }

    public static String toPgVectorLiteral(float[] vector, int expectedDim) {
        if (vector == null || vector.length != expectedDim) {
            throw new IllegalArgumentException("Expected embedding vector of dimension " + expectedDim);
        }
        StringBuilder sb = new StringBuilder(vector.length * 10);
        sb.append('[');
        for (int i = 0; i < vector.length; i++) {
            if (i > 0) sb.append(',');
            float v = vector[i];
            if (!Float.isFinite(v)) {
                throw new IllegalArgumentException("Embedding vector contains non-finite value at index " + i);
            }
            sb.append(String.format(Locale.US, "%.6f", v));
        }
        sb.append(']');
        return sb.toString();
    }

    public static String sha256Hex(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest((input != null ? input : "").getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 unavailable", e);
        }
    }

    private String buildLikePattern(String queryText) {
        if (queryText == null || queryText.isBlank()) {
            return "%";
        }
        String sanitized = queryText.trim()
                .replace("\\", "")
                .replace("%", "")
                .replace("_", "");
        String[] tokens = sanitized.split("\\s+");
        if (tokens.length == 0) {
            return "%";
        }
        // Match on the most informative longest keyword so short filler words don't narrow out hits
        String longest = tokens[0];
        for (String t : tokens) {
            if (t.length() > longest.length()) {
                longest = t;
            }
        }
        return longest.length() > 64 ? "%" + longest.substring(0, 64) + "%" : "%" + longest + "%";
    }
}
