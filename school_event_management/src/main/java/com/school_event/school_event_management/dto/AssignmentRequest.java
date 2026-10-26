package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record AssignmentRequest(
        @NotBlank(message = "Staff name is required.")
        @Size(max = 100, message = "Staff name must be at most 100 characters.")
        String staffName,

        @Size(max = 50, message = "Staff role must be at most 50 characters.")
        String staffRole,

        // Optional. When missing, the service uses "Pending".
        @Pattern(regexp = "Confirmed|Pending|Cancelled",
                message = "Assignment status must be Confirmed, Pending or Cancelled.")
        String assignmentStatus) {
}