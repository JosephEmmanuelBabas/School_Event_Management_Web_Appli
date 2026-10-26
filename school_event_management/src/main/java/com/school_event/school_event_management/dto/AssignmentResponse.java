package com.school_event.school_event_management.dto;

import com.school_event.school_event_management.entity.EventAssignment;

public record AssignmentResponse(
        Integer assignmentId,
        Integer eventId,
        String staffName,
        String staffRole,
        String assignmentStatus) {

    public static AssignmentResponse from(EventAssignment assignment) {
        return new AssignmentResponse(
                assignment.getAssignmentId(),
                assignment.getEvent().getEventId(),
                assignment.getStaffName(),
                assignment.getStaffRole(),
                assignment.getAssignmentStatus());
    }
}