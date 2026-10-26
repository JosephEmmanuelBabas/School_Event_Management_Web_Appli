package com.school_event.school_event_management.dto;

public record GradeAttendanceResponse(
        String gradeLevel,
        long present,
        long late,
        long absent,
        long totalRecorded,
        Double attendanceRatePercent) {
}