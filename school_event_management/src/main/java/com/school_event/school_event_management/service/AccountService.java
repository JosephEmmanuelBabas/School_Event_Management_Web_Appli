package com.school_event.school_event_management.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.ChangePasswordRequest;
import com.school_event.school_event_management.dto.UpdateProfileRequest;
import com.school_event.school_event_management.dto.UserResponse;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.security.PasswordPolicy;

// Self-service: the logged-in user managing their own account.
@Service
public class AccountService {

    private static final String AUDIT_TABLE = "user_account";

    private final userAccountRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    public AccountService(userAccountRepository users, PasswordEncoder passwordEncoder,
                          AuditService auditService) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public UserResponse getMe(Integer userId) {
        return UserResponse.from(getOrThrow(userId));
    }

    @Transactional
    public UserResponse updateProfile(Integer userId, UpdateProfileRequest request) {
        userAccount user = getOrThrow(userId);
        String email = (request.email() == null || request.email().isBlank())
                ? null : request.email().trim();
        if (email != null && users.existsByEmailIgnoreCaseAndUserIdNot(email, userId)) {
            throw new DuplicateResourceException("A user with email '" + email + "' already exists.");
        }
        user.setFirstName(request.firstName().trim());
        user.setLastName(request.lastName().trim());
        user.setEmail(email);
        userAccount saved = users.save(user);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, userId);
        return UserResponse.from(saved);
    }

    @Transactional
    public void changePassword(Integer userId, ChangePasswordRequest request) {
        userAccount user = getOrThrow(userId);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new InvalidRequestException("Current password is incorrect.");
        }
        PasswordPolicy.validate(request.newPassword());
        if (request.newPassword().equals(request.currentPassword())) {
            throw new InvalidRequestException("New password must be different from the current one.");
        }
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        users.save(user);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, userId);
    }

    private userAccount getOrThrow(Integer userId) {
        return users.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));
    }
}