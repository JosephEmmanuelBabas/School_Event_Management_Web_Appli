package com.school_event.school_event_management.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.security.AccountState;

public interface userAccountRepository extends JpaRepository<userAccount, Integer> {

    // Case-insensitive, matching the lower(username) unique index in the database.
    Optional<userAccount> findByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCase(String username);

    boolean existsByUsernameIgnoreCaseAndUserIdNot(String username, Integer userId);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCaseAndUserIdNot(String email, Integer userId);

    boolean existsByRole_RoleName(String roleName);

    long countByRole_RoleNameAndAccountStatus(String roleName, String accountStatus);

    // Loads the role in the same query (avoids one extra query per user).
    @EntityGraph(attributePaths = "role")
    List<userAccount> findAllByOrderByUsernameAsc();

    @Query("""
            select new com.school_event.school_event_management.security.AccountState(
                u.accountStatus, u.role.roleName)
            from userAccount u
            where u.userId = :userId
            """)
    Optional<AccountState> findAccountState(@Param("userId") Integer userId);

    long countByAccountStatus(String accountStatus);
}