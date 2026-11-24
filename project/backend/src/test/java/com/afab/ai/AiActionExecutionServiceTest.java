package com.afab.ai;

import com.afab.ai.domain.AiConversation;
import com.afab.ai.domain.AiMessage;
import com.afab.ai.domain.AiMessageRepository;
import com.afab.ai.domain.AiToolAuditRepository;
import com.afab.ai.dto.AiActionDraftDTO;
import com.afab.ai.dto.ApproveTransactionDraftRequest;
import com.afab.ai.service.AiActionExecutionService;
import com.afab.ai.service.AiAttachmentService;
import com.afab.ai.service.BusinessMemoryService;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.TransactionDTO;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.TransactionService;
import com.afab.invoices.service.InvoiceService;
import com.afab.user.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AiActionExecutionServiceTest {

    @Mock private AiMessageRepository messageRepository;
    @Mock private AiToolAuditRepository toolAuditRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private TransactionService transactionService;
    @Mock private TransactionRepository transactionRepository;
    @Mock private InvoiceService invoiceService;
    @Mock private BudgetService budgetService;
    @Mock private BusinessMemoryService businessMemoryService;
    @Mock private AiAttachmentService attachmentService;

    private AiActionExecutionService executionService;
    private User userA;
    private User userB;
    private Business bizA;
    private Business bizB;
    private final ObjectMapper mapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        executionService = new AiActionExecutionService(
                messageRepository, toolAuditRepository, currentBusinessService,
                transactionService, transactionRepository, invoiceService,
                budgetService, businessMemoryService, attachmentService
        );
        userA = new User("Alice", "Owner", "alice@bizA.test", "hash");
        userA.setId(UUID.randomUUID());
        bizA = new Business(userA, "Alpha Bakery", "TND");
        bizA.setId(UUID.randomUUID());

        userB = new User("Bob", "Other", "bob@bizB.test", "hash");
        userB.setId(UUID.randomUUID());
        bizB = new Business(userB, "Beta Motors", "USD");
        bizB.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Blocks cross-tenant approval of another business's draft message")
    void blocksCrossTenantApproval() {
        UUID msgId = UUID.randomUUID();
        AiMessage msg = new AiMessage();
        msg.setId(msgId);
        msg.setBusiness(bizA);

        when(currentBusinessService.getCurrentUser("bob@bizB.test")).thenReturn(userB);
        when(currentBusinessService.getCurrentBusiness("bob@bizB.test")).thenReturn(bizB);
        when(messageRepository.findById(msgId)).thenReturn(Optional.of(msg));

        ApproveTransactionDraftRequest req = new ApproveTransactionDraftRequest();
        req.setMessageId(msgId);
        req.setDraftId("tx-draft-1");
        req.setType("EXPENSE");
        req.setAmount(new BigDecimal("145.00"));
        req.setDescription("Essence");
        req.setTransactionDate(LocalDate.now());

        assertThatThrownBy(() -> executionService.approveTransaction("bob@bizB.test", req))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    @DisplayName("Approving transaction draft persists record, promotes receipt, and updates actionDraftsJson")
    void approvesTransactionAndPromotesReceipt() throws Exception {
        UUID convId = UUID.randomUUID();
        UUID msgId = UUID.randomUUID();
        UUID stagedId = UUID.randomUUID();
        UUID txId = UUID.randomUUID();

        AiConversation conv = new AiConversation();
        conv.setId(convId);

        AiMessage msg = new AiMessage();
        msg.setId(msgId);
        msg.setBusiness(bizA);
        msg.setConversation(conv);
        msg.setActionDraftsJson(mapper.writeValueAsString(List.of(
                new AiActionDraftDTO("tx-draft-9", "CREATE_TRANSACTION", "PENDING", "Essence", "145 TND", Map.of(), stagedId, null, null)
        )));

        when(currentBusinessService.getCurrentUser("alice@bizA.test")).thenReturn(userA);
        when(currentBusinessService.getCurrentBusiness("alice@bizA.test")).thenReturn(bizA);
        when(messageRepository.findById(msgId)).thenReturn(Optional.of(msg));

        TransactionDTO createdDto = new TransactionDTO();
        createdDto.setId(txId);
        when(transactionService.createTransaction(eq("alice@bizA.test"), any())).thenReturn(createdDto);

        Transaction txEntity = new Transaction();
        txEntity.setId(txId);
        txEntity.setDescription("Essence Shell");
        when(transactionRepository.findActiveById(txId)).thenReturn(Optional.of(txEntity));

        ApproveTransactionDraftRequest req = new ApproveTransactionDraftRequest();
        req.setMessageId(msgId);
        req.setDraftId("tx-draft-9");
        req.setType("EXPENSE");
        req.setAmount(new BigDecimal("145.00"));
        req.setDescription("Essence Shell");
        req.setTransactionDate(LocalDate.now());
        req.setStagedAttachmentId(stagedId);
        req.setExtractedOcrText("Shell station total 145 TND");

        AiActionDraftDTO result = executionService.approveTransaction("alice@bizA.test", req);

        assertThat(result.status()).isEqualTo("APPROVED");
        assertThat(result.createdEntityId()).isEqualTo(txId);
        assertThat(result.createdEntityHref()).isEqualTo("/dashboard/transactions");
        assertThat(msg.getActionDraftsJson()).contains("APPROVED");

        verify(attachmentService).promoteToTransactionReceipt(userA, bizA, txEntity, stagedId, "Shell station total 145 TND");
        verify(toolAuditRepository).save(any());
    }
}
