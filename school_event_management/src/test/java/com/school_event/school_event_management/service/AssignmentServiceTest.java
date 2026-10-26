package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.AssignmentRequest;
import com.school_event.school_event_management.dto.AssignmentResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.EventAssignment;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.EventAssignmentRepository;
import com.school_event.school_event_management.repository.EventRepository;

@ExtendWith(MockitoExtension.class)
class AssignmentServiceTest {

    @Mock
    private EventRepository events;

    @Mock
    private EventAssignmentRepository assignments;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private AssignmentService assignmentService;

    private Event event(String status) {
        return new Event("Assembly", null, LocalDate.now().plusDays(7),
                LocalTime.of(9, 0), LocalTime.of(11, 0), status, null, null);
    }

    @Test
    void create_defaultsToPending_trimsText_andWritesAuditEntry() {
        when(events.findById(1)).thenReturn(Optional.of(event("Upcoming")));
        when(assignments.save(any(EventAssignment.class))).thenAnswer(call -> call.getArgument(0));

        AssignmentResponse response = assignmentService.create(1,
                new AssignmentRequest("  Juan Dela Cruz ", "  ", null));

        assertEquals("Juan Dela Cruz", response.staffName());
        assertNull(response.staffRole());
        assertEquals("Pending", response.assignmentStatus());
        verify(auditService).log(eq(AuditAction.CREATED), eq("event_assignment"), any());
    }

    @Test
    void create_rejectsCancelledEvent() {
        when(events.findById(1)).thenReturn(Optional.of(event("Cancelled")));

        assertThrows(InvalidRequestException.class, () -> assignmentService.create(1,
                new AssignmentRequest("Juan", "Usher", "Confirmed")));

        verify(assignments, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }
}