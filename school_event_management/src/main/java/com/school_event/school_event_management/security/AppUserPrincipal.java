package com.school_event.school_event_management.security;

import java.util.List;
import java.util.Locale;

import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;

public class AppUserPrincipal extends User {

    private final Integer userId;
    private final String roleName;

    public AppUserPrincipal(Integer userId, String username, String passwordHash,
                            String roleName, boolean active) {
        // enabled = active: Inactive and Suspended accounts cannot log in.
        super(username, passwordHash, active, true, true, true,
                List.of(new SimpleGrantedAuthority(toAuthority(roleName))));
        this.userId = userId;
        this.roleName = roleName;
    }

    // "Super Admin" -> "ROLE_SUPER_ADMIN", "Event Organizer" -> "ROLE_EVENT_ORGANIZER"
    private static String toAuthority(String roleName) {
        return "ROLE_" + roleName.trim().toUpperCase(Locale.ROOT).replace(' ', '_');
    }

    public Integer getUserId() { return userId; }

    public String getRoleName() { return roleName; }
}