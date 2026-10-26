package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ParticipantRequest(
        @NotBlank(message = "Student number is required.")
        @Size(max = 20, message = "Student number must be at most 20 characters.")
        String studentNumber,

        @NotBlank(message = "First name is required.")
        @Size(max = 50, message = "First name must be at most 50 characters.")
        String firstName,

        @NotBlank(message = "Last name is required.")
        @Size(max = 50, message = "Last name must be at most 50 characters.")
        String lastName,

        @Size(max = 10, message = "Grade level must be at most 10 characters.")
        String gradeLevel) {
}