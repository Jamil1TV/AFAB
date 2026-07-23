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

    /**
     * GET /api/v1/business/mine — get the current user's business without knowing UUID.
     */
    @GetMapping("/mine")
    public ResponseEntity<?> getMyBusiness(Authentication authentication) {
        User user = userRepository.findByEmail(authentication.getName()).orElseThrow();
        Business business = businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new IllegalArgumentException("No business found for this user"));
        return ResponseEntity.ok(toDTO(business));
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

        // Only update non-null fields (partial update)
        if (request.getName() != null) business.setName(request.getName());
        if (request.getCountry() != null) business.setCountry(request.getCountry());
        if (request.getCurrency() != null) business.setCurrency(request.getCurrency());
        if (request.getTimezone() != null) business.setTimezone(request.getTimezone());
        if (request.getFiscalYearStartMonth() != null) business.setFiscalYearStartMonth(request.getFiscalYearStartMonth());
        if (request.getIndustry() != null) business.setIndustry(request.getIndustry());
        if (request.getBusinessType() != null) business.setBusinessType(request.getBusinessType());
        if (request.getBusinessEmail() != null) business.setBusinessEmail(request.getBusinessEmail());
        if (request.getPhoneNumber() != null) business.setPhoneNumber(request.getPhoneNumber());
        if (request.getWebsite() != null) business.setWebsite(request.getWebsite());
        if (request.getTaxId() != null) business.setTaxId(request.getTaxId());
        if (request.getAddressLine() != null) business.setAddressLine(request.getAddressLine());
        if (request.getCity() != null) business.setCity(request.getCity());
        if (request.getState() != null) business.setState(request.getState());
        if (request.getPostalCode() != null) business.setPostalCode(request.getPostalCode());
        if (request.getDescription() != null) business.setDescription(request.getDescription());
        if (request.getLogoUrl() != null) business.setLogoUrl(request.getLogoUrl());
        if (request.getDateFormat() != null) business.setDateFormat(request.getDateFormat());
        if (request.getNumberFormat() != null) business.setNumberFormat(request.getNumberFormat());

        business = businessRepository.save(business);
        return ResponseEntity.ok(toDTO(business));
    }

    private BusinessDTO toDTO(Business business) {
        BusinessDTO dto = new BusinessDTO();
        dto.setId(business.getId());
        dto.setName(business.getName());
        dto.setCountry(business.getCountry());
        dto.setCurrency(business.getCurrency());
        dto.setTimezone(business.getTimezone());
        dto.setFiscalYearStartMonth(business.getFiscalYearStartMonth());
        dto.setIndustry(business.getIndustry());
        dto.setBusinessType(business.getBusinessType());
        dto.setBusinessEmail(business.getBusinessEmail());
        dto.setPhoneNumber(business.getPhoneNumber());
        dto.setWebsite(business.getWebsite());
        dto.setTaxId(business.getTaxId());
        dto.setAddressLine(business.getAddressLine());
        dto.setCity(business.getCity());
        dto.setState(business.getState());
        dto.setPostalCode(business.getPostalCode());
        dto.setDescription(business.getDescription());
        dto.setLogoUrl(business.getLogoUrl());
        dto.setStatus(business.getStatus());
        dto.setOnboardingComplete(business.isOnboardingComplete());
        dto.setCreatedAt(business.getCreatedAt());
        dto.setDateFormat(business.getDateFormat());
        dto.setNumberFormat(business.getNumberFormat());
        return dto;
    }
}
