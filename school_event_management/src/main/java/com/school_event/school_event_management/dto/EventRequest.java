package com.school_event.school_event_management.dto;

import java.time.LocalDate;
import java.time.LocalTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record EventRequest(
        @NotBlank(message = "Event name is required.")
        @Size(max = 100, message = "Event name must be at most 100 characters.")
        String eventName,

        @Size(max = 5000, message = "Description must be at most 5000 characters.")
        String description,

        @NotNull(message = "Event date is required.")
        LocalDate eventDate,

        @NotNull(message = "Start time is required.")
        LocalTime startTime,

        @NotNull(message = "End time is required.")
        LocalTime endTime,

        @NotNull(message = "Venue is required.")
        Integer venueId) {
}