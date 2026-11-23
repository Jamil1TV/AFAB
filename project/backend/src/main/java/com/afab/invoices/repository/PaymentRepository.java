package com.afab.invoices.repository;

import com.afab.invoices.domain.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PaymentRepository extends JpaRepository<Payment, UUID> {

    Optional<Payment> findByBusinessIdAndInvoiceIdAndIdempotencyKey(
            UUID businessId, UUID invoiceId, String idempotencyKey
    );

    @Query("SELECT p FROM Payment p JOIN FETCH p.incomeTransaction WHERE p.business.id = :businessId AND p.invoice.id = :invoiceId ORDER BY p.paymentDate DESC, p.createdAt DESC")
    List<Payment> findByBusinessIdAndInvoiceId(@Param("businessId") UUID businessId, @Param("invoiceId") UUID invoiceId);
}
