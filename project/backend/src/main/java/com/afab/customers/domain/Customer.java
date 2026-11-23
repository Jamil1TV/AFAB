package com.afab.customers.domain;

import com.afab.business.Business;
import com.afab.common.entity.BaseEntity;
import jakarta.persistence.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "customers")
public class Customer extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @Column(name = "customer_code", nullable = false, length = 40)
    private String customerCode;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(name = "company_name", length = 255)
    private String companyName;

    @Column(columnDefinition = "citext")
    private String email;

    @Column(length = 50)
    private String phone;

    @Column(name = "customer_group", nullable = false, length = 50)
    private String customerGroup = "Standard";

    @Column(nullable = false, length = 30)
    private String status = "Active";

    @Column(columnDefinition = "TEXT")
    private String address;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @Column(name = "archived_at")
    private Instant archivedAt;

    public Customer() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public String getCustomerCode() { return customerCode; }
    public void setCustomerCode(String customerCode) { this.customerCode = customerCode; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getCustomerGroup() { return customerGroup; }
    public void setCustomerGroup(String customerGroup) { this.customerGroup = customerGroup; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Instant getArchivedAt() { return archivedAt; }
    public void setArchivedAt(Instant archivedAt) { this.archivedAt = archivedAt; }
}
