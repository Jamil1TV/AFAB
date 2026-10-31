package com.afab.reports.dto;

import java.math.BigDecimal;

public class MonthlyCashFlowDTO {
    private String month; // YYYY-MM
    private BigDecimal inflow;
    private BigDecimal outflow;
    private BigDecimal net;

    public MonthlyCashFlowDTO() {}

    public MonthlyCashFlowDTO(String month, BigDecimal inflow, BigDecimal outflow, BigDecimal net) {
        this.month = month;
        this.inflow = inflow;
        this.outflow = outflow;
        this.net = net;
    }

    public String getMonth() { return month; }
    public void setMonth(String month) { this.month = month; }

    public BigDecimal getInflow() { return inflow; }
    public void setInflow(BigDecimal inflow) { this.inflow = inflow; }

    public BigDecimal getOutflow() { return outflow; }
    public void setOutflow(BigDecimal outflow) { this.outflow = outflow; }

    public BigDecimal getNet() { return net; }
    public void setNet(BigDecimal net) { this.net = net; }
}
