package com.school_event.school_event_management.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record AttendanceUpdateRequest(
        @NotBlank(message = "Attendance status is required.")
        @Pattern(regexp = "Present|Late|Absent",
                message = "Attendance status must be Present, Late or Absent.")
        String attendanceStatus) {
}