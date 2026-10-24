package com.school_event.school_event_management.security;

import java.nio.charset.StandardCharsets;

import com.school_event.school_event_management.exception.InvalidRequestException;

public final class PasswordPolicy {

    public static final int MIN_LENGTH = 10;
    // bcrypt only uses the first 72 bytes, so longer passwords are refused.
    private static final int MAX_BYTES = 72;

    private PasswordPolicy() {
    }

    public static void validate(String password) {
        if (password == null || password.isBlank() || password.length() < MIN_LENGTH) {
            throw new InvalidRequestException(
                    "Password must be at least " + MIN_LENGTH + " characters long.");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > MAX_BYTES) {
            throw new InvalidRequestException("Password is too long (at most 72 bytes).");
        }
    }
}