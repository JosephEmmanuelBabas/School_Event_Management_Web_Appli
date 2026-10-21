package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record VenueRequest(
        @NotBlank(message = "Venue name is required.")
        @Size(max = 100, message = "Venue name must be at most 100 characters.")
        String venueName,

        @NotBlank(message = "Location is required.")
        @Size(max = 150, message = "Location must be at most 150 characters.")
        String location,

        // Optional (null is allowed); if given, it must be greater than zero.
        @Positive(message = "Capacity must be greater than zero.")
        Integer capacity) {
}