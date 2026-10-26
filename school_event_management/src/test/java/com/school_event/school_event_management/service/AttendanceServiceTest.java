package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
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
import com.school_event.school_event_management.dto.AttendanceRequest;
import com.school_event.school_event_management.dto.AttendanceResponse;
import com.school_event.school_event_management.dto.AttendanceSummaryResponse;
import com.school_event.school_event_management.dto.AttendanceUpdateRequest;
import com.school_event.school_event_management.entity.Attendance;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.Participant;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.AttendanceRepository;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.ParticipantRepository;

@ExtendWith(MockitoExtension.class)
class AttendanceServiceTest {

    @Mock
    private EventRepository events;

    @Mock
    private ParticipantRepository participants;

    @Mock
    private AttendanceRepository attendanceRepository;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private AttendanceService attendanceService;

    private Event event(String status) {
        return new Event("Assembly", null, LocalDate.now().plusDays(7),
                LocalTime.of(9, 0), LocalTime.of(11, 0), status, null, null);
    }

    private Participant ana() {
        return new Participant("2024-001", "Ana", "Cruz", "10");
    }

    @Test
    void record_rejectsEventThatHasNotStarted() {
        when(events.findById(1)).thenReturn(Optional.of(event("Upcoming")));

        assertThrows(InvalidRequestException.class,
                () -> attendanceService.record(1, new AttendanceRequest(7, "Present")));

        verify(attendanceRepository, never()).saveAndFlush(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void record_rejectsCancelledEvent() {
        when(events.findById(1)).thenReturn(Optional.of(event("Cancelled")));

        assertThrows(InvalidRequestException.class,
                () -> attendanceService.record(1, new AttendanceRequest(7, "Present")));

        verify(attendanceRepository, never()).saveAndFlush(any());
    }

    @Test
    void record_rejectsUnknownParticipant() {
        when(events.findById(1)).thenReturn(Optional.of(event("Ongoing")));
        when(participants.findById(7)).thenReturn(Optional.empty());

        assertThrows(InvalidRequestException.class,
                () -> attendanceService.record(1, new AttendanceRequest(7, "Present")));

        verify(attendanceRepository, never()).saveAndFlush(any());
    }

    @Test
    void record_rejectsSecondRecordForTheSameParticipantAndEvent() {
        when(events.findById(1)).thenReturn(Optional.of(event("Ongoing")));
        when(participants.findById(7)).thenReturn(Optional.of(ana()));
        when(attendanceRepository.existsByEvent_EventIdAndParticipant_ParticipantId(1, 7))
                .thenReturn(true);

        assertThrows(DuplicateResourceException.class,
                () -> attendanceService.record(1, new AttendanceRequest(7, "Present")));

        verify(attendanceRepository, never()).saveAndFlush(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void record_savesWithServerTime_andWritesAuditEntry() {
        when(events.findById(1)).thenReturn(Optional.of(event("Ongoing")));
        when(participants.findById(7)).thenReturn(Optional.of(ana()));
        when(attendanceRepository.saveAndFlush(any(Attendance.class)))
                .thenAnswer(call -> call.getArgument(0));

        AttendanceResponse response =
                attendanceService.record(1, new AttendanceRequest(7, "Present"));

        assertEquals("Present", response.attendanceStatus());
        assertEquals("Ana Cruz", response.participantName());
        assertNotNull(response.timeRecorded());
        verify(auditService).log(eq(AuditAction.CREATED), eq("attendance"), any());
    }

    @Test
    void changeStatus_updatesStatus_andWritesAuditEntry() {
        when(events.findById(1)).thenReturn(Optional.of(event("Completed")));
        Attendance existing = new Attendance(event("Completed"), ana(), "Late");
        when(attendanceRepository.findByAttendanceIdAndEvent_EventId(5, 1))
                .thenReturn(Optional.of(existing));
        when(attendanceRepository.save(any(Attendance.class)))
                .thenAnswer(call -> call.getArgument(0));

        AttendanceResponse response =
                attendanceService.changeStatus(1, 5, new AttendanceUpdateRequest("Absent"));

        assertEquals("Absent", response.attendanceStatus());
        verify(auditService).log(eq(AuditAction.UPDATED), eq("attendance"), any());
    }

    @Test
    void summary_countsEachStatus() {
        when(events.existsById(1)).thenReturn(true);
        when(attendanceRepository.countByEvent_EventIdAndAttendanceStatus(1, "Present")).thenReturn(3L);
        when(attendanceRepository.countByEvent_EventIdAndAttendanceStatus(1, "Late")).thenReturn(1L);
        when(attendanceRepository.countByEvent_EventIdAndAttendanceStatus(1, "Absent")).thenReturn(2L);

        AttendanceSummaryResponse summary = attendanceService.summary(1);

        assertEquals(3, summary.present());
        assertEquals(1, summary.late());
        assertEquals(2, summary.absent());
        assertEquals(6, summary.totalRecorded());
    }
}