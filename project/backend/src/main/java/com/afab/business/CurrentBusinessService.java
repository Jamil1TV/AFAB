package com.afab.business;

import com.afab.common.exception.ResourceNotFoundException;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service to resolve the current active business for a user.
 * Encapsulates the user -> business resolution in one place for future multi-business extensibility.
 */
@Service
public class CurrentBusinessService {

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;

    public CurrentBusinessService(UserRepository userRepository, BusinessRepository businessRepository) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public Business getCurrentBusiness(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));

        return businessRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("No business found for user: " + userEmail));
    }

    @Transactional(readOnly = true)
    public User getCurrentUser(String userEmail) {
        return userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userEmail));
    }
}
