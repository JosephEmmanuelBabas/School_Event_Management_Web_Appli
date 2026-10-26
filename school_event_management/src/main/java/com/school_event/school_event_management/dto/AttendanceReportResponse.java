package com.school_event.school_event_management.dto;

import java.time.LocalDate;

// attendanceRatePercent = (present + late) / totalRecorded * 100, or null when nothing is recorded.
public record AttendanceReportResponse(
        Integer eventId,
        String eventName,
        LocalDate eventDate,
        String venueName,
        String eventStatus,
        long present,
        long late,
        long absent,
        long totalRecorded,
        Double attendanceRatePercent) {
}