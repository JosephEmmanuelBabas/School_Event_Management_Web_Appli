package com.school_event.school_event_management.dto;

import com.school_event.school_event_management.entity.Participant;

public record ParticipantResponse(
        Integer participantId,
        String studentNumber,
        String firstName,
        String lastName,
        String gradeLevel) {

    public static ParticipantResponse from(Participant participant) {
        return new ParticipantResponse(
                participant.getParticipantId(),
                participant.getStudentNumber(),
                participant.getFirstName(),
                participant.getLastName(),
                participant.getGradeLevel());
    }
}