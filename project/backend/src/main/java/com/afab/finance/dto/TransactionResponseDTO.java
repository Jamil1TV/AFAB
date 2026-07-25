package com.afab.finance.dto;

import java.math.BigDecimal;
import java.util.List;

public class TransactionResponseDTO {
    private List<TransactionDTO> content;
    private int pageNumber;
    private int pageSize;
    private long totalElements;
    private int totalPages;
    private BigDecimal totalInflow;
    private BigDecimal totalOutflow;
    private BigDecimal netBalance;
    private String currency;

    public TransactionResponseDTO() {}

    public TransactionResponseDTO(List<TransactionDTO> content, int pageNumber, int pageSize,
                                  long totalElements, int totalPages, BigDecimal totalInflow,
                                  BigDecimal totalOutflow, BigDecimal netBalance, String currency) {
        this.content = content;
        this.pageNumber = pageNumber;
        this.pageSize = pageSize;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
        this.totalInflow = totalInflow;
        this.totalOutflow = totalOutflow;
        this.netBalance = netBalance;
        this.currency = currency;
    }

    public List<TransactionDTO> getContent() { return content; }
    public void setContent(List<TransactionDTO> content) { this.content = content; }

    public int getPageNumber() { return pageNumber; }
    public void setPageNumber(int pageNumber) { this.pageNumber = pageNumber; }

    public int getPageSize() { return pageSize; }
    public void setPageSize(int pageSize) { this.pageSize = pageSize; }

    public long getTotalElements() { return totalElements; }
    public void setTotalElements(long totalElements) { this.totalElements = totalElements; }

    public int getTotalPages() { return totalPages; }
    public void setTotalPages(int totalPages) { this.totalPages = totalPages; }

    public BigDecimal getTotalInflow() { return totalInflow; }
    public void setTotalInflow(BigDecimal totalInflow) { this.totalInflow = totalInflow; }

    public BigDecimal getTotalOutflow() { return totalOutflow; }
    public void setTotalOutflow(BigDecimal totalOutflow) { this.totalOutflow = totalOutflow; }

    public BigDecimal getNetBalance() { return netBalance; }
    public void setNetBalance(BigDecimal netBalance) { this.netBalance = netBalance; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }
}
