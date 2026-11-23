package com.afab.recurring.service;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.finance.domain.Category;
import com.afab.finance.repository.CategoryRepository;
import com.afab.recurring.domain.RecurrenceFrequency;
import com.afab.recurring.domain.RecurringTransaction;
import com.afab.recurring.dto.RecurringTransactionDTO;
import com.afab.recurring.dto.RecurringTransactionRequest;
import com.afab.recurring.repository.RecurringTransactionExecutionRepository;
import com.afab.recurring.repository.RecurringTransactionRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

@Service
public class RecurringTransactionService {

    private static final Logger log = LoggerFactory.getLogger(RecurringTransactionService.class);
    private static final int MAX_CATCHUP_OCCURRENCES_PER_RUN = 24;

    private final RecurringTransactionRepository recurringRepository;
    private final RecurringTransactionExecutionRepository executionRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentBusinessService currentBusinessService;
    private final RecurringExecutionProcessor executionProcessor;
    private final AuditService auditService;
    private final Clock clock;

    @Autowired
    public RecurringTransactionService(
            RecurringTransactionRepository recurringRepository,
            RecurringTransactionExecutionRepository executionRepository,
            CategoryRepository categoryRepository,
            CurrentBusinessService currentBusinessService,
            RecurringExecutionProcessor executionProcessor,
            AuditService auditService
    ) {
        this(recurringRepository, executionRepository, categoryRepository,
                currentBusinessService, executionProcessor, auditService, Clock.systemUTC());
    }

    public RecurringTransactionService(
            RecurringTransactionRepository recurringRepository,
            RecurringTransactionExecutionRepository executionRepository,
            CategoryRepository categoryRepository,
            CurrentBusinessService currentBusinessService,
            RecurringExecutionProcessor executionProcessor,
            AuditService auditService,
            Clock clock
    ) {
        this.recurringRepository = recurringRepository;
        this.executionRepository = executionRepository;
        this.categoryRepository = categoryRepository;
        this.currentBusinessService = currentBusinessService;
        this.executionProcessor = executionProcessor;
        this.auditService = auditService;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<RecurringTransactionDTO> list(String userEmail) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        return recurringRepository.findAllByBusinessId(business.getId()).stream()
                .map(this::toDTO)
                .toList();
    }

    @Transactional(readOnly = true)
    public RecurringTransactionDTO getById(String userEmail, UUID id) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        RecurringTransaction rule = loadOwnedRule(id, business.getId());
        return toDTO(rule);
    }

    @Transactional
    public RecurringTransactionDTO create(String userEmail, RecurringTransactionRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        validateDates(request.getStartDate(), request.getEndDate());
        String type = request.getType().toUpperCase(Locale.ROOT).trim();
        Category category = resolveAndValidateCategory(request.getCategoryId(), business.getId(), type);

        String currency = (request.getCurrency() != null && !request.getCurrency().isBlank())
                ? request.getCurrency().toUpperCase(Locale.ROOT).trim()
                : (business.getCurrency() != null && !business.getCurrency().isBlank()
                    ? business.getCurrency().toUpperCase(Locale.ROOT).trim()
                    : "USD");

        RecurringTransaction rule = new RecurringTransaction();
        rule.setBusiness(business);
        rule.setType(type);
        rule.setDescription(request.getDescription().trim());
        rule.setAmount(request.getAmount().setScale(4, RoundingMode.HALF_UP));
        rule.setCurrency(currency);
        rule.setCategory(category);
        rule.setPaymentMethod(request.getPaymentMethod() != null && !request.getPaymentMethod().isBlank()
                ? request.getPaymentMethod().toUpperCase(Locale.ROOT).trim()
                : "BANK_TRANSFER");
        rule.setFrequency(RecurrenceFrequency.valueOf(request.getFrequency().toUpperCase(Locale.ROOT).trim()));
        rule.setStartDate(request.getStartDate());
        rule.setEndDate(request.getEndDate());
        rule.setNextExecutionDate(request.getStartDate());
        rule.setActive(request.getActive() == null || request.getActive());
        rule.setNotes(request.getNotes() != null && !request.getNotes().isBlank() ? request.getNotes().trim() : null);

        rule = recurringRepository.save(rule);
        auditService.log(user, "CREATE", "RecurringTransaction", rule.getId(), null);
        return toDTO(rule);
    }

    @Transactional
    public RecurringTransactionDTO update(String userEmail, UUID id, RecurringTransactionRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);

        RecurringTransaction rule = loadOwnedRule(id, business.getId());
        validateDates(request.getStartDate(), request.getEndDate());

        String type = request.getType().toUpperCase(Locale.ROOT).trim();
        Category category = resolveAndValidateCategory(request.getCategoryId(), business.getId(), type);

        String currency = (request.getCurrency() != null && !request.getCurrency().isBlank())
                ? request.getCurrency().toUpperCase(Locale.ROOT).trim()
                : rule.getCurrency();

        rule.setType(type);
        rule.setDescription(request.getDescription().trim());
        rule.setAmount(request.getAmount().setScale(4, RoundingMode.HALF_UP));
        rule.setCurrency(currency);
        rule.setCategory(category);
        if (request.getPaymentMethod() != null && !request.getPaymentMethod().isBlank()) {
            rule.setPaymentMethod(request.getPaymentMethod().toUpperCase(Locale.ROOT).trim());
        }
        rule.setFrequency(RecurrenceFrequency.valueOf(request.getFrequency().toUpperCase(Locale.ROOT).trim()));
        rule.setStartDate(request.getStartDate());
        rule.setEndDate(request.getEndDate());

        if (rule.getNextExecutionDate() == null || rule.getNextExecutionDate().isBefore(request.getStartDate())) {
            rule.setNextExecutionDate(request.getStartDate());
        }
        if (request.getActive() != null) {
            rule.setActive(request.getActive());
        }
        if (rule.getEndDate() != null && rule.getNextExecutionDate().isAfter(rule.getEndDate())) {
            rule.setActive(false);
        }
        rule.setNotes(request.getNotes() != null && !request.getNotes().isBlank() ? request.getNotes().trim() : null);

        rule = recurringRepository.save(rule);
        auditService.log(user, "UPDATE", "RecurringTransaction", rule.getId(), null);
        return toDTO(rule);
    }

    @Transactional
    public RecurringTransactionDTO setActive(String userEmail, UUID id, boolean active) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        RecurringTransaction rule = loadOwnedRule(id, business.getId());

        if (active && rule.getEndDate() != null && rule.getNextExecutionDate() != null
                && rule.getNextExecutionDate().isAfter(rule.getEndDate())) {
            throw new IllegalArgumentException("Cannot activate a recurring rule whose next execution date is past its end date.");
        }

        rule.setActive(active);
        rule = recurringRepository.save(rule);
        auditService.log(user, active ? "RESUME" : "PAUSE", "RecurringTransaction", rule.getId(), null);
        return toDTO(rule);
    }

    @Transactional
    public void delete(String userEmail, UUID id) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        RecurringTransaction rule = loadOwnedRule(id, business.getId());

        boolean hasExecutions = !executionRepository.findByRecurringTransactionIdOrderByScheduledDateDesc(rule.getId()).isEmpty();
        if (hasExecutions) {
            // Preserve execution history & transaction lineage by deactivating instead of hard-deleting
            rule.setActive(false);
            recurringRepository.save(rule);
            auditService.log(user, "DEACTIVATE", "RecurringTransaction", rule.getId(), null);
        } else {
            recurringRepository.delete(rule);
            auditService.log(user, "DELETE", "RecurringTransaction", rule.getId(), null);
        }
    }

    public RunResult runDueForRule(String userEmail, UUID id) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        RecurringTransaction rule = loadOwnedRule(id, business.getId());
        LocalDate businessToday = currentDateForBusiness(business);
        List<UUID> generatedIds = executeDueOccurrencesForRule(rule.getId(), businessToday);
        RecurringTransaction refreshed = recurringRepository.findById(rule.getId()).orElse(rule);
        return new RunResult(toDTO(refreshed), generatedIds.size(), generatedIds);
    }

    /**
     * Scheduled sweep across all active non-archived businesses.
     * Uses UTC+1d cutoff query to capture UTC+14 timezones, then enforces each business's exact local date.
     */
    public int processDueRecurringTransactions() {
        LocalDate utcCutoff = LocalDate.now(clock.withZone(ZoneOffset.UTC)).plusDays(1);
        List<RecurringTransaction> candidates = recurringRepository.findPotentiallyDueRules(utcCutoff);
        int totalGenerated = 0;

        for (RecurringTransaction rule : candidates) {
            Business business = rule.getBusiness();
            if (business == null || business.getArchivedAt() != null) {
                continue;
            }
            LocalDate businessToday = currentDateForBusiness(business);
            if (rule.getNextExecutionDate() != null && !rule.getNextExecutionDate().isAfter(businessToday)) {
                try {
                    List<UUID> ids = executeDueOccurrencesForRule(rule.getId(), businessToday);
                    totalGenerated += ids.size();
                } catch (Exception ex) {
                    log.error("Failed processing recurring ruleId={}: {}", rule.getId(), ex.getMessage());
                }
            }
        }
        return totalGenerated;
    }

    public List<UUID> executeDueOccurrencesForRule(UUID ruleId, LocalDate businessToday) {
        List<UUID> generatedIds = new ArrayList<>();
        for (int i = 0; i < MAX_CATCHUP_OCCURRENCES_PER_RUN; i++) {
            try {
                Optional<UUID> createdTxId = executionProcessor.executeSingleDueOccurrence(ruleId, businessToday);
                if (createdTxId.isEmpty()) {
                    break;
                }
                generatedIds.add(createdTxId.get());
            } catch (DataIntegrityViolationException dupEx) {
                // Concurrent instance already executed this (ruleId, scheduledDate) occurrence — safe to stop
                log.info("Concurrent execution detected for recurring ruleId={}; idempotent skip", ruleId);
                break;
            }
        }
        return generatedIds;
    }

    public ZoneId resolveBusinessZone(Business business) {
        String tz = business != null ? business.getTimezone() : null;
        if (tz != null && !tz.isBlank()) {
            try {
                return ZoneId.of(tz.trim());
            } catch (Exception ignored) {
                log.warn("Invalid business timezone '{}'; falling back to UTC", tz);
            }
        }
        return ZoneOffset.UTC;
    }

    public LocalDate currentDateForBusiness(Business business) {
        return LocalDate.now(clock.withZone(resolveBusinessZone(business)));
    }

    private RecurringTransaction loadOwnedRule(UUID id, UUID businessId) {
        RecurringTransaction rule = recurringRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Recurring transaction rule not found: " + id));
        if (rule.getBusiness() == null || !rule.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Recurring transaction rule belongs to another business.");
        }
        return rule;
    }

    private void validateDates(LocalDate startDate, LocalDate endDate) {
        if (startDate == null) {
            throw new IllegalArgumentException("Start date is required.");
        }
        if (endDate != null && endDate.isBefore(startDate)) {
            throw new IllegalArgumentException("End date cannot be earlier than start date.");
        }
    }

    private Category resolveAndValidateCategory(UUID categoryId, UUID businessId, String type) {
        if (categoryId == null) {
            return null;
        }
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + categoryId));
        if (category.getBusiness() != null && !category.getBusiness().getId().equals(businessId)) {
            throw new ForbiddenException("Unauthorized: Category belongs to another business.");
        }
        if (!category.getType().equalsIgnoreCase(type)) {
            throw new IllegalArgumentException("Category type '" + category.getType() + "' does not match rule type '" + type + "'.");
        }
        return category;
    }

    private RecurringTransactionDTO toDTO(RecurringTransaction rule) {
        Category cat = rule.getCategory();
        return new RecurringTransactionDTO(
                rule.getId(),
                rule.getBusiness() != null ? rule.getBusiness().getId() : null,
                rule.getType(),
                rule.getDescription(),
                rule.getAmount(),
                rule.getCurrency(),
                cat != null ? cat.getId() : null,
                cat != null ? cat.getName() : null,
                rule.getPaymentMethod(),
                rule.getFrequency() != null ? rule.getFrequency().name() : null,
                rule.getStartDate(),
                rule.getEndDate(),
                rule.getNextExecutionDate(),
                rule.isActive(),
                rule.getNotes(),
                rule.getLastExecutedAt(),
                rule.getCreatedAt(),
                rule.getUpdatedAt()
        );
    }

    public record RunResult(RecurringTransactionDTO rule, int generatedCount, List<UUID> transactionIds) {}
}
