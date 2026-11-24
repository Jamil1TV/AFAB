package com.afab.customers.service;

import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.customers.domain.Customer;
import com.afab.customers.dto.*;
import com.afab.customers.dto.CustomerSummaryDTO.CustomerActivityItem;
import com.afab.customers.dto.CustomerSummaryDTO.OverviewDonut;
import com.afab.customers.dto.CustomerSummaryDTO.TopCustomerItem;
import com.afab.customers.repository.CustomerRepository;
import com.afab.customers.service.CustomerFinancialMetricsProvider.CustomerMetrics;
import com.afab.ai.rag.AiEntityChangedEvent;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class CustomerService {

    private static final List<String> AVATAR_COLORS = List.of(
            "bg-purple-500/15 text-[#7c3aed] dark:text-[#a78bfa] border-purple-500/25",
            "bg-amber-500/15 text-amber-600 dark:text-amber-400 border-amber-500/25",
            "bg-sky-500/15 text-sky-600 dark:text-sky-400 border-sky-500/25",
            "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border-emerald-500/25",
            "bg-pink-500/15 text-pink-600 dark:text-pink-400 border-pink-500/25",
            "bg-indigo-500/15 text-indigo-600 dark:text-indigo-400 border-indigo-500/25",
            "bg-teal-500/15 text-teal-600 dark:text-teal-400 border-teal-500/25"
    );

    private final CustomerRepository customerRepository;
    private final CurrentBusinessService currentBusinessService;
    private final AuditService auditService;
    private final CustomerFinancialMetricsProvider metricsProvider;
    private ApplicationEventPublisher eventPublisher;

    @Autowired(required = false)
    public void setEventPublisher(ApplicationEventPublisher eventPublisher) {
        this.eventPublisher = eventPublisher;
    }

    private void publishRagChange(UUID businessId, UUID customerId, boolean deleted) {
        if (eventPublisher != null && businessId != null && customerId != null) {
            eventPublisher.publishEvent(new AiEntityChangedEvent(businessId, "CUSTOMER", customerId, deleted));
        }
    }

    public CustomerService(
            CustomerRepository customerRepository,
            CurrentBusinessService currentBusinessService,
            AuditService auditService,
            @Autowired(required = false) CustomerFinancialMetricsProvider metricsProvider
    ) {
        this.customerRepository = customerRepository;
        this.currentBusinessService = currentBusinessService;
        this.auditService = auditService;
        this.metricsProvider = metricsProvider;
    }

    @Transactional(readOnly = true)
    public CustomerPageDTO listCustomers(
            String userEmail,
            String search,
            String status,
            String group,
            int page,
            int size,
            String sortBy,
            String sortOrder
    ) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        int safePage = Math.max(0, page);
        int safeSize = Math.min(100, Math.max(1, size));

        Sort.Direction direction = "asc".equalsIgnoreCase(sortOrder) ? Sort.Direction.ASC : Sort.Direction.DESC;
        String sortField = mapSortField(sortBy);

        String cleanStatus = (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) ? status.trim() : null;
        String cleanGroup = (group != null && !group.isBlank() && !"ALL".equalsIgnoreCase(group)) ? group.trim() : null;
        String cleanSearch = (search != null && !search.isBlank()) ? search.trim() : null;

        Page<Customer> pageRes = customerRepository.searchCustomers(
                business.getId(),
                cleanStatus,
                cleanGroup,
                cleanSearch,
                PageRequest.of(safePage, safeSize, Sort.by(direction, sortField))
        );

        Map<UUID, CustomerMetrics> metricsMap = metricsProvider != null
                ? metricsProvider.getMetricsForBusiness(business.getId())
                : Map.of();

        List<CustomerDTO> content = pageRes.getContent().stream()
                .map(c -> toDTO(c, metricsMap.getOrDefault(c.getId(), CustomerMetrics.empty()), false))
                .toList();

        return new CustomerPageDTO(
                content,
                pageRes.getTotalElements(),
                Math.max(1, pageRes.getTotalPages()),
                pageRes.getNumber(),
                pageRes.getSize()
        );
    }

    @Transactional(readOnly = true)
    public CustomerDTO getCustomerById(String userEmail, UUID customerId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Customer customer = customerRepository.findActiveById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with ID: " + customerId));

        if (!customer.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this customer.");
        }

        CustomerMetrics metrics = metricsProvider != null
                ? metricsProvider.getMetricsForCustomer(business.getId(), customer.getId())
                : CustomerMetrics.empty();

        return toDTO(customer, metrics, true);
    }

    @Transactional(readOnly = true)
    public CustomerSummaryDTO getSummary(String userEmail, String period) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD";

        List<Customer> customers = customerRepository.findAllActiveByBusinessId(business.getId());
        Map<UUID, CustomerMetrics> metricsMap = metricsProvider != null
                ? metricsProvider.getMetricsForBusiness(business.getId())
                : Map.of();

        long totalCustomers = customers.size();
        long activeCount = customers.stream().filter(c -> "Active".equalsIgnoreCase(c.getStatus())).count();
        long inactiveCount = customers.stream().filter(c -> "Inactive".equalsIgnoreCase(c.getStatus())).count();
        long newStatusCount = customers.stream()
                .filter(c -> "New".equalsIgnoreCase(c.getStatus()) || "Lead".equalsIgnoreCase(c.getStatus()))
                .count();

        long windowDays = resolveWindowDays(period);
        Instant now = Instant.now();
        Instant currentStart = now.minus(windowDays, ChronoUnit.DAYS);
        Instant prevStart = now.minus(windowDays * 2, ChronoUnit.DAYS);

        long currentNew = customers.stream()
                .filter(c -> c.getCreatedAt() != null && !c.getCreatedAt().isBefore(currentStart))
                .count();
        long prevNew = customers.stream()
                .filter(c -> c.getCreatedAt() != null && !c.getCreatedAt().isBefore(prevStart) && c.getCreatedAt().isBefore(currentStart))
                .count();

        BigDecimal totalRevenue = BigDecimal.ZERO;
        long repeatCustomers = 0;
        List<TopCustomerItem> ranked = new ArrayList<>();
        List<CustomerActivityItem> activity = new ArrayList<>();

        for (Customer c : customers) {
            CustomerMetrics m = metricsMap.getOrDefault(c.getId(), CustomerMetrics.empty());
            totalRevenue = totalRevenue.add(m.totalPaidRevenue());
            if (m.invoiceCount() > 1) {
                repeatCustomers++;
            }
            ranked.add(new TopCustomerItem(
                    c.getId(),
                    c.getCustomerCode(),
                    c.getName(),
                    c.getEmail() != null ? c.getEmail() : "",
                    m.totalPaidRevenue(),
                    m.invoiceCount(),
                    pickAvatarColor(c.getName())
            ));

            if (c.getCreatedAt() != null) {
                activity.add(new CustomerActivityItem(
                        "cust-" + c.getId(),
                        c.getId(),
                        c.getName(),
                        "NEW_CUSTOMER",
                        "Customer " + c.getCustomerCode() + " registered",
                        null,
                        c.getCreatedAt().toString()
                ));
            }
            for (var inv : m.invoices()) {
                activity.add(new CustomerActivityItem(
                        "inv-" + inv.id(),
                        c.getId(),
                        c.getName(),
                        "PAID".equalsIgnoreCase(inv.status()) ? "INVOICE_PAID" : "NEW_ORDER",
                        inv.invoiceNumber() + " — " + inv.description(),
                        inv.amount(),
                        inv.createdAt() != null ? inv.createdAt().toString() : Instant.now().toString()
                ));
            }
        }

        BigDecimal avgRevenue = totalCustomers > 0
                ? totalRevenue.divide(BigDecimal.valueOf(totalCustomers), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;
        double repeatPct = totalCustomers > 0
                ? Math.round((repeatCustomers * 1000.0) / totalCustomers) / 10.0 : 0.0;

        double activePct = totalCustomers > 0 ? Math.round((activeCount * 100.0) / totalCustomers) : 0.0;
        double inactivePct = totalCustomers > 0 ? Math.round((inactiveCount * 100.0) / totalCustomers) : 0.0;
        double newPct = totalCustomers > 0 ? Math.max(0.0, 100.0 - activePct - inactivePct) : 0.0;

        ranked.sort((a, b) -> b.revenue().compareTo(a.revenue()));
        activity.sort((a, b) -> b.timestamp().compareTo(a.timestamp()));

        double newDelta = computePctDelta(currentNew, prevNew);

        return new CustomerSummaryDTO(
                totalCustomers,
                newDelta,
                currentNew,
                newDelta,
                totalRevenue,
                0.0,
                avgRevenue,
                0.0,
                repeatPct,
                0.0,
                currency,
                new OverviewDonut(activeCount, activePct, inactiveCount, inactivePct, newStatusCount, newPct),
                ranked.stream().limit(5).toList(),
                activity.stream().limit(6).toList()
        );
    }

    @Transactional
    public CustomerDTO createCustomer(String userEmail, CreateCustomerRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        String cleanEmail = (request.getEmail() != null && !request.getEmail().isBlank())
                ? request.getEmail().trim().toLowerCase(Locale.ROOT) : null;
        if (cleanEmail != null && customerRepository.existsActiveByBusinessIdAndEmailIgnoreCase(business.getId(), cleanEmail)) {
            throw new ConflictException("A customer with email '" + cleanEmail + "' already exists in this business.");
        }

        String code = (request.getCustomerCode() != null && !request.getCustomerCode().isBlank())
                ? request.getCustomerCode().trim().toUpperCase(Locale.ROOT)
                : generateNextCustomerCode(business.getId());

        if (customerRepository.existsByBusinessIdAndCustomerCodeIgnoreCase(business.getId(), code)) {
            throw new ConflictException("Customer code '" + code + "' is already in use in this business.");
        }

        Customer customer = new Customer();
        customer.setBusiness(business);
        customer.setCustomerCode(code);
        customer.setName(request.getName().trim());
        customer.setCompanyName(trimOrNull(request.getCompanyName()));
        customer.setEmail(cleanEmail);
        customer.setPhone(trimOrNull(request.getPhone()));
        customer.setCustomerGroup(request.getGroup() != null && !request.getGroup().isBlank() ? request.getGroup().trim() : "Standard");
        customer.setStatus(request.getStatus() != null && !request.getStatus().isBlank() ? request.getStatus().trim() : "Active");
        customer.setAddress(trimOrNull(request.getAddress()));
        customer.setNotes(trimOrNull(request.getNotes()));

        customer = customerRepository.save(customer);
        auditService.log(user, "CREATE", "Customer", customer.getId(), "{\"customerCode\":\"" + code + "\"}");
        publishRagChange(business.getId(), customer.getId(), false);

        return toDTO(customer, CustomerMetrics.empty(), true);
    }

    @Transactional
    public CustomerDTO updateCustomer(String userEmail, UUID customerId, UpdateCustomerRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        Customer customer = customerRepository.findActiveById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with ID: " + customerId));

        if (!customer.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this customer.");
        }

        if (request.getName() != null && !request.getName().isBlank()) {
            customer.setName(request.getName().trim());
        }
        if (request.getCompanyName() != null) {
            customer.setCompanyName(trimOrNull(request.getCompanyName()));
        }
        if (request.getEmail() != null) {
            String cleanEmail = trimOrNull(request.getEmail());
            if (cleanEmail != null) {
                cleanEmail = cleanEmail.toLowerCase(Locale.ROOT);
                if (customerRepository.existsActiveByBusinessIdAndEmailIgnoreCaseAndIdNot(business.getId(), cleanEmail, customer.getId())) {
                    throw new ConflictException("A customer with email '" + cleanEmail + "' already exists in this business.");
                }
            }
            customer.setEmail(cleanEmail);
        }
        if (request.getCustomerCode() != null && !request.getCustomerCode().isBlank()) {
            String cleanCode = request.getCustomerCode().trim().toUpperCase(Locale.ROOT);
            if (customerRepository.existsByBusinessIdAndCustomerCodeIgnoreCaseAndIdNot(business.getId(), cleanCode, customer.getId())) {
                throw new ConflictException("Customer code '" + cleanCode + "' is already in use in this business.");
            }
            customer.setCustomerCode(cleanCode);
        }
        if (request.getPhone() != null) {
            customer.setPhone(trimOrNull(request.getPhone()));
        }
        if (request.getGroup() != null && !request.getGroup().isBlank()) {
            customer.setCustomerGroup(request.getGroup().trim());
        }
        if (request.getStatus() != null && !request.getStatus().isBlank()) {
            customer.setStatus(request.getStatus().trim());
        }
        if (request.getAddress() != null) {
            customer.setAddress(trimOrNull(request.getAddress()));
        }
        if (request.getNotes() != null) {
            customer.setNotes(trimOrNull(request.getNotes()));
        }

        customer = customerRepository.save(customer);
        auditService.log(user, "UPDATE", "Customer", customer.getId(), null);
        publishRagChange(business.getId(), customer.getId(), false);

        CustomerMetrics metrics = metricsProvider != null
                ? metricsProvider.getMetricsForCustomer(business.getId(), customer.getId())
                : CustomerMetrics.empty();
        return toDTO(customer, metrics, true);
    }

    /**
     * Soft-archives a customer so historical invoices and payment audit trails remain intact.
     */
    @Transactional
    public void archiveCustomer(String userEmail, UUID customerId) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        Customer customer = customerRepository.findActiveById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with ID: " + customerId));

        if (!customer.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this customer.");
        }

        customer.setArchivedAt(Instant.now());
        customer.setStatus("Archived");
        customerRepository.save(customer);

        auditService.log(user, "ARCHIVE", "Customer", customer.getId(), null);
        publishRagChange(business.getId(), customer.getId(), true);
    }

    private String generateNextCustomerCode(UUID businessId) {
        long seq = customerRepository.countAllByBusinessId(businessId) + 1;
        String candidate = String.format("CST-%04d", 1000 + seq);
        int attempts = 0;
        while (customerRepository.existsByBusinessIdAndCustomerCodeIgnoreCase(businessId, candidate) && attempts < 20) {
            seq++;
            candidate = String.format("CST-%04d", 1000 + seq);
            attempts++;
        }
        if (customerRepository.existsByBusinessIdAndCustomerCodeIgnoreCase(businessId, candidate)) {
            candidate = "CST-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase(Locale.ROOT);
        }
        return candidate;
    }

    private CustomerDTO toDTO(Customer c, CustomerMetrics m, boolean includeOrders) {
        Instant lastActivity = m.lastInvoiceActivityAt() != null
                ? m.lastInvoiceActivityAt()
                : (c.getUpdatedAt() != null ? c.getUpdatedAt() : c.getCreatedAt());
        String lastActivityDate = lastActivity != null
                ? lastActivity.atZone(ZoneOffset.UTC).toLocalDate().toString()
                : "";

        return new CustomerDTO(
                c.getId(),
                c.getCustomerCode(),
                c.getBusiness().getId(),
                c.getName(),
                c.getCompanyName(),
                c.getEmail() != null ? c.getEmail() : "",
                c.getPhone(),
                c.getCustomerGroup(),
                c.getStatus(),
                m.totalPaidRevenue(),
                m.totalInvoicedAmount(),
                m.outstandingBalance(),
                m.invoiceCount(),
                lastActivityDate,
                c.getAddress(),
                c.getNotes(),
                c.getCreatedAt(),
                c.getUpdatedAt(),
                includeOrders ? m.invoices() : List.of()
        );
    }

    private String mapSortField(String sortBy) {
        if (sortBy == null || sortBy.isBlank()) return "createdAt";
        return switch (sortBy) {
            case "name" -> "name";
            case "email" -> "email";
            case "status" -> "status";
            case "customerCode" -> "customerCode";
            case "group", "customerGroup" -> "customerGroup";
            case "updatedAt", "lastActivityDate" -> "updatedAt";
            default -> "createdAt";
        };
    }

    private long resolveWindowDays(String period) {
        if (period == null) return 30;
        return switch (period.toLowerCase(Locale.ROOT)) {
            case "week", "weekly" -> 7;
            case "quarter" -> 90;
            case "year", "yearly" -> 365;
            default -> 30;
        };
    }

    private double computePctDelta(long current, long previous) {
        if (previous == 0) return current > 0 ? 100.0 : 0.0;
        return Math.round(((current - previous) * 1000.0) / Math.abs(previous)) / 10.0;
    }

    private String pickAvatarColor(String name) {
        if (name == null || name.isEmpty()) return AVATAR_COLORS.get(0);
        return AVATAR_COLORS.get(Math.abs(name.hashCode()) % AVATAR_COLORS.size());
    }

    private String trimOrNull(String val) {
        if (val == null) return null;
        String trimmed = val.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
