package com.afab.reports.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class ProfitAndLossReportDTO {
    private String period;
    private Instant startDate;
    private Instant endDate;
    private String currency;
    private BigDecimal totalRevenue = BigDecimal.ZERO;
    private BigDecimal totalExpenses = BigDecimal.ZERO;
    private BigDecimal grossProfit = BigDecimal.ZERO;
    private BigDecimal netOperatingIncome = BigDecimal.ZERO;
    private double profitMarginPct = 0.0;
    private List<CategoryShareDTO> revenueBreakdown = new ArrayList<>();
    private List<CategoryShareDTO> expenseBreakdown = new ArrayList<>();

    public ProfitAndLossReportDTO() {}

    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }

    public Instant getStartDate() { return startDate; }
    public void setStartDate(Instant startDate) { this.startDate = startDate; }

    public Instant getEndDate() { return endDate; }
    public void setEndDate(Instant endDate) { this.endDate = endDate; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public BigDecimal getTotalRevenue() { return totalRevenue; }
    public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

    public BigDecimal getTotalExpenses() { return totalExpenses; }
    public void setTotalExpenses(BigDecimal totalExpenses) { this.totalExpenses = totalExpenses; }

    public BigDecimal getGrossProfit() { return grossProfit; }
    public void setGrossProfit(BigDecimal grossProfit) { this.grossProfit = grossProfit; }

    public BigDecimal getNetOperatingIncome() { return netOperatingIncome; }
    public void setNetOperatingIncome(BigDecimal netOperatingIncome) { this.netOperatingIncome = netOperatingIncome; }

    public double getProfitMarginPct() { return profitMarginPct; }
    public void setProfitMarginPct(double profitMarginPct) { this.profitMarginPct = profitMarginPct; }

    public List<CategoryShareDTO> getRevenueBreakdown() { return revenueBreakdown; }
    public void setRevenueBreakdown(List<CategoryShareDTO> revenueBreakdown) { this.revenueBreakdown = revenueBreakdown; }

    public List<CategoryShareDTO> getExpenseBreakdown() { return expenseBreakdown; }
    public void setExpenseBreakdown(List<CategoryShareDTO> expenseBreakdown) { this.expenseBreakdown = expenseBreakdown; }
}
