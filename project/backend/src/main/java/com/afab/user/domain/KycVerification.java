package com.afab.user.domain;

import com.afab.common.entity.BaseEntity;
import com.afab.user.User;
import jakarta.persistence.*;
import java.util.UUID;

import java.time.Instant;

/**
 * KYC Verification tracking for the business owner.
 */
@Entity
@Table(name = "kyc_verifications")
public class KycVerification extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "document_type", nullable = false, length = 50)
    private String documentType;

    @Column(name = "document_front_url", nullable = false, length = 512)
    private String documentFrontUrl;

    @Column(name = "document_back_url", length = 512)
    private String documentBackUrl;

    @Column(name = "selfie_url", length = 512)
    private String selfieUrl;

    @Column(name = "document_number")
    private String documentNumber;

    @Column(nullable = false, length = 50)
    private String status = "PENDING";

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    private String rejectionReason;

    @Column(name = "verified_at")
    private Instant verifiedAt;

    // ── Constructors ────────────────────────────

    public KycVerification() {}

    // ── Getters & Setters ───────────────────────

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }

    public String getDocumentFrontUrl() { return documentFrontUrl; }
    public void setDocumentFrontUrl(String documentFrontUrl) { this.documentFrontUrl = documentFrontUrl; }

    public String getDocumentBackUrl() { return documentBackUrl; }
    public void setDocumentBackUrl(String documentBackUrl) { this.documentBackUrl = documentBackUrl; }

    public String getSelfieUrl() { return selfieUrl; }
    public void setSelfieUrl(String selfieUrl) { this.selfieUrl = selfieUrl; }

    public String getDocumentNumber() { return documentNumber; }
    public void setDocumentNumber(String documentNumber) { this.documentNumber = documentNumber; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }

    public Instant getVerifiedAt() { return verifiedAt; }
    public void setVerifiedAt(Instant verifiedAt) { this.verifiedAt = verifiedAt; }
}
