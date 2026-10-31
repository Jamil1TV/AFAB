package com.afab.reports.dto;

import java.math.BigDecimal;

public class ComparisonReportDTO {
    private String currency;

    private String primaryPeriodLabel;
    private BigDecimal primaryRevenue = BigDecimal.ZERO;
    private BigDecimal primaryExpenses = BigDecimal.ZERO;
    private BigDecimal primaryNetIncome = BigDecimal.ZERO;

    private String comparisonPeriodLabel;
    private BigDecimal comparisonRevenue = BigDecimal.ZERO;
    private BigDecimal comparisonExpenses = BigDecimal.ZERO;
    private BigDecimal comparisonNetIncome = BigDecimal.ZERO;

    private BigDecimal revenueDifference = BigDecimal.ZERO;
    private double revenueDifferencePct = 0.0;

    private BigDecimal expensesDifference = BigDecimal.ZERO;
    private double expensesDifferencePct = 0.0;

    private BigDecimal netIncomeDifference = BigDecimal.ZERO;
    private double netIncomeDifferencePct = 0.0;

    public ComparisonReportDTO() {}

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getPrimaryPeriodLabel() { return primaryPeriodLabel; }
    public void setPrimaryPeriodLabel(String primaryPeriodLabel) { this.primaryPeriodLabel = primaryPeriodLabel; }

    public BigDecimal getPrimaryRevenue() { return primaryRevenue; }
    public void setPrimaryRevenue(BigDecimal primaryRevenue) { this.primaryRevenue = primaryRevenue; }

    public BigDecimal getPrimaryExpenses() { return primaryExpenses; }
    public void setPrimaryExpenses(BigDecimal primaryExpenses) { this.primaryExpenses = primaryExpenses; }

    public BigDecimal getPrimaryNetIncome() { return primaryNetIncome; }
    public void setPrimaryNetIncome(BigDecimal primaryNetIncome) { this.primaryNetIncome = primaryNetIncome; }

    public String getComparisonPeriodLabel() { return comparisonPeriodLabel; }
    public void setComparisonPeriodLabel(String comparisonPeriodLabel) { this.comparisonPeriodLabel = comparisonPeriodLabel; }

    public BigDecimal getComparisonRevenue() { return comparisonRevenue; }
    public void setComparisonRevenue(BigDecimal comparisonRevenue) { this.comparisonRevenue = comparisonRevenue; }

    public BigDecimal getComparisonExpenses() { return comparisonExpenses; }
    public void setComparisonExpenses(BigDecimal comparisonExpenses) { this.comparisonExpenses = comparisonExpenses; }

    public BigDecimal getComparisonNetIncome() { return comparisonNetIncome; }
    public void setComparisonNetIncome(BigDecimal comparisonNetIncome) { this.comparisonNetIncome = comparisonNetIncome; }

    public BigDecimal getRevenueDifference() { return revenueDifference; }
    public void setRevenueDifference(BigDecimal revenueDifference) { this.revenueDifference = revenueDifference; }

    public double getRevenueDifferencePct() { return revenueDifferencePct; }
    public void setRevenueDifferencePct(double revenueDifferencePct) { this.revenueDifferencePct = revenueDifferencePct; }

    public BigDecimal getExpensesDifference() { return expensesDifference; }
    public void setExpensesDifference(BigDecimal expensesDifference) { this.expensesDifference = expensesDifference; }

    public double getExpensesDifferencePct() { return expensesDifferencePct; }
    public void setExpensesDifferencePct(double expensesDifferencePct) { this.expensesDifferencePct = expensesDifferencePct; }

    public BigDecimal getNetIncomeDifference() { return netIncomeDifference; }
    public void setNetIncomeDifference(BigDecimal netIncomeDifference) { this.netIncomeDifference = netIncomeDifference; }

    public double getNetIncomeDifferencePct() { return netIncomeDifferencePct; }
    public void setNetIncomeDifferencePct(double netIncomeDifferencePct) { this.netIncomeDifferencePct = netIncomeDifferencePct; }
}
