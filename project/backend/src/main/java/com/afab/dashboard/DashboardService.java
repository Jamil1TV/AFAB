package com.afab.dashboard;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.finance.stats.FinanceStatsService;
import org.springframework.stereotype.Service;

/**
 * Dashboard Service — builds real financial summary data for the authenticated user.
 * Phase 2: Fully connected to real transaction data via FinanceStatsService (Cash basis).
 */
@Service
public class DashboardService {

    private final CurrentBusinessService currentBusinessService;
    private final FinanceStatsService financeStatsService;

    public DashboardService(CurrentBusinessService currentBusinessService, FinanceStatsService financeStatsService) {
        this.currentBusinessService = currentBusinessService;
        this.financeStatsService = financeStatsService;
    }

    public DashboardSummaryDTO getSummary(String userEmail) {
        return getSummary(userEmail, "month");
    }

    public DashboardSummaryDTO getSummary(String userEmail, String period) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return financeStatsService.buildDashboardSummary(business, period);
    }
}
