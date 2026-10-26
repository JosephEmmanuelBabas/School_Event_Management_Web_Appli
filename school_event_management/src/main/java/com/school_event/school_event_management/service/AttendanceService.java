package com.school_event.school_event_management.service;

import java.util.List;
import java.util.Set;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.AttendanceRequest;
import com.school_event.school_event_management.dto.AttendanceResponse;
import com.school_event.school_event_management.dto.AttendanceSummaryResponse;
import com.school_event.school_event_management.dto.AttendanceUpdateRequest;
import com.school_event.school_event_management.entity.Attendance;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.Participant;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.AttendanceRepository;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.ParticipantRepository;

@Service
public class AttendanceService {

    private static final String AUDIT_TABLE = "attendance";
    private static final String PRESENT = "Present";
    private static final String LATE = "Late";
    private static final String ABSENT = "Absent";
    private static final Set<String> STATUSES = Set.of(PRESENT, LATE, ABSENT);

    private static final String DUPLICATE_MESSAGE =
            "This participant already has an attendance record for this event. "
                    + "Change the existing record instead.";

    private final EventRepository events;
    private final ParticipantRepository participants;
    private final AttendanceRepository attendanceRepository;
    private final AuditService auditService;

    public AttendanceService(EventRepository events, ParticipantRepository participants,
                             AttendanceRepository attendanceRepository, AuditService auditService) {
        this.events = events;
        this.participants = participants;
        this.attendanceRepository = attendanceRepository;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<AttendanceResponse> list(Integer eventId, String status) {
        if (!events.existsById(eventId)) {
            throw new ResourceNotFoundException("Event", eventId);
        }
        String statusFilter = (status == null || status.isBlank()) ? "" : status.trim();
        if (!statusFilter.isEmpty() && !STATUSES.contains(statusFilter)) {
            throw new InvalidRequestException("Unknown attendance status: '" + statusFilter + "'.");
        }
        return attendanceRepository.findForEvent(eventId, statusFilter)
                .stream()
                .map(AttendanceResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AttendanceSummaryResponse summary(Integer eventId) {
        if (!events.existsById(eventId)) {
            throw new ResourceNotFoundException("Event", eventId);
        }
        long present = attendanceRepository.countByEvent_EventIdAndAttendanceStatus(eventId, PRESENT);
        long late = attendanceRepository.countByEvent_EventIdAndAttendanceStatus(eventId, LATE);
        long absent = attendanceRepository.countByEvent_EventIdAndAttendanceStatus(eventId, ABSENT);
        return new AttendanceSummaryResponse(eventId, present, late, absent, present + late + absent);
    }

    @Transactional
    public AttendanceResponse record(Integer eventId, AttendanceRequest request) {
        Event event = getEventOpenForAttendance(eventId);
        Participant participant = participants.findById(request.participantId())
                .orElseThrow(() -> new InvalidRequestException(
                        "Participant " + request.participantId() + " does not exist."));
        if (attendanceRepository.existsByEvent_EventIdAndParticipant_ParticipantId(
                eventId, request.participantId())) {
            throw new DuplicateResourceException(DUPLICATE_MESSAGE);
        }

        Attendance saved;
        try {
            saved = attendanceRepository.saveAndFlush(
                    new Attendance(event, participant, request.attendanceStatus()));
        } catch (DataIntegrityViolationException ex) {
            // Safety net: two requests raced past the check above, and the database
            // UNIQUE (event_id, participant_id) constraint refused the second one.
            throw new DuplicateResourceException(DUPLICATE_MESSAGE);
        }
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getAttendanceId());
        return AttendanceResponse.from(saved);
    }

    @Transactional
    public AttendanceResponse changeStatus(Integer eventId, Integer attendanceId,
                                           AttendanceUpdateRequest request) {
        getEventOpenForAttendance(eventId);
        Attendance record = getRecordOrThrow(attendanceId, eventId);
        if (record.getAttendanceStatus().equals(request.attendanceStatus())) {
            return AttendanceResponse.from(record); // nothing changed, so nothing is logged
        }
        record.changeStatus(request.attendanceStatus());
        Attendance saved = attendanceRepository.save(record);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getAttendanceId());
        return AttendanceResponse.from(saved);
    }

    @Transactional
    public void delete(Integer eventId, Integer attendanceId) {
        getEventOpenForAttendance(eventId);
        Attendance record = getRecordOrThrow(attendanceId, eventId);
        attendanceRepository.delete(record);
        auditService.log(AuditAction.DELETED, AUDIT_TABLE, attendanceId);
    }

    // ---- helpers ----

    private Event getEventOpenForAttendance(Integer eventId) {
        Event event = events.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event", eventId));
        String status = event.getEventStatus();
        if (!"Ongoing".equals(status) && !"Completed".equals(status)) {
            throw new InvalidRequestException(
                    "Attendance can only be changed for ongoing or completed events (this event is "
                            + status.toLowerCase() + ").");
        }
        return event;
    }

    private Attendance getRecordOrThrow(Integer attendanceId, Integer eventId) {
        return attendanceRepository.findByAttendanceIdAndEvent_EventId(attendanceId, eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Attendance record", attendanceId));
    }
}