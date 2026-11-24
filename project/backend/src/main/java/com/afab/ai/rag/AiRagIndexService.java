package com.afab.ai.rag;

import com.afab.ai.config.AiProperties;
import com.afab.ai.domain.BusinessMemory;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.gateway.AiModelGateway;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.repository.RecurringTransactionRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.*;

/**
 * Indexes business records and approved Business Memory into PostgreSQL pgvector + FTS
 * using EmbeddingGemma 2 documented task prefixes (Spec Appendix B3).
 * Gracefully preserves lexical FTS chunks when Ollama embeddings are temporarily offline.
 */
@Service
public class AiRagIndexService {

    public record IndexSyncStats(int indexedCount, int skippedUnchanged, int embeddingsGenerated, boolean embeddingAvailable) {}

    private final AiProperties properties;
    private final AiModelGateway modelGateway;
    private final AiVectorRepository vectorRepository;
    private final BusinessMemoryRepository memoryRepository;
    private final TransactionRepository transactionRepository;
    private final InvoiceRepository invoiceRepository;
    private final CustomerRepository customerRepository;
    private final BudgetService budgetService;
    private final RecurringTransactionRepository recurringRepository;

    public AiRagIndexService(
            AiProperties properties,
            AiModelGateway modelGateway,
            AiVectorRepository vectorRepository,
            BusinessMemoryRepository memoryRepository,
            TransactionRepository transactionRepository,
            InvoiceRepository invoiceRepository,
            CustomerRepository customerRepository,
            BudgetService budgetService,
            RecurringTransactionRepository recurringRepository
    ) {
        this.properties = properties;
        this.modelGateway = modelGateway;
        this.vectorRepository = vectorRepository;
        this.memoryRepository = memoryRepository;
        this.transactionRepository = transactionRepository;
        this.invoiceRepository = invoiceRepository;
        this.customerRepository = customerRepository;
        this.budgetService = budgetService;
        this.recurringRepository = recurringRepository;
    }

    public String formatQueryInput(String question) {
        return "task: question answering | query: " + (question != null ? question.trim() : "");
    }

    public String formatDocumentInput(String title, String content) {
        return "title: " + (title != null ? title.trim() : "") + " | text: " + (content != null ? content.trim() : "");
    }

    public float[] tryEmbedQuery(String question) {
        try {
            AiModelGateway.GatewayHealth health = modelGateway.checkHealth();
            if (!health.reachable() || !health.embedModelReady()) {
                return null;
            }
            return modelGateway.embed(formatQueryInput(question));
        } catch (Exception ignored) {
            return null;
        }
    }

    public void embedMemoryIfPossible(BusinessMemory memory) {
        if (memory == null || memory.getId() == null || memory.getBusiness() == null) {
            return;
        }
        try {
            AiModelGateway.GatewayHealth health = modelGateway.checkHealth();
            if (!health.reachable() || !health.embedModelReady()) {
                return;
            }
            float[] vec = modelGateway.embed(formatDocumentInput(memory.getTitle(), memory.getContent()));
            vectorRepository.upsertMemoryVector(
                    memory.getId(),
                    memory.getBusiness().getId(),
                    vec,
                    properties.getEmbedModel(),
                    properties.getEmbeddingDimension()
            );
        } catch (Exception ignored) {
            // Memory CRUD succeeds cleanly even if local Ollama is stopped
        }
    }

    public IndexSyncStats syncBusinessIndex(Business business) {
        UUID businessId = business.getId();
        boolean embeddingAvailable = false;
        try {
            AiModelGateway.GatewayHealth health = modelGateway.checkHealth();
            embeddingAvailable = health.reachable() && health.embedModelReady();
        } catch (Exception ignored) {
            embeddingAvailable = false;
        }

        int indexed = 0;
        int skipped = 0;
        int embeddingsGenerated = 0;

        List<ChunkCandidate> candidates = collectCandidates(business);
        for (ChunkCandidate c : candidates) {
            String hash = AiVectorRepository.sha256Hex(c.title() + "\n" + c.content());
            String existingHash = vectorRepository.findChunkContentHash(businessId, c.sourceType(), c.sourceId());
            boolean alreadyHasVec = existingHash != null && existingHash.equals(hash)
                    && vectorRepository.chunkHasVector(businessId, c.sourceType(), c.sourceId());

            if (existingHash != null && existingHash.equals(hash) && (!embeddingAvailable || alreadyHasVec)) {
                skipped++;
                continue;
            }

            float[] vec = null;
            if (embeddingAvailable) {
                try {
                    vec = modelGateway.embed(formatDocumentInput(c.title(), c.content()));
                    embeddingsGenerated++;
                } catch (Exception ignored) {
                    embeddingAvailable = false;
                }
            }

            vectorRepository.upsertChunk(
                    businessId,
                    c.sourceType(),
                    c.sourceId(),
                    c.title(),
                    c.content(),
                    hash,
                    vec,
                    vec != null ? properties.getEmbedModel() : null,
                    vec != null ? properties.getEmbeddingDimension() : null
            );
            indexed++;
        }

        if (embeddingAvailable) {
            List<BusinessMemory> memories = memoryRepository.findByBusinessIdAndStatus(businessId, "APPROVED");
            Set<UUID> existingVecIds = vectorRepository.findMemoryIdsWithVectors(businessId);
            for (BusinessMemory mem : memories) {
                if (!existingVecIds.contains(mem.getId())) {
                    try {
                        float[] vec = modelGateway.embed(formatDocumentInput(mem.getTitle(), mem.getContent()));
                        vectorRepository.upsertMemoryVector(
                                mem.getId(),
                                businessId,
                                vec,
                                properties.getEmbedModel(),
                                properties.getEmbeddingDimension()
                        );
                        embeddingsGenerated++;
                    } catch (Exception ignored) {
                        break;
                    }
                }
            }
        }

        return new IndexSyncStats(indexed, skipped, embeddingsGenerated, embeddingAvailable);
    }

    private record ChunkCandidate(String sourceType, UUID sourceId, String title, String content) {}

    private List<ChunkCandidate> collectCandidates(Business business) {
        UUID businessId = business.getId();
        List<ChunkCandidate> out = new ArrayList<>();

        List<Transaction> txList = transactionRepository.findTopActiveRootTransactionsWithCategory(
                businessId, PageRequest.of(0, 500)
        );
        for (Transaction tx : txList) {
            String catName = tx.getCategory() != null ? tx.getCategory().getName() : "Uncategorized";
            String title = String.format("%s %s (%s %s)",
                    tx.getType(),
                    tx.getDescription(),
                    tx.getAmount() != null ? tx.getAmount().stripTrailingZeros().toPlainString() : "0",
                    tx.getCurrency() != null ? tx.getCurrency() : business.getCurrency());
            String content = String.format(
                    "Type: %s | Date: %s | Amount: %s %s | Category: %s | Status: %s | Payment: %s | Description: %s | Notes: %s",
                    tx.getType(),
                    tx.getTransactionDate(),
                    tx.getAmount(),
                    tx.getCurrency(),
                    catName,
                    tx.getStatus(),
                    tx.getPaymentMethod() != null ? tx.getPaymentMethod() : "N/A",
                    tx.getDescription(),
                    tx.getNotes() != null ? tx.getNotes() : ""
            );
            out.add(new ChunkCandidate("TRANSACTION", tx.getId(), truncate(title, 190), truncate(content, 1200)));
        }

        LocalDate today = LocalDate.now();
        List<Invoice> invoices = invoiceRepository.findAllByBusinessIdWithCustomer(businessId);
        for (Invoice inv : invoices) {
            String custName = inv.getCustomer() != null ? inv.getCustomer().getName() : "Walk-in / Unassigned";
            String effStatus = inv.computeEffectiveStatus(today).name();
            String title = String.format("Invoice %s — %s (%s %s)",
                    inv.getInvoiceNumber(), custName, inv.getTotalAmount(), inv.getCurrency());
            String content = String.format(
                    "Invoice %s | Customer: %s | Status: %s | Issue Date: %s | Due Date: %s | Total: %s %s | Paid: %s | Outstanding: %s | Notes: %s",
                    inv.getInvoiceNumber(),
                    custName,
                    effStatus,
                    inv.getIssueDate(),
                    inv.getDueDate(),
                    inv.getTotalAmount(),
                    inv.getCurrency(),
                    inv.getPaidAmount(),
                    inv.getOutstandingBalance(),
                    inv.getNotes() != null ? inv.getNotes() : ""
            );
            out.add(new ChunkCandidate("INVOICE", inv.getId(), truncate(title, 190), truncate(content, 1200)));
        }

        List<Customer> customers = customerRepository.findAllActiveByBusinessId(businessId);
        for (Customer c : customers) {
            String title = String.format("Customer %s (%s)", c.getName(), c.getCustomerCode());
            String content = String.format(
                    "Customer Code: %s | Name: %s | Company: %s | Group: %s | Status: %s | Notes: %s",
                    c.getCustomerCode(),
                    c.getName(),
                    c.getCompanyName() != null ? c.getCompanyName() : "",
                    c.getCustomerGroup(),
                    c.getStatus(),
                    c.getNotes() != null ? c.getNotes() : ""
            );
            out.add(new ChunkCandidate("CUSTOMER", c.getId(), truncate(title, 190), truncate(content, 1200)));
        }

        BudgetSummaryDTO budgets = budgetService.buildSummaryForBusiness(business, today);
        if (budgets != null && budgets.budgets() != null) {
            for (BudgetDTO b : budgets.budgets()) {
                String title = String.format("Budget %s (%s)", b.name(), b.alertLevel());
                String content = String.format(
                        "Budget: %s | Period: %s (%s to %s) | Category: %s | Limit: %s %s | Spent: %s | Remaining: %s | Consumed: %s%% | Alert: %s",
                        b.name(), b.periodType(), b.startDate(), b.endDate(),
                        b.categoryName() != null ? b.categoryName() : "Overall",
                        b.budgetAmount(), b.currency(), b.actualSpending(), b.remainingAmount(),
                        b.percentageConsumed(), b.alertLevel()
                );
                out.add(new ChunkCandidate("BUDGET", b.id(), truncate(title, 190), truncate(content, 1200)));
            }
        }

        List<RecurringTransaction> recurring = recurringRepository.findAllByBusinessId(businessId);
        for (RecurringTransaction r : recurring) {
            String catName = r.getCategory() != null ? r.getCategory().getName() : "Uncategorized";
            String title = String.format("Recurring %s: %s (%s %s)", r.getType(), r.getDescription(), r.getAmount(), r.getCurrency());
            String content = String.format(
                    "Recurring Rule: %s | Type: %s | Frequency: %s | Amount: %s %s | Category: %s | Next Run: %s | Active: %s | Notes: %s",
                    r.getDescription(), r.getType(), r.getFrequency(), r.getAmount(), r.getCurrency(),
                    catName, r.getNextExecutionDate(), r.isActive(), r.getNotes() != null ? r.getNotes() : ""
            );
            out.add(new ChunkCandidate("RECURRING", r.getId(), truncate(title, 190), truncate(content, 1200)));
        }

        return out;
    }

    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }
}
