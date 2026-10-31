package com.afab.reports;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.finance.repository.TransactionRepository;
import com.afab.reports.dto.CashFlowReportDTO;
import com.afab.reports.dto.ComparisonReportDTO;
import com.afab.reports.dto.ProfitAndLossReportDTO;
import com.afab.reports.service.CsvReportExporter;
import com.afab.reports.service.PdfReportExporter;
import com.afab.reports.service.ReportService;
import com.afab.subscription.EntitlementService;
import com.afab.subscription.PlanLimitReachedException;
import com.afab.subscription.dto.SubscriptionSnapshotDTO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ReportServiceTest {

    @Mock
    private CurrentBusinessService currentBusinessService;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private EntitlementService entitlementService;

    private CsvReportExporter csvReportExporter;
    private PdfReportExporter pdfReportExporter;
    private ReportService reportService;

    private Business testBusiness;
    private final String testEmail = "ceo@example.com";

    @BeforeEach
    void setUp() {
        csvReportExporter = new CsvReportExporter();
        pdfReportExporter = new PdfReportExporter();
        reportService = new ReportService(
                currentBusinessService,
                transactionRepository,
                entitlementService,
                csvReportExporter,
                pdfReportExporter
        );

        testBusiness = new Business();
        testBusiness.setId(UUID.randomUUID());
        testBusiness.setName("Atlas Ventures");
        testBusiness.setCurrency("USD");
    }

    @Test
    void testProfitAndLossCalculation() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "advanced"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("10000.00"));

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("4000.00"));

        List<Object[]> incomeBreakdown = List.<Object[]>of(
                new Object[]{"Consulting", "#10b981", new BigDecimal("10000.00")}
        );
        when(transactionRepository.findCategoryBreakdownByType(
                eq(testBusiness.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(incomeBreakdown);

        List<Object[]> expenseBreakdown = List.<Object[]>of(
                new Object[]{"Hosting", "#ef4444", new BigDecimal("2500.00")},
                new Object[]{"Office", "#6366f1", new BigDecimal("1500.00")}
        );
        when(transactionRepository.findCategoryBreakdownByType(
                eq(testBusiness.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(expenseBreakdown);

        ProfitAndLossReportDTO pnl = reportService.getProfitAndLoss("this_month", null, null, testEmail);

        assertNotNull(pnl);
        assertEquals(new BigDecimal("10000.00"), pnl.getTotalRevenue());
        assertEquals(new BigDecimal("4000.00"), pnl.getTotalExpenses());
        assertEquals(new BigDecimal("6000.00"), pnl.getNetOperatingIncome());
        assertEquals(60.0, pnl.getProfitMarginPct(), 0.01);
        assertEquals(1, pnl.getRevenueBreakdown().size());
        assertEquals(2, pnl.getExpenseBreakdown().size());
    }

    @Test
    void testCashFlowStatement() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "basic"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("7500.00"));

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("3500.00"));

        CashFlowReportDTO cashFlow = reportService.getCashFlow("this_month", null, null, testEmail);

        assertNotNull(cashFlow);
        assertEquals(new BigDecimal("7500.00"), cashFlow.getCashInflow());
        assertEquals(new BigDecimal("3500.00"), cashFlow.getCashOutflow());
        assertEquals(new BigDecimal("4000.00"), cashFlow.getNetCashChange());
        assertEquals(6, cashFlow.getMonthlyTrend().size());
    }

    @Test
    void testPeriodComparison() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "advanced"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        // Primary period
        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("INCOME"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("12000.00"), new BigDecimal("10000.00")); // Primary, then Comparison

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                eq(testBusiness.getId()), eq("EXPENSE"), any(LocalDate.class), any(LocalDate.class)
        )).thenReturn(new BigDecimal("4000.00"), new BigDecimal("5000.00")); // Primary, then Comparison

        ComparisonReportDTO comparison = reportService.getComparison("this_month", "last_month", testEmail);

        assertNotNull(comparison);
        assertEquals(new BigDecimal("12000.00"), comparison.getPrimaryRevenue());
        assertEquals(new BigDecimal("10000.00"), comparison.getComparisonRevenue());
        assertEquals(new BigDecimal("2000.00"), comparison.getRevenueDifference());
        assertEquals(20.0, comparison.getRevenueDifferencePct(), 0.01);
    }

    @Test
    void testReportLevelGate_BasicUserRequestingAnnualReportThrows() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "basic"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        PlanLimitReachedException ex = assertThrows(PlanLimitReachedException.class, () ->
                reportService.getProfitAndLoss("this_year", null, null, testEmail)
        );

        assertEquals("reports.level", ex.getFeature());
        assertEquals("plus", ex.getUpgradeTo());
    }

    @Test
    void testReportLevelGate_CustomRangeRequiresPro() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "advanced")); // Plus tier
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        PlanLimitReachedException ex = assertThrows(PlanLimitReachedException.class, () ->
                reportService.getProfitAndLoss("custom", LocalDate.now().minusDays(10), LocalDate.now(), testEmail)
        );

        assertEquals("reports.level", ex.getFeature());
        assertEquals("pro", ex.getUpgradeTo());
    }

    @Test
    void testExportCsv_ConsumesQuotaAndGeneratesUtf8Bom() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "advanced"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                any(), any(), any(), any()
        )).thenReturn(new BigDecimal("5000.00"));

        byte[] csvBytes = reportService.exportCsv("this_month", null, null, testEmail);

        // Verify quota consumed
        verify(entitlementService, times(1)).consume(testEmail, "export.per_month", 1);

        assertNotNull(csvBytes);
        assertTrue(csvBytes.length > 0);
        // Verify UTF-8 BOM bytes (0xEF, 0xBB, 0xBF)
        assertEquals((byte) 0xEF, csvBytes[0]);
        assertEquals((byte) 0xBB, csvBytes[1]);
        assertEquals((byte) 0xBF, csvBytes[2]);
    }

    @Test
    void testExportPdf_ConsumesQuotaAndGeneratesValidPdf() {
        when(currentBusinessService.getCurrentBusiness(testEmail)).thenReturn(testBusiness);

        SubscriptionSnapshotDTO snapshot = new SubscriptionSnapshotDTO();
        snapshot.setEntitlements(Map.of("reports.level", "advanced"));
        when(entitlementService.getEntitlementsSnapshot(testEmail)).thenReturn(snapshot);

        when(transactionRepository.sumCompletedAmountByBusinessAndTypeAndDateRange(
                any(), any(), any(), any()
        )).thenReturn(new BigDecimal("5000.00"));

        byte[] pdfBytes = reportService.exportPdf("this_month", null, null, testEmail);

        // Verify quota consumed
        verify(entitlementService, times(1)).consume(testEmail, "export.per_month", 1);

        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 10);
        // Verify PDF Magic Bytes (%PDF-)
        String header = new String(pdfBytes, 0, 5);
        assertEquals("%PDF-", header);
    }
}
