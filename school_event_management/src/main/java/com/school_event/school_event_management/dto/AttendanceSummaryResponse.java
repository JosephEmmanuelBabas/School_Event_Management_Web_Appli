package com.school_event.school_event_management.dto;

public record AttendanceSummaryResponse(
        Integer eventId,
        long present,
        long late,
        long absent,
        long totalRecorded) {
}