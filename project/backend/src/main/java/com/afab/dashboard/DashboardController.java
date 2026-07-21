package com.afab.dashboard;

import com.afab.dashboard.dto.DashboardSummaryDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/dashboard")
public class DashboardController {

    @GetMapping("/summary")
    public ResponseEntity<DashboardSummaryDTO> getDashboardSummary() {
        DashboardSummaryDTO summary = new DashboardSummaryDTO();

        // 1. KPI Data
        Map<String, DashboardSummaryDTO.KpiMetric> kpiData = new HashMap<>();
        kpiData.put("revenue", new DashboardSummaryDTO.KpiMetric("$24,850.00", "+12.5%", true));
        kpiData.put("expenses", new DashboardSummaryDTO.KpiMetric("$9,420.00", "-8.4%", false));
        kpiData.put("profit", new DashboardSummaryDTO.KpiMetric("$15,430.00", "+33.4%", true));
        kpiData.put("cashFlow", new DashboardSummaryDTO.KpiMetric("$8,750.00", "+16.7%", true));
        summary.setKpiData(kpiData);

        // 2. Revenue Data
        summary.setRevenueData(Arrays.asList(
                new DashboardSummaryDTO.RevenueData("Mon", 4000, 2400),
                new DashboardSummaryDTO.RevenueData("Tue", 3000, 1398),
                new DashboardSummaryDTO.RevenueData("Wed", 2000, 9800),
                new DashboardSummaryDTO.RevenueData("Thu", 2780, 3908),
                new DashboardSummaryDTO.RevenueData("Fri", 1890, 4800),
                new DashboardSummaryDTO.RevenueData("Sat", 2390, 3800),
                new DashboardSummaryDTO.RevenueData("Sun", 3490, 4300)
        ));

        // 3. Transactions
        summary.setTransactions(Arrays.asList(
                new DashboardSummaryDTO.Transaction(1, "Stripe Payment", "May 18, 2024 - 10:40 AM", "+$1,250.00", "Completed", true, "S", "bg-[#635BFF]"),
                new DashboardSummaryDTO.Transaction(2, "AWS Cloud", "May 17, 2024 - 09:15 AM", "-$340.00", "Pending", false, "A", "bg-[#FF9900]"),
                new DashboardSummaryDTO.Transaction(3, "Upwork Escrow", "May 16, 2024 - 04:30 PM", "-$850.00", "Completed", false, "U", "bg-[#14A800]"),
                new DashboardSummaryDTO.Transaction(4, "Shopify Payout", "May 15, 2024 - 11:20 AM", "+$3,420.00", "Completed", true, "S", "bg-[#95BF47]"),
                new DashboardSummaryDTO.Transaction(5, "Google Workspace", "May 14, 2024 - 08:00 AM", "-$45.00", "Completed", false, "G", "bg-[#4285F4]")
        ));

        // 4. Expense Categories
        summary.setExpenseCategories(Arrays.asList(
                new DashboardSummaryDTO.ExpenseCategory("Marketing", 4200, "#8b5cf6"),
                new DashboardSummaryDTO.ExpenseCategory("Subscriptions", 2200, "#06b6d4"),
                new DashboardSummaryDTO.ExpenseCategory("Operations", 1800, "#22c55e"),
                new DashboardSummaryDTO.ExpenseCategory("Other", 1220, "#9ca3af")
        ));

        // 5. Reminders
        summary.setReminders(Arrays.asList(
                new DashboardSummaryDTO.Reminder(1, "Review Q3 Tax Documents", "Tomorrow, 10:00 AM", "Tax"),
                new DashboardSummaryDTO.Reminder(2, "Client Meeting - Vercel", "Wed, 2:30 PM", "Meeting"),
                new DashboardSummaryDTO.Reminder(3, "Renew AWS Subscription", "Fri, 12:00 PM", "Subscription")
        ));

        // 6. Customers
        summary.setCustomers(Arrays.asList(
                new DashboardSummaryDTO.Customer(1, "Acme Corp", "$12,450", "https://i.pravatar.cc/150?u=a042581f4e29026024d"),
                new DashboardSummaryDTO.Customer(2, "Globex Inc", "$8,320", "https://i.pravatar.cc/150?u=a042581f4e29026704d"),
                new DashboardSummaryDTO.Customer(3, "Soylent Corp", "$5,100", "https://i.pravatar.cc/150?u=a04258114e29026702d")
        ));

        return ResponseEntity.ok(summary);
    }
}
