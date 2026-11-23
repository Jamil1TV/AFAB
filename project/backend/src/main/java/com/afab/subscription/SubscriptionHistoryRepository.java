package com.afab.subscription;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface SubscriptionHistoryRepository extends JpaRepository<SubscriptionHistory, UUID> {
    List<SubscriptionHistory> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);
}
