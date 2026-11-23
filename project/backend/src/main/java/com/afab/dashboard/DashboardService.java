package com.afab.dashboard;

import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.dashboard.dto.DashboardSummaryDTO;
import com.afab.dashboard.dto.DashboardSummaryDTO.CustomerItem;
import com.afab.dashboard.dto.DashboardSummaryDTO.ReminderItem;
import com.afab.finance.stats.FinanceStatsService;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import com.afab.invoices.repository.InvoiceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Dashboard Service — builds real financial summary data for the authenticated user.
 * Aggregates cash-basis transaction KPIs, active budgets & deterministic alerts,
 * overdue invoice reminders, and top customers by real invoice revenue.
 */
@Service
public class DashboardService {

    private final CurrentBusinessService currentBusinessService;
    private final FinanceStatsService financeStatsService;
    private final BudgetService budgetService;
    private final InvoiceRepository invoiceRepository;
    private final CustomerRepository customerRepository;

    public DashboardService(
            CurrentBusinessService currentBusinessService,
            FinanceStatsService financeStatsService,
            BudgetService budgetService,
            InvoiceRepository invoiceRepository,
            CustomerRepository customerRepository
    ) {
        this.currentBusinessService = currentBusinessService;
        this.financeStatsService = financeStatsService;
        this.budgetService = budgetService;
        this.invoiceRepository = invoiceRepository;
        this.customerRepository = customerRepository;
    }

    @Transactional(readOnly = true)
    public DashboardSummaryDTO getSummary(String userEmail) {
        return getSummary(userEmail, "month");
    }

    @Transactional(readOnly = true)
    public DashboardSummaryDTO getSummary(String userEmail, String period) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        DashboardSummaryDTO summary = financeStatsService.buildDashboardSummary(business, period);

        LocalDate today = LocalDate.now();
        BudgetSummaryDTO budgetSummary = budgetService.buildSummaryForBusiness(business, today);
        summary.setBudgets(budgetSummary);

        // Deterministic rule-based reminders (budget alerts + overdue invoices)
        List<ReminderItem> reminders = new ArrayList<>();
        if (budgetSummary != null && budgetSummary.budgets() != null) {
            for (BudgetDTO b : budgetSummary.budgets()) {
                if ("OVER_BUDGET".equals(b.alertLevel())) {
                    reminders.add(new ReminderItem(
                            "budget-over-" + b.id(),
                            "Over budget: " + b.name() + " (" + b.percentageConsumed().stripTrailingZeros().toPlainString() + "%)",
                            b.endDate() != null ? b.endDate().toString() : today.toString(),
                            "high",
                            "budget"
                    ));
                } else if ("APPROACHING".equals(b.alertLevel())) {
                    reminders.add(new ReminderItem(
                            "budget-warn-" + b.id(),
                            "Approaching budget limit: " + b.name() + " (" + b.percentageConsumed().stripTrailingZeros().toPlainString() + "%)",
                            b.endDate() != null ? b.endDate().toString() : today.toString(),
                            "medium",
                            "budget"
                    ));
                }
            }
        }

        List<Invoice> businessInvoices = invoiceRepository.findAllByBusinessIdWithCustomer(business.getId());
        Map<UUID, BigDecimal> revenueByCustomer = new HashMap<>();
        for (Invoice inv : businessInvoices) {
            if (inv.computeEffectiveStatus(today) == InvoiceStatus.OVERDUE) {
                String custName = inv.getCustomer() != null ? inv.getCustomer().getName() : "Customer";
                reminders.add(new ReminderItem(
                        "inv-overdue-" + inv.getId(),
                        "Overdue invoice " + inv.getInvoiceNumber() + " — " + custName,
                        inv.getDueDate() != null ? inv.getDueDate().toString() : today.toString(),
                        "high",
                        "invoice"
                ));
            }
            if (inv.getCustomer() != null && inv.getStatus() != InvoiceStatus.CANCELLED
                    && inv.getPaidAmount() != null && inv.getPaidAmount().compareTo(BigDecimal.ZERO) > 0) {
                revenueByCustomer.merge(inv.getCustomer().getId(), inv.getPaidAmount(), BigDecimal::add);
            }
        }
        summary.setReminders(reminders.stream().limit(8).toList());

        // Real top customers by paid invoice revenue
        List<Customer> activeCustomers = customerRepository.findAllActiveByBusinessId(business.getId());
        List<CustomerItem> topCustomers = activeCustomers.stream()
                .map(c -> new CustomerItem(
                        c.getId().toString(),
                        c.getName(),
                        revenueByCustomer.getOrDefault(c.getId(), BigDecimal.ZERO).doubleValue(),
                        extractInitials(c.getName())
                ))
                .sorted(Comparator.comparingDouble(CustomerItem::getRevenue).reversed())
                .limit(5)
                .toList();
        summary.setCustomers(topCustomers);

        return summary;
    }

    private String extractInitials(String name) {
        if (name == null || name.isBlank()) return "C";
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, Math.min(2, parts[0].length())).toUpperCase();
        }
        return ("" + parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase();
    }
}
