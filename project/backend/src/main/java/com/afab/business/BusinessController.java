package com.afab.business;

import com.afab.business.dto.BusinessDTO;
import com.afab.business.dto.UpdateBusinessRequest;
import com.afab.user.User;
import com.afab.user.UserRepository;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/business")
public class BusinessController {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;

    public BusinessController(BusinessRepository businessRepository, UserRepository userRepository) {
        this.businessRepository = businessRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getBusiness(@PathVariable UUID id, Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName()).orElseThrow();
        Business business = businessRepository.findById(id).orElseThrow();

        // Ensure user owns this business
        if (!business.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body("Forbidden");
        }

        return ResponseEntity.ok(toDTO(business));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateBusiness(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBusinessRequest request,
            Authentication authentication
    ) {
        User user = userRepository.findByEmail(authentication.getName()).orElseThrow();
        Business business = businessRepository.findById(id).orElseThrow();

        // Ensure user owns this business
        if (!business.getUser().getId().equals(user.getId())) {
            return ResponseEntity.status(403).body("Forbidden");
        }

        business.setCountry(request.getCountry());
        business.setCurrency(request.getCurrency());
        business.setTimezone(request.getTimezone());
        business.setFiscalYearStartMonth(request.getFiscalYearStartMonth());

        if (request.getIndustry() != null) {
            business.setIndustry(request.getIndustry());
        }
        if (request.getBusinessType() != null) {
            business.setBusinessType(request.getBusinessType());
        }

        business = businessRepository.save(business);
        return ResponseEntity.ok(toDTO(business));
    }

    private BusinessDTO toDTO(Business business) {
        return new BusinessDTO(
                business.getId(),
                business.getName(),
                business.getCountry(),
                business.getCurrency(),
                business.getTimezone(),
                business.getFiscalYearStartMonth(),
                business.getIndustry(),
                business.getBusinessType(),
                business.getStatus(),
                business.isOnboardingComplete()
        );
    }
}
