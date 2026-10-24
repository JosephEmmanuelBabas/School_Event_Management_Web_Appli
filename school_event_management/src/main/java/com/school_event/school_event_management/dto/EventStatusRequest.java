package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record EventStatusRequest(
        @NotBlank(message = "Status is required.")
        @Pattern(regexp = "Upcoming|Ongoing|Completed|Cancelled",
                message = "Status must be Upcoming, Ongoing, Completed or Cancelled.")
        String status) {
}