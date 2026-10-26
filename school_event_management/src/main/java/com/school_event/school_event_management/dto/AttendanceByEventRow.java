package com.school_event.school_event_management.dto;

import java.time.LocalDate;

public record AttendanceByEventRow(
        Integer eventId,
        String eventName,
        LocalDate eventDate,
        String venueName,
        String eventStatus,
        Long present,
        Long late,
        Long absent) {
}