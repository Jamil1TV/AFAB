package com.afab.ai.rag;

import com.afab.ai.config.AiProperties;
import com.afab.ai.domain.BusinessMemory;
import com.afab.ai.domain.BusinessMemoryRepository;
import com.afab.ai.gateway.AiModelGateway;
import com.afab.budgets.domain.Budget;
import com.afab.budgets.dto.BudgetDTO;
import com.afab.budgets.dto.BudgetSummaryDTO;
import com.afab.budgets.repository.BudgetRepository;
import com.afab.budgets.service.BudgetService;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.finance.domain.Transaction;
import com.afab.finance.repository.TransactionRepository;
import com.afab.invoices.domain.Invoice;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.receipts.domain.Receipt;
import com.afab.receipts.repository.ReceiptRepository;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.repository.RecurringTransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
    private BudgetRepository budgetRepository;
    private BusinessRepository businessRepository;
    private ReceiptRepository receiptRepository;

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

    @Autowired(required = false)
    public void setOptionalRepositories(
            BudgetRepository budgetRepository,
            BusinessRepository businessRepository,
            ReceiptRepository receiptRepository
    ) {
        this.budgetRepository = budgetRepository;
        this.businessRepository = businessRepository;
        this.receiptRepository = receiptRepository;
    }

    @Transactional(readOnly = true)
    public void upsertSingleRecord(UUID businessId, String sourceType, UUID sourceId) {
        if (businessId == null || sourceType == null || sourceId == null) return;
        Business business = businessRepository != null ? businessRepository.findById(businessId).orElse(null) : null;
        String baseCurrency = business != null && business.getCurrency() != null ? business.getCurrency() : "USD";

        ChunkCandidate candidate = switch (sourceType.toUpperCase(Locale.ROOT)) {
            case "TRANSACTION" -> transactionRepository.findActiveById(sourceId)
                    .filter(tx -> tx.getBusiness() != null && businessId.equals(tx.getBusiness().getId()))
                    .map(tx -> toTransactionCandidate(tx, baseCurrency))
                    .orElse(null);
            case "INVOICE" -> invoiceRepository.findWithDetailsById(sourceId)
                    .filter(inv -> inv.getBusiness() != null && businessId.equals(inv.getBusiness().getId()))
                    .map(this::toInvoiceCandidate)
                    .orElse(null);
            case "CUSTOMER" -> customerRepository.findActiveById(sourceId)
                    .filter(c -> c.getBusiness() != null && businessId.equals(c.getBusiness().getId()))
                    .map(this::toCustomerCandidate)
                    .orElse(null);
            case "BUDGET" -> budgetRepository == null ? null : budgetRepository.findActiveById(sourceId)
                    .filter(b -> b.getBusiness() != null && businessId.equals(b.getBusiness().getId()))
                    .map(b -> {
                        BudgetDTO dto = budgetService.evaluateBudget(b);
                        String title = String.format("Budget %s (%s)", dto.name(), dto.alertLevel());
                        String content = String.format(
                                "Budget: %s | Period: %s (%s to %s) | Category: %s | Limit: %s %s | Spent: %s | Remaining: %s | Consumed: %s%% | Alert: %s",
                                dto.name(), dto.periodType(), dto.startDate(), dto.endDate(),
                                dto.categoryName() != null ? dto.categoryName() : "Overall",
                                dto.budgetAmount(), dto.currency(), dto.actualSpending(), dto.remainingAmount(),
                                dto.percentageConsumed(), dto.alertLevel()
                        );
                        return new ChunkCandidate("BUDGET", dto.id(), truncate(title, 190), truncate(content, 1200));
                    })
                    .orElse(null);
            case "RECURRING" -> recurringRepository.findById(sourceId)
                    .filter(r -> r.getBusiness() != null && businessId.equals(r.getBusiness().getId()))
                    .map(this::toRecurringCandidate)
                    .orElse(null);
            case "RECEIPT" -> receiptRepository == null ? null : receiptRepository.findActiveById(sourceId)
                    .filter(r -> r.getBusiness() != null && businessId.equals(r.getBusiness().getId()))
                    .map(r -> {
                        String txDesc = r.getTransaction() != null ? r.getTransaction().getDescription() : "";
                        String title = "Receipt: " + r.getOriginalFilename() + (txDesc.isBlank() ? "" : " (" + txDesc + ")");
                        String content = String.format(
                                "Receipt file: %s | Type: %s | Linked transaction: %s | Uploaded: %s",
                                r.getOriginalFilename(), r.getContentType(), txDesc, r.getCreatedAt()
                        );
                        return new ChunkCandidate("RECEIPT", r.getId(), truncate(title, 190), truncate(content, 1200));
                    })
                    .orElse(null);
            default -> null;
        };

        if (candidate != null) {
            upsertCandidate(businessId, candidate);
        }
    }

    public void upsertReceiptChunk(UUID businessId, UUID receiptId, String filename, String txDescription, String ocrText) {
        if (businessId == null || receiptId == null) return;
        String title = "Receipt: " + (filename != null ? filename : "Uploaded Receipt")
                + (txDescription != null && !txDescription.isBlank() ? " (" + txDescription + ")" : "");
        String content = "Receipt: " + (filename != null ? filename : "") + " | Transaction: "
                + (txDescription != null ? txDescription : "") + " | Extracted details: "
                + (ocrText != null ? ocrText : "");
        upsertCandidate(businessId, new ChunkCandidate("RECEIPT", receiptId, truncate(title, 190), truncate(content, 1800)));
    }

    public void deleteSingleRecord(UUID businessId, String sourceType, UUID sourceId) {
        if (businessId == null || sourceType == null || sourceId == null) return;
        vectorRepository.deleteChunk(businessId, sourceType.toUpperCase(Locale.ROOT), sourceId);
    }

    private void upsertCandidate(UUID businessId, ChunkCandidate candidate) {
        String hash = AiVectorRepository.sha256Hex(candidate.title() + "\n" + candidate.content());
        String existingHash = vectorRepository.findChunkContentHash(businessId, candidate.sourceType(), candidate.sourceId());
        boolean alreadyHasVec = existingHash != null && existingHash.equals(hash)
                && vectorRepository.chunkHasVector(businessId, candidate.sourceType(), candidate.sourceId());
        if (existingHash != null && existingHash.equals(hash) && alreadyHasVec) {
            return;
        }
        float[] vec = null;
        try {
            AiModelGateway.GatewayHealth health = modelGateway.checkHealth();
            if (health.reachable() && health.embedModelReady()) {
                vec = modelGateway.embed(formatDocumentInput(candidate.title(), candidate.content()));
            }
        } catch (Exception ignored) {
            // Preserve lexical FTS chunk cleanly when Ollama embeddings are temporarily offline
        }
        vectorRepository.upsertChunk(
                businessId,
                candidate.sourceType(),
                candidate.sourceId(),
                candidate.title(),
                candidate.content(),
                hash,
                vec,
                vec != null ? properties.getEmbedModel() : null,
                vec != null ? properties.getEmbeddingDimension() : null
        );
    }

    private ChunkCandidate toTransactionCandidate(Transaction tx, String fallbackCurrency) {
        String catName = tx.getCategory() != null ? tx.getCategory().getName() : "Uncategorized";
        String curr = tx.getCurrency() != null ? tx.getCurrency() : fallbackCurrency;
        String title = String.format("%s %s (%s %s)",
                tx.getType(),
                tx.getDescription(),
                tx.getAmount() != null ? tx.getAmount().stripTrailingZeros().toPlainString() : "0",
                curr);
        String content = String.format(
                "Type: %s | Date: %s | Amount: %s %s | Category: %s | Status: %s | Payment: %s | Description: %s | Notes: %s",
                tx.getType(), tx.getTransactionDate(), tx.getAmount(), tx.getCurrency(),
                catName, tx.getStatus(), tx.getPaymentMethod() != null ? tx.getPaymentMethod() : "N/A",
                tx.getDescription(), tx.getNotes() != null ? tx.getNotes() : ""
        );
        return new ChunkCandidate("TRANSACTION", tx.getId(), truncate(title, 190), truncate(content, 1200));
    }

    private ChunkCandidate toInvoiceCandidate(Invoice inv) {
        String custName = inv.getCustomer() != null ? inv.getCustomer().getName() : "Walk-in / Unassigned";
        String effStatus = inv.computeEffectiveStatus(LocalDate.now()).name();
        String title = String.format("Invoice %s — %s (%s %s)",
                inv.getInvoiceNumber(), custName, inv.getTotalAmount(), inv.getCurrency());
        String content = String.format(
                "Invoice %s | Customer: %s | Status: %s | Issue Date: %s | Due Date: %s | Total: %s %s | Paid: %s | Outstanding: %s | Notes: %s",
                inv.getInvoiceNumber(), custName, effStatus, inv.getIssueDate(), inv.getDueDate(),
                inv.getTotalAmount(), inv.getCurrency(), inv.getPaidAmount(), inv.getOutstandingBalance(),
                inv.getNotes() != null ? inv.getNotes() : ""
        );
        return new ChunkCandidate("INVOICE", inv.getId(), truncate(title, 190), truncate(content, 1200));
    }

    private ChunkCandidate toCustomerCandidate(Customer c) {
        String title = String.format("Customer %s (%s)", c.getName(), c.getCustomerCode());
        String content = String.format(
                "Customer Code: %s | Name: %s | Company: %s | Group: %s | Status: %s | Notes: %s",
                c.getCustomerCode(), c.getName(), c.getCompanyName() != null ? c.getCompanyName() : "",
                c.getCustomerGroup(), c.getStatus(), c.getNotes() != null ? c.getNotes() : ""
        );
        return new ChunkCandidate("CUSTOMER", c.getId(), truncate(title, 190), truncate(content, 1200));
    }

    private ChunkCandidate toRecurringCandidate(RecurringTransaction r) {
        String catName = r.getCategory() != null ? r.getCategory().getName() : "Uncategorized";
        String title = String.format("Recurring %s: %s (%s %s)", r.getType(), r.getDescription(), r.getAmount(), r.getCurrency());
        String content = String.format(
                "Recurring Rule: %s | Type: %s | Frequency: %s | Amount: %s %s | Category: %s | Next Run: %s | Active: %s | Notes: %s",
                r.getDescription(), r.getType(), r.getFrequency(), r.getAmount(), r.getCurrency(),
                catName, r.getNextExecutionDate(), r.isActive(), r.getNotes() != null ? r.getNotes() : ""
        );
        return new ChunkCandidate("RECURRING", r.getId(), truncate(title, 190), truncate(content, 1200));
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
