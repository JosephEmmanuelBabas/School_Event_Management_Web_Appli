package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @NotBlank(message = "Username is required.")
        @Pattern(regexp = "^[A-Za-z0-9._-]{3,50}$",
                message = "Username must be 3-50 characters: letters, digits, dot, underscore or hyphen.")
        String username,

        @NotBlank(message = "First name is required.")
        @Size(max = 50, message = "First name must be at most 50 characters.")
        String firstName,

        @NotBlank(message = "Last name is required.")
        @Size(max = 50, message = "Last name must be at most 50 characters.")
        String lastName,

        @Email(message = "Email is not valid.")
        @Size(max = 100, message = "Email must be at most 100 characters.")
        String email,

        @NotBlank(message = "Role is required.")
        String roleName,

        @NotBlank(message = "Account status is required.")
        @Pattern(regexp = "Active|Inactive|Suspended",
                message = "Account status must be Active, Inactive or Suspended.")
        String accountStatus) {
}