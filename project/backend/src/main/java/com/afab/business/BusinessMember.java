package com.afab.business;

import com.afab.common.entity.BaseEntity;
import com.afab.user.User;
import jakarta.persistence.*;
import java.util.UUID;

/**
 * BusinessMember entity — represents a user's membership and role in a business.
 * Powers multi-tenancy, workspace switching, and team access.
 */
@Entity
@Table(
    name = "business_members",
    uniqueConstraints = {
        @UniqueConstraint(name = "uq_business_member", columnNames = {"business_id", "user_id"})
    }
)
public class BusinessMember extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "business_id", nullable = false)
    private Business business;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 50)
    private String role = "MEMBER";

    @Column(nullable = false, length = 50)
    private String status = "ACTIVE";

    // ── Constructors ────────────────────────────

    public BusinessMember() {}

    public BusinessMember(Business business, User user, String role) {
        this.business = business;
        this.user = user;
        this.role = role != null ? role.toUpperCase() : "MEMBER";
        this.status = "ACTIVE";
    }

    public BusinessMember(Business business, User user, String role, String status) {
        this.business = business;
        this.user = user;
        this.role = role != null ? role.toUpperCase() : "MEMBER";
        this.status = status != null ? status.toUpperCase() : "ACTIVE";
    }

    // ── Getters & Setters ───────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Business getBusiness() { return business; }
    public void setBusiness(Business business) { this.business = business; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role != null ? role.toUpperCase() : "MEMBER"; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status != null ? status.toUpperCase() : "ACTIVE"; }

    public boolean isOwner() {
        return "OWNER".equalsIgnoreCase(this.role);
    }

    public boolean isAdminOrOwner() {
        return "OWNER".equalsIgnoreCase(this.role) || "ADMIN".equalsIgnoreCase(this.role);
    }
}
