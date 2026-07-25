package com.afab.dashboard;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.dashboard.dto.DashboardSummaryDTO.*;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.stereotype.Service;

import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.*;

/**
 * Dashboard Service — builds the summary data for the authenticated user.
 * In Phase 2 (current), all financial KPIs are zero since no income/expense tables exist yet.
 * Phase 3 will upgrade this to aggregate real financial data with SQL queries.
 */
@Service
public class DashboardService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;

    public DashboardService(UserRepository userRepository, BusinessRepository businessRepository) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
    }

    public DashboardSummaryDTO getSummary(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Business business = businessRepository.findByUserId(user.getId()).orElse(null);

        String currency = (business != null && business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD";
        String businessName = (business != null && business.getName() != null) ? business.getName() : "My Business";

        String currencySymbol = getCurrencySymbol(currency);

        // ── KPI Data (zeroed for new users) ────────────────
        KpiMetric revenue = new KpiMetric(currencySymbol + "0.00", "0.0%", true);
        KpiMetric expenses = new KpiMetric(currencySymbol + "0.00", "0.0%", true);
        KpiMetric profit = new KpiMetric(currencySymbol + "0.00", "0.0%", true);
        KpiMetric cashFlow = new KpiMetric(currencySymbol + "0.00", "0.0%", true);
        KpiData kpiData = new KpiData(revenue, expenses, profit, cashFlow);

        // ── Revenue Chart (last 6 months, all zeroed) ──────
        List<RevenueDataPoint> revenueData = new ArrayList<>();
        LocalDate now = LocalDate.now();
        for (int i = 5; i >= 0; i--) {
            LocalDate month = now.minusMonths(i);
            String monthName = month.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            revenueData.add(new RevenueDataPoint(monthName, 0.0, 0.0));
        }

        // ── Empty lists (no finance data yet) ──────────────
        List<TransactionItem> transactions = List.of();
        List<ExpenseCategory> expenseCategories = List.of();
        List<ReminderItem> reminders = List.of();
        List<CustomerItem> customers = List.of();

        return new DashboardSummaryDTO(
                kpiData,
                revenueData,
                transactions,
                expenseCategories,
                reminders,
                customers,
                currency,
                businessName
        );
    }

    private String getCurrencySymbol(String currencyCode) {
        if (currencyCode == null) return "$";
        String code = currencyCode.toUpperCase().trim();
        switch (code) {
            case "QAR": return "QAR ";
            case "AED": return "AED ";
            case "SAR": return "SAR ";
            case "KWD": return "KWD ";
            case "BHD": return "BHD ";
            case "OMR": return "OMR ";
            case "EGP": return "EGP ";
            case "USD": return "$";
            case "EUR": return "€";
            case "GBP": return "£";
            case "JPY": return "¥";
            default:
                try {
                    Currency c = Currency.getInstance(code);
                    return c.getSymbol(Locale.US);
                } catch (Exception e) {
                    return code + " ";
                }
        }
    }
}
