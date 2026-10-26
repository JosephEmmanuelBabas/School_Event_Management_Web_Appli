package com.school_event.school_event_management.dto;

import java.time.LocalTime;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ScheduleRequest(
        @NotBlank(message = "Activity name is required.")
        @Size(max = 100, message = "Activity name must be at most 100 characters.")
        String activityName,

        @NotNull(message = "Start time is required.")
        LocalTime startTime,

        @NotNull(message = "End time is required.")
        LocalTime endTime) {
}