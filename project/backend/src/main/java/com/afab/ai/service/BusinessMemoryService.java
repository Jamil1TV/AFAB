package com.afab.ai.service;

import com.afab.ai.domain.BusinessMemory;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.dto.BusinessMemoryDTO;
import com.afab.ai.dto.BusinessMemoryRequest;
import com.afab.ai.dto.BusinessMemoryUpdateRequest;
import com.afab.ai.rag.AiRagIndexService;
import com.afab.ai.rag.AiVectorRepository;
import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class BusinessMemoryService {

    public static final Set<String> ALLOWED_MEMORY_TYPES = Set.of(
            "BUSINESS_PROFILE",
            "TRANSACTION_CONTEXT",
            "SUPPLIER_PATTERN",
            "CATEGORIZATION_PREFERENCE",
            "DECISION_HISTORY",
            "OPERATIONAL_CONSTRAINT"
    );

    public static final Set<String> ALLOWED_STATUSES = Set.of("PROPOSED", "APPROVED", "EXPIRED");

    private final BusinessMemoryRepository memoryRepository;
    private final AiVectorRepository vectorRepository;
    private final AiRagIndexService ragIndexService;
    private final CurrentBusinessService currentBusinessService;
    private final AuditService auditService;

    public BusinessMemoryService(
            BusinessMemoryRepository memoryRepository,
            AiVectorRepository vectorRepository,
            AiRagIndexService ragIndexService,
            CurrentBusinessService currentBusinessService,
            AuditService auditService
    ) {
        this.memoryRepository = memoryRepository;
        this.vectorRepository = vectorRepository;
        this.ragIndexService = ragIndexService;
        this.currentBusinessService = currentBusinessService;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<BusinessMemoryDTO> list(String userEmail, String statusFilter) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        List<BusinessMemory> list = (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter))
                ? memoryRepository.findByBusinessIdAndStatus(business.getId(), normalizeStatus(statusFilter))
                : memoryRepository.findAllVisibleByBusinessId(business.getId());

        Set<UUID> vectorIds = vectorRepository.findMemoryIdsWithVectors(business.getId());
        return list.stream().map(m -> toDTO(m, vectorIds.contains(m.getId()))).toList();
    }

    public BusinessMemoryDTO create(String userEmail, BusinessMemoryRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        String memoryType = normalizeMemoryType(request.getMemoryType());
        String status = request.getStatus() != null && !request.getStatus().isBlank()
                ? normalizeStatus(request.getStatus())
                : "APPROVED";

        BusinessMemory memory = new BusinessMemory();
        memory.setBusiness(business);
        memory.setMemoryType(memoryType);
        memory.setTitle(request.getTitle().trim());
        memory.setContent(request.getContent().trim());
        memory.setContentHash(AiVectorRepository.sha256Hex(memory.getTitle() + "\n" + memory.getContent()));
        memory.setSourceType("USER_NOTE");
        memory.setStatus(status);
        memory.setVisibility("BUSINESS");
        memory.setCreatedBy(user.getId());
        if ("APPROVED".equals(status)) {
            memory.setApprovedBy(user.getId());
        }
        memory.setExpiresAt(request.getExpiresAt());

        memory = memoryRepository.save(memory);
        if ("APPROVED".equals(status)) {
            ragIndexService.embedMemoryIfPossible(memory);
        }

        auditService.log(user, "CREATE", "BusinessMemory", memory.getId(), "{\"type\":\"" + memoryType + "\"}");
        boolean hasVec = vectorRepository.memoryHasVector(memory.getId(), business.getId());
        return toDTO(memory, hasVec);
    }

    public BusinessMemoryDTO update(String userEmail, UUID id, BusinessMemoryUpdateRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        BusinessMemory memory = memoryRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Business memory not found with ID: " + id));
        if (!memory.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this memory record.");
        }

        boolean contentChanged = false;
        if (request.getMemoryType() != null && !request.getMemoryType().isBlank()) {
            memory.setMemoryType(normalizeMemoryType(request.getMemoryType()));
        }
        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            memory.setTitle(request.getTitle().trim());
            contentChanged = true;
        }
        if (request.getContent() != null && !request.getContent().isBlank()) {
            memory.setContent(request.getContent().trim());
            contentChanged = true;
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            String nextStatus = normalizeStatus(request.getStatus());
            memory.setStatus(nextStatus);
            if ("APPROVED".equals(nextStatus)) {
                memory.setApprovedBy(user.getId());
            }
        }
        if (request.getExpiresAt() != null) {
            memory.setExpiresAt(request.getExpiresAt());
        }

        if (contentChanged) {
            memory.setContentHash(AiVectorRepository.sha256Hex(memory.getTitle() + "\n" + memory.getContent()));
        }

        memory = memoryRepository.save(memory);
        if ("APPROVED".equals(memory.getStatus()) && (contentChanged || !vectorRepository.memoryHasVector(memory.getId(), business.getId()))) {
            ragIndexService.embedMemoryIfPossible(memory);
        }

        auditService.log(user, "UPDATE", "BusinessMemory", memory.getId(), "{\"status\":\"" + memory.getStatus() + "\"}");
        boolean hasVec = vectorRepository.memoryHasVector(memory.getId(), business.getId());
        return toDTO(memory, hasVec);
    }

    @Transactional
    public void delete(String userEmail, UUID id) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        BusinessMemory memory = memoryRepository.findActiveById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Business memory not found with ID: " + id));
        if (!memory.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this memory record.");
        }

        memory.setStatus("DELETED");
        memoryRepository.save(memory);
        auditService.log(user, "DELETE", "BusinessMemory", memory.getId(), null);
    }

    private String normalizeMemoryType(String raw) {
        String upper = raw.trim().toUpperCase(Locale.ROOT);
        if (!ALLOWED_MEMORY_TYPES.contains(upper)) {
            throw new IllegalArgumentException("Unsupported memoryType: " + raw);
        }
        return upper;
    }

    private String normalizeStatus(String raw) {
        String upper = raw.trim().toUpperCase(Locale.ROOT);
        if (!ALLOWED_STATUSES.contains(upper)) {
            throw new IllegalArgumentException("Unsupported memory status: " + raw);
        }
        return upper;
    }

    private BusinessMemoryDTO toDTO(BusinessMemory m, boolean hasVector) {
        return new BusinessMemoryDTO(
                m.getId(),
                m.getMemoryType(),
                m.getTitle(),
                m.getContent(),
                m.getSourceType(),
                m.getSourceId(),
                m.getStatus(),
                m.getVisibility(),
                m.getModelId(),
                hasVector,
                m.getExpiresAt(),
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
