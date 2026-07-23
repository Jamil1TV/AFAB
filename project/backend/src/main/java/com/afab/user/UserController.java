package com.afab.user;

import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.user.dto.UserProfileDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;

    public UserController(UserRepository userRepository, BusinessRepository businessRepository) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        Business business = businessRepository.findByUserId(user.getId()).orElse(null);

        UserProfileDTO profile = new UserProfileDTO(
                user.getId(),
                user.getFirstName(),
                user.getLastName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getAvatarUrl(),
                user.getEmailVerifiedAt() != null,
                business != null ? business.getId() : null,
                business != null ? business.getName() : "My Workspace",
                business != null ? business.getCurrency() : "USD",
                business != null ? business.getCountry() : null,
                business != null && business.isOnboardingComplete(),
                user.getCreatedAt()
        );

        return ResponseEntity.ok(profile);
    }
}
