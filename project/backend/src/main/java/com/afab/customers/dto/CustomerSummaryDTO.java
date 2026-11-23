package com.afab.customers.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CustomerSummaryDTO(
        long totalCustomers,
        double totalCustomersChangePct,
        long newCustomers,
        double newCustomersChangePct,
        BigDecimal totalRevenue,
        double totalRevenueChangePct,
        BigDecimal avgRevenuePerCustomer,
        double avgRevenueChangePct,
        double repeatCustomersPct,
        double repeatCustomersChangePct,
        String currency,
        OverviewDonut overviewDonut,
        List<TopCustomerItem> topCustomers,
        List<CustomerActivityItem> recentActivity
) {
    public record OverviewDonut(
            long activeCount,
            double activePct,
            long inactiveCount,
            double inactivePct,
            long newCount,
            double newPct
    ) {}

    public record TopCustomerItem(
            UUID id,
            String customerCode,
            String name,
            String email,
            BigDecimal revenue,
            long ordersCount,
            String avatarColor
    ) {}

    public record CustomerActivityItem(
            String id,
            UUID customerId,
            String customerName,
            String type,
            String description,
            BigDecimal amount,
            String timestamp
    ) {}
}
