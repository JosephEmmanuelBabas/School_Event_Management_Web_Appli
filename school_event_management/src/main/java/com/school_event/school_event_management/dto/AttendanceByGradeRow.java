package com.school_event.school_event_management.dto;

public record AttendanceByGradeRow(
        String gradeLevel,
        Long present,
        Long late,
        Long absent) {
}