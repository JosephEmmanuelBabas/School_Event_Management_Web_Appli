package com.school_event.school_event_management.security;

// The two facts about an account that can change while a session is open.
public record AccountState(String accountStatus, String roleName) {
}