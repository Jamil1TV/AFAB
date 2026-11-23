package com.afab.customers.repository;

import com.afab.customers.domain.Customer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CustomerRepository extends JpaRepository<Customer, UUID> {

    @Query("SELECT c FROM Customer c WHERE c.id = :id AND c.archivedAt IS NULL")
    Optional<Customer> findActiveById(@Param("id") UUID id);

    @Query("SELECT c FROM Customer c WHERE c.business.id = :businessId AND c.archivedAt IS NULL " +
           "AND (:status IS NULL OR LOWER(c.status) = LOWER(CAST(:status AS string))) " +
           "AND (:group IS NULL OR LOWER(c.customerGroup) = LOWER(CAST(:group AS string))) " +
           "AND (:search IS NULL OR LOWER(c.name) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR LOWER(COALESCE(c.companyName, '')) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR LOWER(COALESCE(c.email, '')) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR LOWER(c.customerCode) LIKE LOWER(CONCAT('%', CAST(:search AS string), '%')) " +
           "  OR COALESCE(c.phone, '') LIKE CONCAT('%', CAST(:search AS string), '%'))")
    Page<Customer> searchCustomers(
            @Param("businessId") UUID businessId,
            @Param("status") String status,
            @Param("group") String group,
            @Param("search") String search,
            Pageable pageable
    );

    @Query("SELECT c FROM Customer c WHERE c.business.id = :businessId AND c.archivedAt IS NULL ORDER BY c.createdAt DESC")
    List<Customer> findAllActiveByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT COUNT(c) FROM Customer c WHERE c.business.id = :businessId")
    long countAllByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT COUNT(c) > 0 FROM Customer c WHERE c.business.id = :businessId AND LOWER(c.customerCode) = LOWER(:code)")
    boolean existsByBusinessIdAndCustomerCodeIgnoreCase(@Param("businessId") UUID businessId, @Param("code") String code);

    @Query("SELECT COUNT(c) > 0 FROM Customer c WHERE c.business.id = :businessId AND LOWER(c.customerCode) = LOWER(:code) AND c.id <> :excludeId")
    boolean existsByBusinessIdAndCustomerCodeIgnoreCaseAndIdNot(
            @Param("businessId") UUID businessId,
            @Param("code") String code,
            @Param("excludeId") UUID excludeId
    );

    @Query("SELECT COUNT(c) > 0 FROM Customer c WHERE c.business.id = :businessId AND c.archivedAt IS NULL AND LOWER(c.email) = LOWER(:email)")
    boolean existsActiveByBusinessIdAndEmailIgnoreCase(@Param("businessId") UUID businessId, @Param("email") String email);

    @Query("SELECT COUNT(c) > 0 FROM Customer c WHERE c.business.id = :businessId AND c.archivedAt IS NULL AND LOWER(c.email) = LOWER(:email) AND c.id <> :excludeId")
    boolean existsActiveByBusinessIdAndEmailIgnoreCaseAndIdNot(
            @Param("businessId") UUID businessId,
            @Param("email") String email,
            @Param("excludeId") UUID excludeId
    );
}
