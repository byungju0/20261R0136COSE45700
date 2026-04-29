package com.tracker.api.dto;

import java.util.List;

public record DetectionListResponse(
        List<DetectionResponse> content,
        int page,
        int size,
        long totalElements
) {}
