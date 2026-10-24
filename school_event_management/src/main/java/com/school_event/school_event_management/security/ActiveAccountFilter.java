package com.school_event.school_event_management.security;

import java.io.IOException;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import com.school_event.school_event_management.repository.userAccountRepository;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

// Cuts off a session when its account is deactivated or its role has changed.
// Created in SecurityConfig (not a @Component) so it runs only inside the security chain.
public class ActiveAccountFilter extends OncePerRequestFilter {

    private final userAccountRepository users;

    public ActiveAccountFilter(userAccountRepository users) {
        this.users = users;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof AppUserPrincipal principal) {
            boolean stillValid = users.findAccountState(principal.getUserId())
                    .map(state -> "Active".equals(state.accountStatus())
                            && state.roleName().equals(principal.getRoleName()))
                    .orElse(false);
            if (!stillValid) {
                SecurityContextHolder.clearContext();
                HttpSession session = request.getSession(false);
                if (session != null) {
                    session.invalidate();
                }
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }
        chain.doFilter(request, response);
    }
}