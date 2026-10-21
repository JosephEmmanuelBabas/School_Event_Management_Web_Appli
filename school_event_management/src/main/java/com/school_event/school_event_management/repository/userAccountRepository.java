package com.school_event.school_event_management.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.school_event.school_event_management.entity.userAccount;

public interface userAccountRepository extends JpaRepository<userAccount, Integer> {

    // Case-insensitive, matching the lower(username) unique index in the database.
    Optional<userAccount> findByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCase(String username);

    boolean existsByRole_RoleName(String roleName);
}