package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;

public record ResetPasswordRequest(
        @NotBlank(message = "New password is required.")
        String newPassword) {

    @Override
    public String toString() {
        return "ResetPasswordRequest[]";
    }
}