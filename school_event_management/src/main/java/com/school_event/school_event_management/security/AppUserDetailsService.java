package com.school_event.school_event_management.security;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.repository.userAccountRepository;

@Service
public class AppUserDetailsService implements UserDetailsService {

    private final userAccountRepository userAccountRepository;

    public AppUserDetailsService(userAccountRepository userAccountRepository) {
        this.userAccountRepository = userAccountRepository;
    }

    // The role is loaded lazily, so this must run inside a transaction.
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        userAccount account = userAccountRepository.findByUsernameIgnoreCase(username)
                .orElseThrow(() -> new UsernameNotFoundException("Unknown user."));

        boolean active = "Active".equals(account.getAccountStatus());
        return new AppUserPrincipal(
                account.getUserId(),
                account.getUsername(),
                account.getPasswordHash(),
                account.getRole().getRoleName(),
                active);
    }
}