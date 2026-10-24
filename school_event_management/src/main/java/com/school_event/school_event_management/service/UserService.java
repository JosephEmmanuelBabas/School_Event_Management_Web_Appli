package com.school_event.school_event_management.service;

import java.util.List;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.CreateUserRequest;
import com.school_event.school_event_management.dto.ResetPasswordRequest;
import com.school_event.school_event_management.dto.UpdateUserRequest;
import com.school_event.school_event_management.dto.UserResponse;
import com.school_event.school_event_management.entity.Role;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.roleRepository;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.security.PasswordPolicy;

@Service
public class UserService {

    private static final String AUDIT_TABLE = "user_account";
    private static final String SUPER_ADMIN = "Super Admin";
    private static final String ACTIVE = "Active";

    private final userAccountRepository users;
    private final roleRepository roles;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    public UserService(userAccountRepository users, roleRepository roles,
                       PasswordEncoder passwordEncoder, AuditService auditService) {
        this.users = users;
        this.roles = roles;
        this.passwordEncoder = passwordEncoder;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<UserResponse> findAll() {
        return users.findAllByOrderByUsernameAsc().stream().map(UserResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public UserResponse findById(Integer id) {
        return UserResponse.from(getOrThrow(id));
    }

    @Transactional
    public UserResponse create(CreateUserRequest request) {
        PasswordPolicy.validate(request.password());
        String username = request.username().trim();
        if (users.existsByUsernameIgnoreCase(username)) {
            throw new DuplicateResourceException("A user named '" + username + "' already exists.");
        }
        String email = normalizeEmail(request.email());
        if (email != null && users.existsByEmailIgnoreCase(email)) {
            throw new DuplicateResourceException("A user with email '" + email + "' already exists.");
        }
        Role role = findRole(request.roleName());

        userAccount saved = users.save(new userAccount(
                username,
                passwordEncoder.encode(request.password()),
                request.firstName().trim(),
                request.lastName().trim(),
                email,
                role));
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getUserId());
        return UserResponse.from(saved);
    }

    @Transactional
    public UserResponse update(Integer id, UpdateUserRequest request, Integer actingUserId) {
        userAccount user = getOrThrow(id);
        String username = request.username().trim();
        if (users.existsByUsernameIgnoreCaseAndUserIdNot(username, id)) {
            throw new DuplicateResourceException("A user named '" + username + "' already exists.");
        }
        String email = normalizeEmail(request.email());
        if (email != null && users.existsByEmailIgnoreCaseAndUserIdNot(email, id)) {
            throw new DuplicateResourceException("A user with email '" + email + "' already exists.");
        }
        Role newRole = findRole(request.roleName());
        String newStatus = request.accountStatus();
        String oldRoleName = user.getRole().getRoleName();

        boolean roleChanged = !newRole.getRoleName().equals(oldRoleName);
        boolean statusChanged = !newStatus.equals(user.getAccountStatus());

        // Rule: nobody can lock themselves out.
        if (id.equals(actingUserId) && (roleChanged || statusChanged)) {
            throw new InvalidRequestException("You cannot change your own role or account status.");
        }
        // Rule: at least one active Super Admin must always remain.
        boolean wasActiveAdmin = SUPER_ADMIN.equals(oldRoleName) && ACTIVE.equals(user.getAccountStatus());
        boolean willBeActiveAdmin = SUPER_ADMIN.equals(newRole.getRoleName()) && ACTIVE.equals(newStatus);
        if (wasActiveAdmin && !willBeActiveAdmin
                && users.countByRole_RoleNameAndAccountStatus(SUPER_ADMIN, ACTIVE) <= 1) {
            throw new InvalidRequestException("At least one active Super Admin must remain.");
        }

        user.setUsername(username);
        user.setFirstName(request.firstName().trim());
        user.setLastName(request.lastName().trim());
        user.setEmail(email);
        user.setRole(newRole);
        user.setAccountStatus(newStatus);
        userAccount saved = users.save(user);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getUserId());
        return UserResponse.from(saved);
    }

    @Transactional
    public void resetPassword(Integer id, ResetPasswordRequest request) {
        PasswordPolicy.validate(request.newPassword());
        userAccount user = getOrThrow(id);
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        users.save(user);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, id);
    }

    private userAccount getOrThrow(Integer id) {
        return users.findById(id).orElseThrow(() -> new ResourceNotFoundException("User", id));
    }

    private Role findRole(String roleName) {
        return roles.findByRoleName(roleName.trim())
                .orElseThrow(() -> new InvalidRequestException("Unknown role: '" + roleName + "'."));
    }

    private static String normalizeEmail(String email) {
        return (email == null || email.isBlank()) ? null : email.trim();
    }
}