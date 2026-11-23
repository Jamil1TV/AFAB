package com.afab.customers.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

public class UpdateCustomerRequest {

    @Size(min = 1, max = 255, message = "Customer name must be between 1 and 255 characters")
    private String name;

    @Size(max = 255, message = "Company name cannot exceed 255 characters")
    private String companyName;

    @Email(message = "Invalid email format")
    @Size(max = 255, message = "Email cannot exceed 255 characters")
    private String email;

    @Size(max = 40, message = "Customer code cannot exceed 40 characters")
    private String customerCode;

    @Size(max = 50, message = "Phone cannot exceed 50 characters")
    private String phone;

    @Size(max = 50, message = "Group cannot exceed 50 characters")
    private String group;

    @Size(max = 30, message = "Status cannot exceed 30 characters")
    private String status;

    @Size(max = 1000, message = "Address cannot exceed 1000 characters")
    private String address;

    @Size(max = 2000, message = "Notes cannot exceed 2000 characters")
    private String notes;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getCustomerCode() { return customerCode; }
    public void setCustomerCode(String customerCode) { this.customerCode = customerCode; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getGroup() { return group; }
    public void setGroup(String group) { this.group = group; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
