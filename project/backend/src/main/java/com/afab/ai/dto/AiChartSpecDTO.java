package com.afab.ai.dto;

import java.util.List;
import java.util.Map;

public record AiChartSpecDTO(
        String id,
        String chartType, // "bar" | "line" | "area" | "donut"
        String title,
        String subtitle,
        String currency,
        String xKey,
        List<SeriesSpec> series,
        List<Map<String, Object>> data
) {
    public record SeriesSpec(
            String key,
            String label,
            String colorToken // "primary" | "emerald" | "rose" | "amber" | "sky"
    ) {}
}
