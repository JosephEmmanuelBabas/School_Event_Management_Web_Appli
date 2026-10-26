package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
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
import com.school_event.school_event_management.dto.ScheduleRequest;
import com.school_event.school_event_management.dto.ScheduleResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.EventSchedule;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.EventScheduleRepository;

@ExtendWith(MockitoExtension.class)
class ScheduleServiceTest {

    @Mock
    private EventRepository events;

    @Mock
    private EventScheduleRepository schedules;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private ScheduleService scheduleService;

    // An event from 09:00 to 11:00.
    private Event event(String status) {
        return new Event("Assembly", null, LocalDate.now().plusDays(7),
                LocalTime.of(9, 0), LocalTime.of(11, 0), status, null, null);
    }

    @Test
    void create_rejectsEntryOutsideTheEventTimes() {
        when(events.findById(1)).thenReturn(Optional.of(event("Upcoming")));

        assertThrows(InvalidRequestException.class, () -> scheduleService.create(1,
                new ScheduleRequest("Early start", LocalTime.of(8, 0), LocalTime.of(9, 30))));

        verify(schedules, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_rejectsEndBeforeStart() {
        when(events.findById(1)).thenReturn(Optional.of(event("Upcoming")));

        assertThrows(InvalidRequestException.class, () -> scheduleService.create(1,
                new ScheduleRequest("Backwards", LocalTime.of(10, 30), LocalTime.of(10, 0))));

        verify(schedules, never()).save(any());
    }

    @Test
    void create_rejectsCompletedEvent() {
        when(events.findById(1)).thenReturn(Optional.of(event("Completed")));

        assertThrows(InvalidRequestException.class, () -> scheduleService.create(1,
                new ScheduleRequest("Late", LocalTime.of(9, 0), LocalTime.of(10, 0))));

        verify(schedules, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_savesTrimmedEntryAndWritesAuditEntry() {
        when(events.findById(1)).thenReturn(Optional.of(event("Upcoming")));
        when(schedules.save(any(EventSchedule.class))).thenAnswer(call -> call.getArgument(0));

        ScheduleResponse response = scheduleService.create(1,
                new ScheduleRequest("  Opening  ", LocalTime.of(9, 0), LocalTime.of(10, 0)));

        assertEquals("Opening", response.activityName());
        verify(auditService).log(eq(AuditAction.CREATED), eq("event_schedule"), any());
    }
}