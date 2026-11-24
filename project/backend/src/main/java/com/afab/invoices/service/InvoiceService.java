package com.afab.invoices.service;

import com.afab.business.Business;
import com.afab.business.BusinessAccessGuard;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.common.exception.ResourceNotFoundException;
import com.afab.customers.domain.Customer;
import com.afab.customers.repository.CustomerRepository;
import com.afab.finance.domain.Transaction;
import com.afab.finance.dto.InvoiceSummaryDTO;
import com.afab.finance.repository.TransactionRepository;
import com.afab.finance.service.TransactionService;
import com.afab.invoices.domain.*;
import com.afab.invoices.dto.*;
import com.afab.invoices.dto.InvoiceDTO.InvoiceItemDTO;
import com.afab.invoices.dto.InvoiceDTO.PaymentDTO;
import com.afab.invoices.repository.InvoiceRepository;
import com.afab.invoices.repository.PaymentRepository;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

/**
 * Real Invoice Lifecycle & Atomic Payment Allocation Service.
 *
 * Critical Accounting Rules (P1.3):
 * 1. Invoices are strictly separate from Income Transactions.
 * 2. Creating or issuing an unpaid Invoice NEVER creates an Income Transaction.
 * 3. Only actual received Payments create a corresponding Income Transaction (1:1 DB constraint),
 *    using the immutable P1.1 FX snapshot rules.
 * 4. Payment recording is atomic (@Transactional) and idempotent per (business, invoice, idempotencyKey).
 * 5. OVERDUE is calculated dynamically from dueDate & outstandingBalance rather than stale state.
 */
@Service
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final PaymentRepository paymentRepository;
    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;
    private final TransactionService transactionService;
    private final InvoiceNumberGenerator invoiceNumberGenerator;
    private final CurrentBusinessService currentBusinessService;
    private final AuditService auditService;

    public InvoiceService(
            InvoiceRepository invoiceRepository,
            PaymentRepository paymentRepository,
            CustomerRepository customerRepository,
            TransactionRepository transactionRepository,
            TransactionService transactionService,
            InvoiceNumberGenerator invoiceNumberGenerator,
            CurrentBusinessService currentBusinessService,
            AuditService auditService
    ) {
        this.invoiceRepository = invoiceRepository;
        this.paymentRepository = paymentRepository;
        this.customerRepository = customerRepository;
        this.transactionRepository = transactionRepository;
        this.transactionService = transactionService;
        this.invoiceNumberGenerator = invoiceNumberGenerator;
        this.currentBusinessService = currentBusinessService;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public InvoicePageDTO listInvoices(
            String userEmail,
            UUID customerId,
            String statusFilter,
            String search,
            int page,
            int size
    ) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        int safePage = Math.max(0, page);
        int safeSize = Math.min(100, Math.max(1, size));
        LocalDate today = LocalDate.now();

        boolean filteringOverdue = "OVERDUE".equalsIgnoreCase(statusFilter);
        InvoiceStatus storedStatusFilter = null;
        if (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter) && !filteringOverdue) {
            try {
                storedStatusFilter = InvoiceStatus.valueOf(statusFilter.toUpperCase(Locale.ROOT).trim());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Invalid invoice status filter: " + statusFilter);
            }
        }

        String cleanSearch = (search != null && !search.isBlank()) ? search.trim() : null;
        List<Invoice> allForSummary = invoiceRepository.findAllByBusinessIdWithCustomer(business.getId());

        BigDecimal totalInvoiced = BigDecimal.ZERO;
        BigDecimal totalPaid = BigDecimal.ZERO;
        BigDecimal totalOutstanding = BigDecimal.ZERO;
        for (Invoice inv : allForSummary) {
            if (inv.getStatus() == InvoiceStatus.CANCELLED || inv.getStatus() == InvoiceStatus.DRAFT) {
                continue;
            }
            totalInvoiced = totalInvoiced.add(inv.getTotalAmount());
            totalPaid = totalPaid.add(inv.getPaidAmount());
            totalOutstanding = totalOutstanding.add(inv.getOutstandingBalance());
        }

        List<InvoiceDTO> content;
        long totalElements;
        int totalPages;

        if (filteringOverdue) {
            List<Invoice> overdueList = allForSummary.stream()
                    .filter(inv -> inv.computeEffectiveStatus(today) == InvoiceStatus.OVERDUE)
                    .filter(inv -> customerId == null || (inv.getCustomer() != null && customerId.equals(inv.getCustomer().getId())))
                    .filter(inv -> cleanSearch == null
                            || inv.getInvoiceNumber().toLowerCase(Locale.ROOT).contains(cleanSearch.toLowerCase(Locale.ROOT))
                            || (inv.getCustomer() != null && inv.getCustomer().getName().toLowerCase(Locale.ROOT).contains(cleanSearch.toLowerCase(Locale.ROOT))))
                    .toList();
            totalElements = overdueList.size();
            totalPages = Math.max(1, (int) Math.ceil((double) totalElements / safeSize));
            int fromIdx = Math.min(safePage * safeSize, overdueList.size());
            int toIdx = Math.min(fromIdx + safeSize, overdueList.size());
            content = overdueList.subList(fromIdx, toIdx).stream()
                    .map(inv -> toDTO(inv, List.of(), today))
                    .toList();
        } else {
            Page<Invoice> pageRes = invoiceRepository.searchInvoices(
                    business.getId(),
                    customerId,
                    storedStatusFilter,
                    cleanSearch,
                    PageRequest.of(safePage, safeSize)
            );
            totalElements = pageRes.getTotalElements();
            totalPages = Math.max(1, pageRes.getTotalPages());
            content = pageRes.getContent().stream()
                    .map(inv -> toDTO(inv, List.of(), today))
                    .toList();
        }

        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD";
        return new InvoicePageDTO(
                content,
                safePage,
                safeSize,
                totalElements,
                totalPages,
                totalInvoiced,
                totalPaid,
                totalOutstanding,
                currency
        );
    }

    @Transactional(readOnly = true)
    public InvoiceDTO getInvoiceById(String userEmail, UUID invoiceId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Invoice invoice = invoiceRepository.findWithDetailsById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }

        List<Payment> payments = paymentRepository.findByBusinessIdAndInvoiceId(business.getId(), invoice.getId());
        return toDTO(invoice, payments, LocalDate.now());
    }

    @Transactional(readOnly = true)
    public InvoiceSummaryDTO getSummary(String userEmail, String period) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        String currency = (business.getCurrency() != null && !business.getCurrency().isBlank()) ? business.getCurrency() : "USD";
        LocalDate today = LocalDate.now();

        List<Invoice> invoices = invoiceRepository.findAllByBusinessIdWithCustomer(business.getId());

        long totalInvoices = 0;
        long paidCount = 0;
        long pendingCount = 0;
        long overdueCount = 0;

        BigDecimal totalInvoiceAmount = BigDecimal.ZERO;
        BigDecimal paidAmount = BigDecimal.ZERO;
        BigDecimal pendingAmount = BigDecimal.ZERO;
        BigDecimal overdueAmount = BigDecimal.ZERO;

        List<InvoiceSummaryDTO.UpcomingInvoiceItem> upcoming = new ArrayList<>();

        for (Invoice inv : invoices) {
            if (inv.getStatus() == InvoiceStatus.CANCELLED) {
                continue;
            }
            totalInvoices++;
            totalInvoiceAmount = totalInvoiceAmount.add(inv.getTotalAmount());
            InvoiceStatus eff = inv.computeEffectiveStatus(today);

            if (eff == InvoiceStatus.PAID) {
                paidCount++;
                paidAmount = paidAmount.add(inv.getPaidAmount());
            } else if (eff == InvoiceStatus.OVERDUE) {
                overdueCount++;
                paidAmount = paidAmount.add(inv.getPaidAmount());
                overdueAmount = overdueAmount.add(inv.getOutstandingBalance());
                upcoming.add(new InvoiceSummaryDTO.UpcomingInvoiceItem(
                        inv.getInvoiceNumber(),
                        inv.getCustomer() != null ? inv.getCustomer().getName() : "Walk-in Customer",
                        inv.getCustomer() != null && inv.getCustomer().getEmail() != null ? inv.getCustomer().getEmail() : "",
                        inv.getDueDate().toString(),
                        inv.getOutstandingBalance()
                ));
            } else {
                pendingCount++;
                paidAmount = paidAmount.add(inv.getPaidAmount());
                pendingAmount = pendingAmount.add(inv.getOutstandingBalance());
                if (inv.getStatus() != InvoiceStatus.DRAFT && inv.getOutstandingBalance().compareTo(BigDecimal.ZERO) > 0) {
                    upcoming.add(new InvoiceSummaryDTO.UpcomingInvoiceItem(
                            inv.getInvoiceNumber(),
                            inv.getCustomer() != null ? inv.getCustomer().getName() : "Walk-in Customer",
                            inv.getCustomer() != null && inv.getCustomer().getEmail() != null ? inv.getCustomer().getEmail() : "",
                            inv.getDueDate().toString(),
                            inv.getOutstandingBalance()
                    ));
                }
            }
        }

        BigDecimal breakdownDenom = paidAmount.add(pendingAmount).add(overdueAmount);
        double paidPct = calcPct(paidAmount, breakdownDenom);
        double pendingPct = calcPct(pendingAmount, breakdownDenom);
        double overduePct = calcPct(overdueAmount, breakdownDenom);

        List<InvoiceSummaryDTO.StatusBreakdownItem> breakdown = List.of(
                new InvoiceSummaryDTO.StatusBreakdownItem("Paid", paidAmount, paidPct, "#4edea3"),
                new InvoiceSummaryDTO.StatusBreakdownItem("Pending", pendingAmount, pendingPct, "#ffb95f"),
                new InvoiceSummaryDTO.StatusBreakdownItem("Overdue", overdueAmount, overduePct, "#ffb4ab")
        );

        upcoming.sort(Comparator.comparing(InvoiceSummaryDTO.UpcomingInvoiceItem::getDueDate));

        return new InvoiceSummaryDTO(
                totalInvoices,
                paidCount,
                pendingCount,
                overdueCount,
                totalInvoiceAmount,
                paidAmount,
                pendingAmount,
                overdueAmount,
                currency,
                breakdown,
                upcoming.stream().limit(5).toList()
        );
    }

    /**
     * Creates a new DRAFT invoice with concurrency-safe sequential invoice numbering.
     * NEVER creates an Income Transaction.
     */
    @Transactional
    public InvoiceDTO createInvoice(String userEmail, CreateInvoiceRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        validateDates(request.getIssueDate(), request.getDueDate());
        Customer customer = resolveAndValidateCustomer(business, request.getCustomerId());

        String invoiceCurrency = (request.getCurrency() != null && !request.getCurrency().isBlank())
                ? request.getCurrency().toUpperCase(Locale.ROOT).trim()
                : (business.getCurrency() != null && !business.getCurrency().isBlank() ? business.getCurrency() : "USD");

        String invoiceNumber = invoiceNumberGenerator.nextInvoiceNumber(business.getId(), request.getIssueDate().getYear());

        Invoice invoice = new Invoice();
        invoice.setBusiness(business);
        invoice.setCustomer(customer);
        invoice.setInvoiceNumber(invoiceNumber);
        invoice.setStatus(InvoiceStatus.DRAFT);
        invoice.setIssueDate(request.getIssueDate());
        invoice.setDueDate(request.getDueDate());
        invoice.setCurrency(invoiceCurrency);
        invoice.setNotes(request.getNotes() != null ? request.getNotes().trim() : null);

        applyItemsAndTotals(invoice, request.getItems(), request.getDiscountAmount());

        invoice = invoiceRepository.save(invoice);
        auditService.log(user, "CREATE", "Invoice", invoice.getId(), "{\"invoiceNumber\":\"" + invoiceNumber + "\"}");

        return toDTO(invoice, List.of(), LocalDate.now());
    }

    /**
     * Edits a DRAFT invoice. Issued, paid, or cancelled invoices cannot be mutated.
     */
    @Transactional
    public InvoiceDTO updateDraftInvoice(String userEmail, UUID invoiceId, CreateInvoiceRequest request) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        Invoice invoice = invoiceRepository.findWithDetailsById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }
        if (invoice.getStatus() != InvoiceStatus.DRAFT) {
            throw new ConflictException("Only DRAFT invoices can be edited. Current status: " + invoice.getStatus());
        }

        validateDates(request.getIssueDate(), request.getDueDate());
        Customer customer = resolveAndValidateCustomer(business, request.getCustomerId());

        invoice.setCustomer(customer);
        invoice.setIssueDate(request.getIssueDate());
        invoice.setDueDate(request.getDueDate());
        if (request.getCurrency() != null && !request.getCurrency().isBlank()) {
            invoice.setCurrency(request.getCurrency().toUpperCase(Locale.ROOT).trim());
        }
        invoice.setNotes(request.getNotes() != null ? request.getNotes().trim() : null);

        invoice.getItems().clear();
        applyItemsAndTotals(invoice, request.getItems(), request.getDiscountAmount());

        invoice = invoiceRepository.save(invoice);
        auditService.log(user, "UPDATE", "Invoice", invoice.getId(), null);

        return toDTO(invoice, List.of(), LocalDate.now());
    }

    /**
     * Issues/Sends a DRAFT invoice (DRAFT -> UNPAID or SENT).
     * Critical accounting rule: Issuing an unpaid invoice NEVER creates an Income Transaction.
     */
    @Transactional
    public InvoiceDTO issueInvoice(String userEmail, UUID invoiceId, boolean markAsSent) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        Invoice invoice = invoiceRepository.findWithDetailsById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }
        if (invoice.getStatus() != InvoiceStatus.DRAFT) {
            throw new ConflictException("Invalid transition: Only DRAFT invoices can be issued. Current status: " + invoice.getStatus());
        }
        if (invoice.getTotalAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Cannot issue an invoice with a zero total amount.");
        }

        invoice.setStatus(markAsSent ? InvoiceStatus.SENT : InvoiceStatus.UNPAID);
        invoice.setIssuedAt(Instant.now());
        invoice = invoiceRepository.save(invoice);

        auditService.log(user, "ISSUE", "Invoice", invoice.getId(), "{\"status\":\"" + invoice.getStatus() + "\"}");
        return toDTO(invoice, List.of(), LocalDate.now());
    }

    /**
     * Cancels a DRAFT, SENT, or UNPAID invoice that has received zero payments.
     */
    @Transactional
    public InvoiceDTO cancelInvoice(String userEmail, UUID invoiceId) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        Invoice invoice = invoiceRepository.findWithDetailsById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }
        if (invoice.getStatus() == InvoiceStatus.CANCELLED) {
            throw new ConflictException("Invoice is already cancelled.");
        }
        if (invoice.getStatus() == InvoiceStatus.PAID || invoice.getPaidAmount().compareTo(BigDecimal.ZERO) > 0) {
            throw new ConflictException("Cannot cancel an invoice that has recorded payments.");
        }

        invoice.setStatus(InvoiceStatus.CANCELLED);
        invoice.setCancelledAt(Instant.now());
        invoice.setOutstandingBalance(BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP));
        invoice = invoiceRepository.save(invoice);

        auditService.log(user, "CANCEL", "Invoice", invoice.getId(), null);
        return toDTO(invoice, List.of(), LocalDate.now());
    }

    /**
     * Atomically and idempotently records a full or partial payment against an issued invoice.
     * Creates exactly ONE Income Transaction (with immutable FX snapshot) per Payment,
     * allocates the payment, and updates the invoice's paid amount, outstanding balance, and status.
     */
    @Transactional
    public PaymentDTO recordPayment(
            String userEmail,
            UUID invoiceId,
            RecordPaymentRequest request,
            String headerIdempotencyKey
    ) {
        User user = currentBusinessService.getCurrentUser(userEmail);
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        BusinessAccessGuard.assertEditable(business);

        String idempotencyKey = (headerIdempotencyKey != null && !headerIdempotencyKey.isBlank())
                ? headerIdempotencyKey.trim()
                : (request.getIdempotencyKey() != null && !request.getIdempotencyKey().isBlank()
                        ? request.getIdempotencyKey().trim()
                        : null);

        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new IllegalArgumentException("Idempotency-Key header or idempotencyKey field is required to record a payment safely.");
        }

        // 1. Idempotency replay check — never duplicate a payment or income transaction
        Optional<Payment> existingPayment = paymentRepository.findByBusinessIdAndInvoiceIdAndIdempotencyKey(
                business.getId(), invoiceId, idempotencyKey
        );
        if (existingPayment.isPresent()) {
            return toPaymentDTO(existingPayment.get());
        }

        // 2. Lock and validate invoice & tenant ownership
        Invoice invoice = invoiceRepository.findByIdForUpdate(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }

        if (invoice.getStatus() == InvoiceStatus.DRAFT) {
            throw new ConflictException("Cannot record payment on a DRAFT invoice. Issue the invoice first.");
        }
        if (invoice.getStatus() == InvoiceStatus.CANCELLED) {
            throw new ConflictException("Cannot record payment on a CANCELLED invoice.");
        }
        if (invoice.getStatus() == InvoiceStatus.PAID || invoice.getOutstandingBalance().compareTo(BigDecimal.ZERO) <= 0) {
            throw new ConflictException("Invoice is already fully paid.");
        }

        // 3. Validate payment currency & remaining balance (prevent overpayment)
        String paymentCurrency = (request.getCurrency() != null && !request.getCurrency().isBlank())
                ? request.getCurrency().toUpperCase(Locale.ROOT).trim()
                : invoice.getCurrency();
        if (!paymentCurrency.equalsIgnoreCase(invoice.getCurrency())) {
            throw new IllegalArgumentException(
                    "Payment currency (" + paymentCurrency + ") must match invoice currency (" + invoice.getCurrency() + ").");
        }

        BigDecimal paymentAmount = request.getAmount().setScale(4, RoundingMode.HALF_UP);
        if (paymentAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Payment amount must be greater than zero.");
        }
        if (paymentAmount.compareTo(invoice.getOutstandingBalance()) > 0) {
            throw new IllegalArgumentException(
                    "Payment amount (" + paymentAmount + ") exceeds remaining invoice balance (" + invoice.getOutstandingBalance() + "). Overpayment is not allowed.");
        }

        // 4. Create the corresponding Income Transaction with immutable P1.1 FX snapshot
        String method = request.getPaymentMethod() != null ? request.getPaymentMethod().toUpperCase(Locale.ROOT).trim() : "BANK_TRANSFER";
        if ("CREDIT_CARD".equals(method)) method = "CARD";

        String customerLabel = invoice.getCustomer() != null ? invoice.getCustomer().getName() : "Customer";
        Transaction incomeTx = new Transaction();
        incomeTx.setBusiness(business);
        incomeTx.setType("INCOME");
        transactionService.applyFxSnapshot(incomeTx, business, paymentAmount, paymentCurrency, request.getExchangeRate());
        incomeTx.setDescription("Payment for " + invoice.getInvoiceNumber() + " — " + customerLabel);
        incomeTx.setTransactionDate(request.getPaymentDate());
        incomeTx.setPaymentMethod(method);
        incomeTx.setStatus("COMPLETED");
        incomeTx.setNotes(request.getReference() != null && !request.getReference().isBlank()
                ? "Invoice: " + invoice.getInvoiceNumber() + " | Ref: " + request.getReference().trim()
                : "Invoice: " + invoice.getInvoiceNumber());
        incomeTx = transactionRepository.save(incomeTx);

        // 5. Record Payment linked 1:1 to Income Transaction
        Payment payment = new Payment();
        payment.setBusiness(business);
        payment.setInvoice(invoice);
        payment.setIncomeTransaction(incomeTx);
        payment.setIdempotencyKey(idempotencyKey);
        payment.setAmount(paymentAmount);
        payment.setCurrency(paymentCurrency);
        payment.setPaymentDate(request.getPaymentDate());
        payment.setPaymentMethod(method);
        payment.setReference(request.getReference() != null ? request.getReference().trim() : null);
        payment.setNotes(request.getNotes() != null ? request.getNotes().trim() : null);
        payment = paymentRepository.save(payment);

        // 6. Allocate payment and update Invoice totals & lifecycle state
        BigDecimal newPaid = invoice.getPaidAmount().add(paymentAmount).setScale(4, RoundingMode.HALF_UP);
        BigDecimal newOutstanding = invoice.getTotalAmount().subtract(newPaid).setScale(4, RoundingMode.HALF_UP);
        if (newOutstanding.compareTo(BigDecimal.ZERO) < 0) {
            newOutstanding = BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP);
        }

        invoice.setPaidAmount(newPaid);
        invoice.setOutstandingBalance(newOutstanding);
        invoice.setStatus(newOutstanding.compareTo(BigDecimal.ZERO) == 0 ? InvoiceStatus.PAID : InvoiceStatus.PARTIALLY_PAID);
        invoiceRepository.save(invoice);

        auditService.log(
                user,
                "PAYMENT_RECORDED",
                "Invoice",
                invoice.getId(),
                "{\"paymentId\":\"" + payment.getId() + "\",\"transactionId\":\"" + incomeTx.getId() + "\",\"amount\":" + paymentAmount.toPlainString() + "}"
        );

        return toPaymentDTO(payment);
    }

    @Transactional(readOnly = true)
    public List<PaymentDTO> listInvoicePayments(String userEmail, UUID invoiceId) {
        Business business = currentBusinessService.getCurrentBusiness(userEmail);
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID: " + invoiceId));

        if (!invoice.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: You do not have access to this invoice.");
        }

        return paymentRepository.findByBusinessIdAndInvoiceId(business.getId(), invoice.getId())
                .stream()
                .map(this::toPaymentDTO)
                .toList();
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private void validateDates(LocalDate issueDate, LocalDate dueDate) {
        if (dueDate.isBefore(issueDate)) {
            throw new IllegalArgumentException("Due date cannot be earlier than issue date.");
        }
    }

    private Customer resolveAndValidateCustomer(Business business, UUID customerId) {
        if (customerId == null) {
            return null;
        }
        Customer customer = customerRepository.findActiveById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Customer not found with ID: " + customerId));
        if (!customer.getBusiness().getId().equals(business.getId())) {
            throw new ForbiddenException("Unauthorized: Customer belongs to another business.");
        }
        return customer;
    }

    private void applyItemsAndTotals(
            Invoice invoice,
            List<CreateInvoiceRequest.InvoiceItemRequest> itemReqs,
            BigDecimal discountAmount
    ) {
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal taxTotal = BigDecimal.ZERO;
        int order = 0;

        for (CreateInvoiceRequest.InvoiceItemRequest req : itemReqs) {
            BigDecimal qty = req.getQuantity().setScale(4, RoundingMode.HALF_UP);
            BigDecimal unit = req.getUnitPrice().setScale(4, RoundingMode.HALF_UP);
            BigDecimal taxRate = req.getTaxRate().setScale(2, RoundingMode.HALF_UP);

            BigDecimal lineSub = qty.multiply(unit).setScale(4, RoundingMode.HALF_UP);
            BigDecimal lineTax = lineSub.multiply(taxRate)
                    .divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
            BigDecimal lineTotal = lineSub.add(lineTax).setScale(4, RoundingMode.HALF_UP);

            InvoiceItem item = new InvoiceItem();
            item.setInvoice(invoice);
            item.setDescription(req.getDescription().trim());
            item.setQuantity(qty);
            item.setUnitPrice(unit);
            item.setTaxRate(taxRate);
            item.setLineSubtotal(lineSub);
            item.setLineTax(lineTax);
            item.setLineTotal(lineTotal);
            item.setSortOrder(order++);
            invoice.getItems().add(item);

            subtotal = subtotal.add(lineSub);
            taxTotal = taxTotal.add(lineTax);
        }

        BigDecimal discount = discountAmount != null ? discountAmount.setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP);
        if (discount.compareTo(subtotal.add(taxTotal)) > 0) {
            throw new IllegalArgumentException("Discount cannot exceed invoice subtotal plus tax.");
        }

        BigDecimal total = subtotal.add(taxTotal).subtract(discount).setScale(4, RoundingMode.HALF_UP);
        invoice.setSubtotal(subtotal.setScale(4, RoundingMode.HALF_UP));
        invoice.setDiscountAmount(discount);
        invoice.setTaxAmount(taxTotal.setScale(4, RoundingMode.HALF_UP));
        invoice.setTotalAmount(total);
        invoice.setPaidAmount(BigDecimal.ZERO.setScale(4, RoundingMode.HALF_UP));
        invoice.setOutstandingBalance(total);
    }

    private InvoiceDTO toDTO(Invoice inv, List<Payment> payments, LocalDate today) {
        InvoiceStatus effectiveStatus = inv.computeEffectiveStatus(today);
        List<InvoiceItemDTO> itemDTOs = inv.getItems() == null ? List.of() : inv.getItems().stream()
                .map(it -> new InvoiceItemDTO(
                        it.getId(),
                        it.getDescription(),
                        it.getQuantity(),
                        it.getUnitPrice(),
                        it.getTaxRate(),
                        it.getLineSubtotal(),
                        it.getLineTax(),
                        it.getLineTotal()
                ))
                .toList();

        List<PaymentDTO> paymentDTOs = payments.stream().map(this::toPaymentDTO).toList();

        return new InvoiceDTO(
                inv.getId(),
                inv.getBusiness().getId(),
                inv.getInvoiceNumber(),
                inv.getCustomer() != null ? inv.getCustomer().getId() : null,
                inv.getCustomer() != null ? inv.getCustomer().getName() : null,
                inv.getCustomer() != null ? inv.getCustomer().getEmail() : null,
                effectiveStatus.name(),
                inv.getStatus().name(),
                effectiveStatus == InvoiceStatus.OVERDUE,
                inv.getIssueDate(),
                inv.getDueDate(),
                inv.getCurrency(),
                inv.getSubtotal(),
                inv.getDiscountAmount(),
                inv.getTaxAmount(),
                inv.getTotalAmount(),
                inv.getPaidAmount(),
                inv.getOutstandingBalance(),
                inv.getNotes(),
                inv.getIssuedAt(),
                inv.getCancelledAt(),
                inv.getCreatedAt(),
                inv.getUpdatedAt(),
                itemDTOs,
                paymentDTOs
        );
    }

    private PaymentDTO toPaymentDTO(Payment p) {
        Transaction tx = p.getIncomeTransaction();
        return new PaymentDTO(
                p.getId(),
                p.getInvoice().getId(),
                tx != null ? tx.getId() : null,
                p.getIdempotencyKey(),
                p.getAmount(),
                p.getCurrency(),
                tx != null ? tx.getConvertedAmount() : p.getAmount(),
                tx != null ? tx.getBaseCurrency() : p.getCurrency(),
                tx != null ? tx.getExchangeRate() : BigDecimal.ONE,
                p.getPaymentDate(),
                p.getPaymentMethod(),
                p.getReference(),
                p.getNotes(),
                p.getCreatedAt()
        );
    }

    private double calcPct(BigDecimal part, BigDecimal total) {
        if (total == null || total.compareTo(BigDecimal.ZERO) <= 0) return 0.0;
        return part.divide(total, 4, RoundingMode.HALF_UP)
                .multiply(new BigDecimal("100"))
                .setScale(1, RoundingMode.HALF_UP)
                .doubleValue();
    }
}
