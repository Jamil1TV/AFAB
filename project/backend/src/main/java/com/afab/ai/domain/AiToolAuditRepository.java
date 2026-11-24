package com.afab.ai.domain;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AiToolAuditRepository extends JpaRepository<AiToolAudit, UUID> {
}
