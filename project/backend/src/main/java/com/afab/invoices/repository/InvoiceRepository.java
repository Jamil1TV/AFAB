package com.afab.invoices.repository;

import com.afab.invoices.domain.Invoice;
import com.afab.invoices.domain.InvoiceStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM Invoice i LEFT JOIN FETCH i.customer WHERE i.id = :id")
    Optional<Invoice> findByIdForUpdate(@Param("id") UUID id);

    @Query("SELECT i FROM Invoice i LEFT JOIN FETCH i.customer LEFT JOIN FETCH i.items WHERE i.id = :id")
    Optional<Invoice> findWithDetailsById(@Param("id") UUID id);

    @Query("SELECT i FROM Invoice i LEFT JOIN i.customer c " +
           "WHERE i.business.id = :businessId " +
           "AND (:customerId IS NULL OR c.id = :customerId) " +
           "AND (:status IS NULL OR i.status = :status) " +
           "AND (:search IS NULL OR LOWER(i.invoiceNumber) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR LOWER(COALESCE(c.name, '')) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR LOWER(COALESCE(i.notes, '')) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%'))) " +
           "ORDER BY i.issueDate DESC, i.createdAt DESC")
    Page<Invoice> searchInvoices(
            @Param("businessId") UUID businessId,
            @Param("customerId") UUID customerId,
            @Param("status") InvoiceStatus status,
            @Param("search") String search,
            Pageable pageable
    );

    @Query("SELECT i FROM Invoice i LEFT JOIN FETCH i.customer WHERE i.business.id = :businessId ORDER BY i.issueDate DESC, i.createdAt DESC")
    List<Invoice> findAllByBusinessIdWithCustomer(@Param("businessId") UUID businessId);

    @Query("SELECT i FROM Invoice i WHERE i.business.id = :businessId AND i.customer.id = :customerId ORDER BY i.issueDate DESC, i.createdAt DESC")
    List<Invoice> findAllByBusinessIdAndCustomerId(@Param("businessId") UUID businessId, @Param("customerId") UUID customerId);
}
