package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import org.springframework.data.domain.Pageable;
import com.school_event.school_event_management.dto.PageResult;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.ParticipantRequest;
import com.school_event.school_event_management.dto.ParticipantResponse;
import com.school_event.school_event_management.entity.Participant;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.repository.ParticipantRepository;

@ExtendWith(MockitoExtension.class)
class ParticipantServiceTest {

    @Mock
    private ParticipantRepository participants;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private ParticipantService participantService;

    @Test
    void create_rejectsDuplicateStudentNumber_ignoringCase() {
        when(participants.existsByStudentNumberIgnoreCase("2024-001")).thenReturn(true);

        assertThrows(DuplicateResourceException.class, () -> participantService.create(
                new ParticipantRequest(" 2024-001 ", "Ana", "Cruz", "10")));

        verify(participants, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_trimsText_andWritesAuditEntry() {
        when(participants.save(any(Participant.class))).thenAnswer(call -> call.getArgument(0));

        ParticipantResponse response = participantService.create(
                new ParticipantRequest(" 2024-001 ", " Ana ", "Cruz", "  "));

        assertEquals("2024-001", response.studentNumber());
        assertEquals("Ana", response.firstName());
        assertNull(response.gradeLevel());
        verify(auditService).log(eq(AuditAction.CREATED), eq("participant"), any());
    }

    @Test
    void delete_reportsConflictWhenAttendanceExists() {
        Participant participant = new Participant("2024-001", "Ana", "Cruz", "10");
        when(participants.findById(4)).thenReturn(Optional.of(participant));
        doThrow(new DataIntegrityViolationException("foreign key")).when(participants).flush();

        assertThrows(DuplicateResourceException.class, () -> participantService.delete(4));

        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void search_returnsOnePageAndTheTotalCount() {
        when(participants.search(eq(""), eq("ana"), any(Pageable.class)))
                .thenReturn(List.of(new Participant("2024-001", "Ana", "Cruz", "10")));
        when(participants.countSearch("", "ana")).thenReturn(7L);

        PageResult<ParticipantResponse> page = participantService.search("ana", null, 0, 50);

        assertEquals(1, page.items().size());
        assertEquals(7, page.totalCount());
    }

}