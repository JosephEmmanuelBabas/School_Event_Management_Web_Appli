package com.school_event.school_event_management.dto;

import java.time.LocalDateTime;

import com.school_event.school_event_management.entity.Attendance;

public record AttendanceResponse(
        Integer attendanceId,
        Integer eventId,
        Integer participantId,
        String studentNumber,
        String participantName,
        String attendanceStatus,
        LocalDateTime timeRecorded) {

    // Call this inside a service transaction (the event loads lazily).
    public static AttendanceResponse from(Attendance attendance) {
        return new AttendanceResponse(
                attendance.getAttendanceId(),
                attendance.getEvent().getEventId(),
                attendance.getParticipant().getParticipantId(),
                attendance.getParticipant().getStudentNumber(),
                attendance.getParticipant().getFirstName() + " " + attendance.getParticipant().getLastName(),
                attendance.getAttendanceStatus(),
                attendance.getTimeRecorded());
    }
}