package com.afab.customers;

import com.afab.business.Business;
import com.afab.business.CurrentBusinessService;
import com.afab.common.exception.ConflictException;
import com.afab.common.exception.ForbiddenException;
import com.afab.customers.domain.Customer;
import com.afab.customers.dto.CreateCustomerRequest;
import com.afab.customers.dto.CustomerDTO;
import com.afab.customers.dto.UpdateCustomerRequest;
import com.afab.customers.repository.CustomerRepository;
import com.afab.customers.service.CustomerService;
import com.afab.security.AuditService;
import com.afab.user.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private CurrentBusinessService currentBusinessService;
    @Mock private AuditService auditService;

    private CustomerService customerService;

    private User ownerA;
    private Business businessA;
    private Business businessB;

    @BeforeEach
    void setUp() {
        customerService = new CustomerService(customerRepository, currentBusinessService, auditService, null);

        ownerA = new User("Alice", "Owner", "alice@a.com", "hash");
        ownerA.setId(UUID.randomUUID());

        businessA = new Business(ownerA, "Biz A", "TND");
        businessA.setId(UUID.randomUUID());

        businessB = new Business(new User("Bob", "Owner", "bob@b.com", "hash"), "Biz B", "EUR");
        businessB.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Creates a business-scoped customer with auto-generated code and audit log")
    void createCustomerSuccess() {
        when(currentBusinessService.getCurrentUser("alice@a.com")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("alice@a.com")).thenReturn(businessA);
        when(customerRepository.existsActiveByBusinessIdAndEmailIgnoreCase(businessA.getId(), "client@acme.tn")).thenReturn(false);
        when(customerRepository.countAllByBusinessId(businessA.getId())).thenReturn(0L);
        when(customerRepository.existsByBusinessIdAndCustomerCodeIgnoreCase(businessA.getId(), "CST-1001")).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(inv -> {
            Customer c = inv.getArgument(0);
            c.setId(UUID.randomUUID());
            return c;
        });

        CreateCustomerRequest req = new CreateCustomerRequest();
        req.setName("Acme Tunisia");
        req.setCompanyName("Acme SARL");
        req.setEmail("Client@Acme.TN");
        req.setPhone("+216 71 000 000");

        CustomerDTO dto = customerService.createCustomer("alice@a.com", req);

        assertThat(dto.customerCode()).isEqualTo("CST-1001");
        assertThat(dto.email()).isEqualTo("client@acme.tn");
        assertThat(dto.businessId()).isEqualTo(businessA.getId());
        assertThat(dto.companyName()).isEqualTo("Acme SARL");
        verify(auditService).log(eq(ownerA), eq("CREATE"), eq("Customer"), eq(dto.id()), any());
    }

    @Test
    @DisplayName("Rejects duplicate customer email within same business with 409 Conflict")
    void rejectsDuplicateEmailWithinBusiness() {
        when(currentBusinessService.getCurrentUser("alice@a.com")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("alice@a.com")).thenReturn(businessA);
        when(customerRepository.existsActiveByBusinessIdAndEmailIgnoreCase(businessA.getId(), "dup@acme.tn")).thenReturn(true);

        CreateCustomerRequest req = new CreateCustomerRequest();
        req.setName("Dup Customer");
        req.setEmail("dup@acme.tn");

        assertThatThrownBy(() -> customerService.createCustomer("alice@a.com", req))
                .isInstanceOf(ConflictException.class);
        verify(customerRepository, never()).save(any());
    }

    @Test
    @DisplayName("Blocks cross-tenant read, update, and archive on Business B's customer")
    void enforcesCustomerTenantIsolation() {
        Customer foreignCustomer = new Customer();
        foreignCustomer.setId(UUID.randomUUID());
        foreignCustomer.setBusiness(businessB);
        foreignCustomer.setCustomerCode("CST-1001");
        foreignCustomer.setName("Business B Client");

        when(currentBusinessService.getCurrentBusiness("alice@a.com")).thenReturn(businessA);
        when(currentBusinessService.getCurrentUser("alice@a.com")).thenReturn(ownerA);
        when(customerRepository.findActiveById(foreignCustomer.getId())).thenReturn(Optional.of(foreignCustomer));

        assertThatThrownBy(() -> customerService.getCustomerById("alice@a.com", foreignCustomer.getId()))
                .isInstanceOf(ForbiddenException.class);

        UpdateCustomerRequest updateReq = new UpdateCustomerRequest();
        updateReq.setName("Tampered");
        assertThatThrownBy(() -> customerService.updateCustomer("alice@a.com", foreignCustomer.getId(), updateReq))
                .isInstanceOf(ForbiddenException.class);

        assertThatThrownBy(() -> customerService.archiveCustomer("alice@a.com", foreignCustomer.getId()))
                .isInstanceOf(ForbiddenException.class);

        verify(customerRepository, never()).save(any());
    }

    @Test
    @DisplayName("Soft-archives customer instead of hard-deleting to preserve invoice history")
    void archiveCustomerSoftDeletes() {
        Customer ownCustomer = new Customer();
        ownCustomer.setId(UUID.randomUUID());
        ownCustomer.setBusiness(businessA);
        ownCustomer.setCustomerCode("CST-1001");
        ownCustomer.setName("Client A");

        when(currentBusinessService.getCurrentUser("alice@a.com")).thenReturn(ownerA);
        when(currentBusinessService.getCurrentBusiness("alice@a.com")).thenReturn(businessA);
        when(customerRepository.findActiveById(ownCustomer.getId())).thenReturn(Optional.of(ownCustomer));

        customerService.archiveCustomer("alice@a.com", ownCustomer.getId());

        assertThat(ownCustomer.getArchivedAt()).isNotNull();
        assertThat(ownCustomer.getStatus()).isEqualTo("Archived");
        verify(customerRepository).save(ownCustomer);
        verify(customerRepository, never()).delete(any());
    }
}
