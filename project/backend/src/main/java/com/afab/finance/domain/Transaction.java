package com.afab.finance.domain;

import com.afab.business.Business;
import com.afab.common.entity.BaseEntity;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "transactions")
public class Transaction extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @Column(nullable = false, length = 20)
    private String type; // 'INCOME', 'EXPENSE'

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(nullable = false, length = 3)
    private String currency = "USD";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @Column(nullable = false, length = 255)
    private String description;

    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    @Column(name = "payment_method", length = 50)
    private String paymentMethod;

    @Column(nullable = false, length = 30)
    private String status = "COMPLETED";

    @Column(name = "receipt_url", length = 512)
    private String receiptUrl;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Column(name = "tax_deductible", nullable = false)
    private Boolean taxDeductible = false;

    @Column(name = "tax_rate", precision = 5, scale = 2)
    private BigDecimal taxRate;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_transaction_id")
    private Transaction parentTransaction;

    @Column(name = "is_split", nullable = false)
    private Boolean isSplit = false;

    @OneToMany(mappedBy = "parentTransaction", cascade = CascadeType.ALL, orphanRemoval = true)
    private java.util.List<Transaction> splitItems = new java.util.ArrayList<>();

    public Transaction() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Category getCategory() { return category; }
    public void setCategory(Category category) { this.category = category; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public LocalDate getTransactionDate() { return transactionDate; }
    public void setTransactionDate(LocalDate transactionDate) { this.transactionDate = transactionDate; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReceiptUrl() { return receiptUrl; }
    public void setReceiptUrl(String receiptUrl) { this.receiptUrl = receiptUrl; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Instant getDeletedAt() { return deletedAt; }
    public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }

    public Boolean getTaxDeductible() { return taxDeductible != null && taxDeductible; }
    public void setTaxDeductible(Boolean taxDeductible) { this.taxDeductible = taxDeductible; }

    public BigDecimal getTaxRate() { return taxRate; }
    public void setTaxRate(BigDecimal taxRate) { this.taxRate = taxRate; }

    public Transaction getParentTransaction() { return parentTransaction; }
    public void setParentTransaction(Transaction parentTransaction) { this.parentTransaction = parentTransaction; }

    public Boolean getIsSplit() { return isSplit != null && isSplit; }
    public void setIsSplit(Boolean isSplit) { this.isSplit = isSplit; }

    public java.util.List<Transaction> getSplitItems() { return splitItems; }
    public void setSplitItems(java.util.List<Transaction> splitItems) { this.splitItems = splitItems; }
}
