package com.tracker.api.controller;

import com.tracker.api.dto.DetectionListResponse;
import com.tracker.api.dto.DetectionResponse;
import com.tracker.api.service.DetectionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(DetectionController.class)
class DetectionControllerTest {

    @Autowired MockMvc mockMvc;
    @MockitoBean DetectionService detectionService;

    @Test
    void getDetections_returnsOk() throws Exception {
        var mockDetection = new DetectionResponse(1L, true, "매크로_판매", 0.95,
                "이유", "원문", null, "http://example.com", "tailstar.net", "zh-CN",
                "2026-04-24T14:30:00Z");
        when(detectionService.getDetections(any(), any(), any(), any(), eq(0), eq(20)))
                .thenReturn(new DetectionListResponse(List.of(mockDetection), 0, 20, 1L));

        mockMvc.perform(get("/api/detections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isArray())
                .andExpect(jsonPath("$.totalElements").value(1))
                .andExpect(jsonPath("$.content[0].isIllegal").value(true))
                .andExpect(jsonPath("$.content[0].detectedAt").value("2026-04-24T14:30:00Z"))
                .andExpect(header().exists("X-Correlation-ID"));
    }

    @Test
    void getDetections_emptyResult_returns200() throws Exception {
        when(detectionService.getDetections(any(), any(), any(), any(), eq(0), eq(20)))
                .thenReturn(new DetectionListResponse(List.of(), 0, 20, 0L));

        mockMvc.perform(get("/api/detections"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content").isEmpty())
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void getDetections_invalidDateFormat_returns400ProblemDetail() throws Exception {
        mockMvc.perform(get("/api/detections").param("date", "not-a-date"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("INVALID_FILTER_PARAM"))
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void getDetections_invalidPage_returns400ProblemDetail() throws Exception {
        mockMvc.perform(get("/api/detections").param("page", "-1"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errorCode").value("INVALID_FILTER_PARAM"))
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void getDetections_passesFilterParametersToService() throws Exception {
        when(detectionService.getDetections(
                eq(LocalDate.of(2026, 4, 24)),
                eq("tailstar.net"),
                eq("매크로_판매"),
                eq("ko"),
                eq(1),
                eq(10)))
                .thenReturn(new DetectionListResponse(List.of(), 1, 10, 0L));

        mockMvc.perform(get("/api/detections")
                        .param("date", "2026-04-24")
                        .param("site", "tailstar.net")
                        .param("type", "매크로_판매")
                        .param("lang", "ko")
                        .param("page", "1")
                        .param("size", "10"))
                .andExpect(status().isOk());

        verify(detectionService).getDetections(
                LocalDate.of(2026, 4, 24),
                "tailstar.net",
                "매크로_판매",
                "ko",
                1,
                10);
    }
}
