package com.afab.reports.controller;

import com.afab.reports.dto.CashFlowReportDTO;
import com.afab.reports.dto.ComparisonReportDTO;
import com.afab.reports.dto.ProfitAndLossReportDTO;
import com.afab.reports.service.ReportService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    /**
     * GET /api/v1/reports/profit-loss
     */
    @GetMapping("/profit-loss")
    public ResponseEntity<ProfitAndLossReportDTO> getProfitAndLoss(
            @RequestParam(required = false, defaultValue = "this_month") String period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication
    ) {
        ProfitAndLossReportDTO report = reportService.getProfitAndLoss(period, startDate, endDate, authentication.getName());
        return ResponseEntity.ok(report);
    }

    /**
     * GET /api/v1/reports/cash-flow
     */
    @GetMapping("/cash-flow")
    public ResponseEntity<CashFlowReportDTO> getCashFlow(
            @RequestParam(required = false, defaultValue = "this_month") String period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication
    ) {
        CashFlowReportDTO report = reportService.getCashFlow(period, startDate, endDate, authentication.getName());
        return ResponseEntity.ok(report);
    }

    /**
     * GET /api/v1/reports/comparison
     */
    @GetMapping("/comparison")
    public ResponseEntity<ComparisonReportDTO> getComparison(
            @RequestParam(required = false, defaultValue = "this_month") String primaryPeriod,
            @RequestParam(required = false, defaultValue = "last_month") String comparisonPeriod,
            Authentication authentication
    ) {
        ComparisonReportDTO report = reportService.getComparison(primaryPeriod, comparisonPeriod, authentication.getName());
        return ResponseEntity.ok(report);
    }

    /**
     * GET /api/v1/reports/export/csv — exports report as RFC 4180 CSV (UTF-8 BOM).
     * Consumes 1 unit of user's monthly export quota.
     */
    @GetMapping("/export/csv")
    public ResponseEntity<byte[]> exportCsv(
            @RequestParam(required = false, defaultValue = "this_month") String period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication
    ) {
        byte[] csvBytes = reportService.exportCsv(period, startDate, endDate, authentication.getName());
        String filename = "AFAB-report-" + period + ".csv";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csvBytes);
    }

    /**
     * GET /api/v1/reports/export/pdf — exports branded financial statement PDF.
     * Consumes 1 unit of user's monthly export quota.
     */
    @GetMapping("/export/pdf")
    public ResponseEntity<byte[]> exportPdf(
            @RequestParam(required = false, defaultValue = "this_month") String period,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            Authentication authentication
    ) {
        byte[] pdfBytes = reportService.exportPdf(period, startDate, endDate, authentication.getName());
        String filename = "AFAB-statement-" + period + ".pdf";

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdfBytes);
    }
}
