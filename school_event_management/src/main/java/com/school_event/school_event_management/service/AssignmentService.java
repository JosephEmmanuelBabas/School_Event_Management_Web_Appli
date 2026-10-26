package com.school_event.school_event_management.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.AssignmentRequest;
import com.school_event.school_event_management.dto.AssignmentResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.EventAssignment;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.EventAssignmentRepository;
import com.school_event.school_event_management.repository.EventRepository;

@Service
public class AssignmentService {

    private static final String AUDIT_TABLE = "event_assignment";
    private static final String DEFAULT_STATUS = "Pending";

    private final EventRepository events;
    private final EventAssignmentRepository assignments;
    private final AuditService auditService;

    public AssignmentService(EventRepository events, EventAssignmentRepository assignments,
                             AuditService auditService) {
        this.events = events;
        this.assignments = assignments;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<AssignmentResponse> list(Integer eventId) {
        if (!events.existsById(eventId)) {
            throw new ResourceNotFoundException("Event", eventId);
        }
        return assignments.findByEvent_EventIdOrderByStaffNameAscAssignmentIdAsc(eventId)
                .stream()
                .map(AssignmentResponse::from)
                .toList();
    }

    @Transactional
    public AssignmentResponse create(Integer eventId, AssignmentRequest request) {
        Event event = getOpenEvent(eventId);
        EventAssignment saved = assignments.save(new EventAssignment(
                event,
                request.staffName().trim(),
                normalize(request.staffRole()),
                statusOrDefault(request.assignmentStatus())));
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getAssignmentId());
        return AssignmentResponse.from(saved);
    }

    @Transactional
    public AssignmentResponse update(Integer eventId, Integer assignmentId, AssignmentRequest request) {
        getOpenEvent(eventId);
        EventAssignment assignment = getEntryOrThrow(assignmentId, eventId);

        assignment.setStaffName(request.staffName().trim());
        assignment.setStaffRole(normalize(request.staffRole()));
        assignment.setAssignmentStatus(statusOrDefault(request.assignmentStatus()));
        EventAssignment saved = assignments.save(assignment);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getAssignmentId());
        return AssignmentResponse.from(saved);
    }

    @Transactional
    public void delete(Integer eventId, Integer assignmentId) {
        getOpenEvent(eventId);
        EventAssignment assignment = getEntryOrThrow(assignmentId, eventId);
        assignments.delete(assignment);
        auditService.log(AuditAction.DELETED, AUDIT_TABLE, assignmentId);
    }

    // ---- helpers ----

    private Event getOpenEvent(Integer eventId) {
        Event event = events.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event", eventId));
        EventLock.ensureOpen(event);
        return event;
    }

    private EventAssignment getEntryOrThrow(Integer assignmentId, Integer eventId) {
        return assignments.findByAssignmentIdAndEvent_EventId(assignmentId, eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Staff assignment", assignmentId));
    }

    private static String statusOrDefault(String status) {
        return (status == null || status.isBlank()) ? DEFAULT_STATUS : status;
    }

    private static String normalize(String text) {
        return (text == null || text.isBlank()) ? null : text.trim();
    }
}