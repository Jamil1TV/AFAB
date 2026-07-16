package com.afab.auth;

import com.afab.auth.dto.AuthResponse;
import com.afab.auth.dto.LoginRequest;
import com.afab.auth.dto.RegisterRequest;
import com.afab.business.Business;
import com.afab.business.BusinessRepository;
import com.afab.common.exception.BusinessRuleException;
import com.afab.common.security.JwtService;
import com.afab.user.User;
import com.afab.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Service handling authentication operations:
 * registration, login, token refresh, logout.
 */
@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final BusinessRepository businessRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Value("${afab.jwt.access-expiration-ms}")
    private long accessExpirationMs;

    public AuthService(UserRepository userRepository,
                       BusinessRepository businessRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       AuthenticationManager authenticationManager) {
        this.userRepository = userRepository;
        this.businessRepository = businessRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }

    /**
     * Register a new user and create their business.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Check if email already exists
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessRuleException("An account with this email already exists.");
        }

        // Create user
        User user = new User(
                request.name(),
                request.email(),
                passwordEncoder.encode(request.password())
        );
        user = userRepository.save(user);

        // Create business (PR-001: one user = one business)
        String currency = request.currency() != null ? request.currency() : "USD";
        Business business = new Business(user, request.businessName(), currency);
        businessRepository.save(business);

        log.info("New user registered: {} (business: {})", user.getEmail(), business.getName());

        // Generate tokens
        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return AuthResponse.of(accessToken, refreshToken, accessExpirationMs);
    }

    /**
     * Authenticate a user and return JWT tokens.
     */
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );

        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new BusinessRuleException("Invalid email or password."));

        String accessToken = jwtService.generateAccessToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        log.info("User logged in: {}", user.getEmail());

        return AuthResponse.of(accessToken, refreshToken, accessExpirationMs);
    }
}
