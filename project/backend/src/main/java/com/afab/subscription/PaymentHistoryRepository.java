package com.afab.subscription;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PaymentHistoryRepository extends JpaRepository<PaymentHistory, UUID> {
    Optional<PaymentHistory> findByStripeInvoiceId(String stripeInvoiceId);
    List<PaymentHistory> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);
}
