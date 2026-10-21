package com.school_event.school_event_management.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.school_event.school_event_management.entity.Role;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.repository.roleRepository;
import com.school_event.school_event_management.repository.userAccountRepository;

@Component
public class AccountBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(AccountBootstrap.class);
    private static final int MIN_PASSWORD_LENGTH = 10;

    private final userAccountRepository users;
    private final roleRepository roles;
    private final PasswordEncoder passwordEncoder;
    private final String adminUsername;
    private final String adminPassword;
    private final String organizerUsername;
    private final String organizerPassword;

    public AccountBootstrap(userAccountRepository users,
                            roleRepository roles,
                            PasswordEncoder passwordEncoder,
                            @Value("${app.bootstrap.admin.username:}") String adminUsername,
                            @Value("${app.bootstrap.admin.password:}") String adminPassword,
                            @Value("${app.bootstrap.organizer.username:}") String organizerUsername,
                            @Value("${app.bootstrap.organizer.password:}") String organizerPassword) {
        this.users = users;
        this.roles = roles;
        this.passwordEncoder = passwordEncoder;
        this.adminUsername = adminUsername;
        this.adminPassword = adminPassword;
        this.organizerUsername = organizerUsername;
        this.organizerPassword = organizerPassword;
    }

    @Override
    public void run(ApplicationArguments args) {
        createFirstAccount("Super Admin", adminUsername, adminPassword, "System", "Administrator");
        createFirstAccount("Event Organizer", organizerUsername, organizerPassword, "Dev", "Organizer");
    }

    private void createFirstAccount(String roleName, String username, String password,
                                    String firstName, String lastName) {
        if (username.isBlank() && password.isBlank()) {
            return; // nothing configured for this role
        }
        if (username.isBlank() || password.length() < MIN_PASSWORD_LENGTH) {
            throw new IllegalStateException("The setup account for role '" + roleName
                    + "' needs a username and a password of at least "
                    + MIN_PASSWORD_LENGTH + " characters.");
        }
        if (users.existsByRole_RoleName(roleName)) {
            log.info("Skipped setup account for '{}': an account with that role already exists.", roleName);
            return;
        }
        Role role = roles.findByRoleName(roleName)
                .orElseThrow(() -> new IllegalStateException(
                        "Role '" + roleName + "' is missing. Check Flyway migration V2."));

        users.save(new userAccount(username.trim(), passwordEncoder.encode(password),
                firstName, lastName, null, role));
        log.info("Created first {} account '{}'.", roleName, username.trim());
    }
}