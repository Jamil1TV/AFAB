package com.afab.ai.service;

import com.afab.ai.domain.*;
import com.afab.ai.dto.*;
import com.afab.ai.rag.AiVectorRepository;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetRequest;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.CreateTransactionRequest;
import com.afab.finance.dto.TransactionDTO;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.TransactionService;
import com.afab.invoices.dto.CreateInvoiceRequest;
import com.afab.invoices.dto.InvoiceDTO;
import com.afab.invoices.service.InvoiceService;
import com.afab.user.User;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * Atomic Human-in-the-Loop Action Executor.
 * Mutations ONLY occur when an authenticated user explicitly approves a draft card.
 */
@Service
public class AiActionExecutionService {

    private final AiMessageRepository messageRepository;
    private final AiToolAuditRepository toolAuditRepository;
    private final CurrentBusinessService currentBusinessService;
    private final TransactionService transactionService;
    private final TransactionRepository transactionRepository;
    private final InvoiceService invoiceService;
    private final BudgetService budgetService;
    private final BusinessMemoryService businessMemoryService;
    private final AiAttachmentService attachmentService;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    public AiActionExecutionService(
            AiMessageRepository messageRepository,
            AiToolAuditRepository toolAuditRepository,
            CurrentBusinessService currentBusinessService,
            TransactionService transactionService,
            TransactionRepository transactionRepository,
            InvoiceService invoiceService,
            BudgetService budgetService,
            BusinessMemoryService businessMemoryService,
            AiAttachmentService attachmentService
    ) {
        this.messageRepository = messageRepository;
        this.toolAuditRepository = toolAuditRepository;
        this.currentBusinessService = currentBusinessService;
        this.transactionService = transactionService;
        this.transactionRepository = transactionRepository;
        this.invoiceService = invoiceService;
        this.budgetService = budgetService;
        this.businessMemoryService = businessMemoryService;
        this.attachmentService = attachmentService;
    }

    @Transactional
    public AiActionDraftDTO approveTransaction(String userEmail, ApproveTransactionDraftRequest req) {
        long startNs = System.nanoTime();
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        AiMessage message = loadOwnedAssistantMessage(req.getMessageId(), business.getId());

        CreateTransactionRequest txReq = new CreateTransactionRequest();
        txReq.setType(req.getType() != null ? req.getType().trim().toUpperCase(Locale.ROOT) : "EXPENSE");
        txReq.setAmount(req.getAmount());
        txReq.setOriginalCurrency(req.getOriginalCurrency());
        txReq.setDescription(req.getDescription().trim());
        txReq.setTransactionDate(req.getTransactionDate());
        txReq.setCategoryId(req.getCategoryId());
        txReq.setPaymentMethod(req.getPaymentMethod() != null && !req.getPaymentMethod().isBlank()
                ? req.getPaymentMethod().trim().toUpperCase(Locale.ROOT) : "BANK_TRANSFER");
        txReq.setStatus(req.getStatus() != null && !req.getStatus().isBlank()
                ? req.getStatus().trim().toUpperCase(Locale.ROOT) : "COMPLETED");
        txReq.setNotes(req.getNotes());

        TransactionDTO created = transactionService.createTransaction(userEmail, txReq);

        if (req.getStagedAttachmentId() != null) {
            Transaction txEntity = transactionRepository.findActiveById(created.getId()).orElse(null);
            if (txEntity != null) {
                attachmentService.promoteToTransactionReceipt(
                        user, business, txEntity, req.getStagedAttachmentId(), req.getExtractedOcrText()
                );
            }
        }

        AiActionDraftDTO updated = markDraftApproved(
                message, req.getDraftId(), "CREATE_TRANSACTION",
                created.getId(), "/dashboard/transactions"
        );
        auditDecision(user, business, message.getConversation().getId(), "approve_transaction", req.getDraftId(), "USER_APPROVED", startNs);
        return updated;
    }

    @Transactional
    public AiActionDraftDTO approveInvoice(String userEmail, ApproveInvoiceDraftRequest req) {
        long startNs = System.nanoTime();
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        AiMessage message = loadOwnedAssistantMessage(req.getMessageId(), business.getId());

        CreateInvoiceRequest invReq = new CreateInvoiceRequest();
        invReq.setCustomerId(req.getCustomerId());
        invReq.setIssueDate(req.getIssueDate());
        invReq.setDueDate(req.getDueDate());
        invReq.setCurrency(req.getCurrency());
        invReq.setDiscountAmount(req.getDiscountAmount());
        invReq.setNotes(req.getNotes());
        invReq.setItems(req.getItems());

        InvoiceDTO created = invoiceService.createInvoice(userEmail, invReq);
        if (req.isIssueImmediately()) {
            created = invoiceService.issueInvoice(userEmail, created.id(), false);
        }

        AiActionDraftDTO updated = markDraftApproved(
                message, req.getDraftId(), "CREATE_INVOICE",
                created.id(), "/dashboard/invoices"
        );
        auditDecision(user, business, message.getConversation().getId(), "approve_invoice", req.getDraftId(), "USER_APPROVED", startNs);
        return updated;
    }

    @Transactional
    public AiActionDraftDTO approveBudget(String userEmail, ApproveBudgetDraftRequest req) {
        long startNs = System.nanoTime();
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        AiMessage message = loadOwnedAssistantMessage(req.getMessageId(), business.getId());

        BudgetRequest bReq = new BudgetRequest();
        bReq.setName(req.getName().trim());
        bReq.setAmount(req.getAmount());
        bReq.setCategoryId(req.getCategoryId());
        bReq.setPeriodType(req.getPeriodType() != null && !req.getPeriodType().isBlank()
                ? req.getPeriodType().trim().toUpperCase(Locale.ROOT) : "MONTHLY");
        bReq.setStartDate(req.getStartDate());
        bReq.setEndDate(req.getEndDate());
        bReq.setAlertThresholdPercent(req.getAlertThresholdPercent() != null ? req.getAlertThresholdPercent() : 80);
        bReq.setDescription(req.getDescription());

        BudgetDTO created = budgetService.create(userEmail, bReq);

        AiActionDraftDTO updated = markDraftApproved(
                message, req.getDraftId(), "CREATE_BUDGET",
                created.id(), "/dashboard/budgets"
        );
        auditDecision(user, business, message.getConversation().getId(), "approve_budget", req.getDraftId(), "USER_APPROVED", startNs);
        return updated;
    }

    @Transactional
    public AiActionDraftDTO approveMemory(String userEmail, ApproveMemoryDraftRequest req) {
        long startNs = System.nanoTime();
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        AiMessage message = loadOwnedAssistantMessage(req.getMessageId(), business.getId());

        BusinessMemoryRequest memReq = new BusinessMemoryRequest();
        memReq.setMemoryType(req.getMemoryType());
        memReq.setTitle(req.getTitle().trim());
        memReq.setContent(req.getContent().trim());
        memReq.setStatus("APPROVED");

        BusinessMemoryDTO created = businessMemoryService.create(userEmail, memReq);

        AiActionDraftDTO updated = markDraftApproved(
                message, req.getDraftId(), "SAVE_MEMORY",
                created.id(), "/dashboard/ai"
        );
        auditDecision(user, business, message.getConversation().getId(), "approve_memory", req.getDraftId(), "USER_APPROVED", startNs);
        return updated;
    }

    @Transactional
    public AiActionDraftDTO dismissDraft(String userEmail, UUID messageId, String draftId) {
        long startNs = System.nanoTime();
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        AiMessage message = loadOwnedAssistantMessage(messageId, business.getId());
        List<AiActionDraftDTO> drafts = parseDrafts(message.getActionDraftsJson());
        AiActionDraftDTO updatedTarget = null;
        List<AiActionDraftDTO> next = new ArrayList<>();

        for (AiActionDraftDTO d : drafts) {
            if (d.draftId() != null && d.draftId().equals(draftId)) {
                updatedTarget = d.withDismissed();
                next.add(updatedTarget);
            } else {
                next.add(d);
            }
        }
        if (updatedTarget == null) {
            updatedTarget = new AiActionDraftDTO(draftId, "UNKNOWN", "DISMISSED", "Dismissed", "", Map.of(), null, null, null);
        }

        message.setActionDraftsJson(writeDrafts(next));
        messageRepository.save(message);
        auditDecision(user, business, message.getConversation().getId(), "dismiss_draft", draftId, "USER_DISMISSED", startNs);
        return updatedTarget;
    }

    private AiMessage loadOwnedAssistantMessage(UUID messageId, UUID businessId) {
        AiMessage message = messageRepository.findById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found: " + messageId));
        if (message.getBusiness() == null || !message.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Message belongs to another business.");
        }
        return message;
    }

    private AiActionDraftDTO markDraftApproved(
            AiMessage message,
            String draftId,
            String fallbackType,
            UUID entityId,
            String href
    ) {
        List<AiActionDraftDTO> drafts = parseDrafts(message.getActionDraftsJson());
        AiActionDraftDTO updatedTarget = null;
        List<AiActionDraftDTO> next = new ArrayList<>();

        for (AiActionDraftDTO d : drafts) {
            if (d.draftId() != null && d.draftId().equals(draftId)) {
                updatedTarget = d.withApproved(entityId, href);
                next.add(updatedTarget);
            } else {
                next.add(d);
            }
        }
        if (updatedTarget == null) {
            updatedTarget = new AiActionDraftDTO(draftId, fallbackType, "APPROVED", "Saved", "", Map.of(), null, entityId, href);
            next.add(updatedTarget);
        }

        message.setActionDraftsJson(writeDrafts(next));
        messageRepository.save(message);
        return updatedTarget;
    }

    private List<AiActionDraftDTO> parseDrafts(String json) {
        if (json == null || json.isBlank()) return new ArrayList<>();
        try {
            return new ArrayList<>(objectMapper.readValue(json, new TypeReference<List<AiActionDraftDTO>>() {}));
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private String writeDrafts(List<AiActionDraftDTO> drafts) {
        try {
            return objectMapper.writeValueAsString(drafts);
        } catch (Exception e) {
            return "[]";
        }
    }

    private void auditDecision(
            User user,
            Business business,
            UUID conversationId,
            String toolName,
            String draftId,
            String approvalStatus,
            long startNs
    ) {
        try {
            AiToolAudit audit = new AiToolAudit();
            audit.setBusiness(business);
            audit.setUser(user);
            audit.setConversationId(conversationId);
            audit.setToolName(toolName);
            audit.setArgumentsHash(AiVectorRepository.sha256Hex(draftId != null ? draftId : ""));
            audit.setResultStatus("OK");
            audit.setApprovalStatus(approvalStatus);
            audit.setDurationMs(Math.max(0L, (System.nanoTime() - startNs) / 1_000_000L));
            toolAuditRepository.save(audit);
        } catch (Exception ignored) {}
    }
}
