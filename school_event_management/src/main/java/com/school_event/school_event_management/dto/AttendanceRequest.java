package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record AttendanceRequest(
        @NotNull(message = "Participant is required.")
        Integer participantId,

        @NotBlank(message = "Attendance status is required.")
        @Pattern(regexp = "Present|Late|Absent",
                message = "Attendance status must be Present, Late or Absent.")
        String attendanceStatus) {
}