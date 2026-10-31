package com.afab.reports.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

public class CashFlowReportDTO {
    private String period;
    private Instant startDate;
    private Instant endDate;
    private String currency;
    private BigDecimal cashInflow = BigDecimal.ZERO;
    private BigDecimal cashOutflow = BigDecimal.ZERO;
    private BigDecimal netCashChange = BigDecimal.ZERO;
    private List<MonthlyCashFlowDTO> monthlyTrend = new ArrayList<>();

    public CashFlowReportDTO() {}

    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }

    public Instant getStartDate() { return startDate; }
    public void setStartDate(Instant startDate) { this.startDate = startDate; }

    public Instant getEndDate() { return endDate; }
    public void setEndDate(Instant endDate) { this.endDate = endDate; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public BigDecimal getCashInflow() { return cashInflow; }
    public void setCashInflow(BigDecimal cashInflow) { this.cashInflow = cashInflow; }

    public BigDecimal getCashOutflow() { return cashOutflow; }
    public void setCashOutflow(BigDecimal cashOutflow) { this.cashOutflow = cashOutflow; }

    public BigDecimal getNetCashChange() { return netCashChange; }
    public void setNetCashChange(BigDecimal netCashChange) { this.netCashChange = netCashChange; }

    public List<MonthlyCashFlowDTO> getMonthlyTrend() { return monthlyTrend; }
    public void setMonthlyTrend(List<MonthlyCashFlowDTO> monthlyTrend) { this.monthlyTrend = monthlyTrend; }
}
