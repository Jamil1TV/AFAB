package com.afab.notification;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findTop30ByUserIdOrderByCreatedAtDesc(UUID userId);
    long countByUserIdAndReadAtIsNull(UUID userId);
    Optional<Notification> findByIdAndUserId(UUID id, UUID userId);

    @Modifying
    @Query("UPDATE Notification n SET n.readAt = :readAt WHERE n.user.id = :userId AND n.readAt IS NULL")
    int markAllReadByUserId(@Param("userId") UUID userId, @Param("readAt") Instant readAt);
}
