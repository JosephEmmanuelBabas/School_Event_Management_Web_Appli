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
import com.school_event.school_event_management.dto.EventRequest;
import com.school_event.school_event_management.dto.EventResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.Venue;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.repository.venueRepository;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private EventRepository events;

    @Mock
    private venueRepository venues;

    @Mock
    private userAccountRepository users;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private EventService eventService;

    private final LocalDate nextWeek = LocalDate.now().plusDays(7);

    private Venue venue() {
        return new Venue("Gym", "Main Building", 100);
    }

    private userAccount organizer() {
        return new userAccount("org", "hash", "Ana", "Cruz", null, null);
    }

    private Event eventWithStatus(String status) {
        return new Event("Assembly", null, nextWeek, LocalTime.of(9, 0), LocalTime.of(11, 0),
                status, organizer(), venue());
    }

    private EventRequest request(LocalDate date, LocalTime start, LocalTime end) {
        return new EventRequest("Assembly", "Welcome", date, start, end, 1);
    }

    @Test
    void create_rejectsEndBeforeStart() {
        assertThrows(InvalidRequestException.class, () -> eventService.create(
                request(nextWeek, LocalTime.of(15, 0), LocalTime.of(14, 0)), 5));

        verify(events, never()).saveAndFlush(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_rejectsPastDate() {
        assertThrows(InvalidRequestException.class, () -> eventService.create(
                request(LocalDate.now().minusDays(1), LocalTime.of(9, 0), LocalTime.of(10, 0)), 5));

        verify(events, never()).saveAndFlush(any());
    }

    @Test
    void create_rejectsOverlappingVenueBooking() {
        when(venues.findById(1)).thenReturn(Optional.of(venue()));
        when(users.findById(5)).thenReturn(Optional.of(organizer()));
                // The fake venue has no database id (null), so match any venue id.
        when(events.countVenueConflicts(any(), eq(nextWeek), any(LocalTime.class),
                any(LocalTime.class), eq(0))).thenReturn(1L);

        assertThrows(DuplicateResourceException.class, () -> eventService.create(
                request(nextWeek, LocalTime.of(10, 0), LocalTime.of(12, 0)), 5));

        verify(events, never()).saveAndFlush(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void create_startsAsUpcoming_andWritesAuditEntry() {
        when(venues.findById(1)).thenReturn(Optional.of(venue()));
        when(users.findById(5)).thenReturn(Optional.of(organizer()));
        when(events.saveAndFlush(any(Event.class))).thenAnswer(call -> call.getArgument(0));

        EventResponse response = eventService.create(
                request(nextWeek, LocalTime.of(9, 0), LocalTime.of(11, 0)), 5);

        assertEquals("Upcoming", response.eventStatus());
        assertEquals("Ana Cruz", response.organizerName());
        verify(auditService).log(eq(AuditAction.CREATED), eq("event"), any());
    }

    @Test
    void changeStatus_allowsUpcomingToOngoing_andWritesAuditEntry() {
        when(events.findById(1)).thenReturn(Optional.of(eventWithStatus("Upcoming")));
        when(events.save(any(Event.class))).thenAnswer(call -> call.getArgument(0));

        EventResponse response = eventService.changeStatus(1, "Ongoing");

        assertEquals("Ongoing", response.eventStatus());
        verify(auditService).log(eq(AuditAction.UPDATED), eq("event"), any());
    }

    @Test
    void changeStatus_rejectsLeavingCompleted() {
        when(events.findById(1)).thenReturn(Optional.of(eventWithStatus("Completed")));

        assertThrows(InvalidRequestException.class, () -> eventService.changeStatus(1, "Upcoming"));

        verify(events, never()).save(any());
        verify(auditService, never()).log(any(), any(), any());
    }

    @Test
    void update_rejectsCompletedEvent() {
        when(events.findById(2)).thenReturn(Optional.of(eventWithStatus("Completed")));

        assertThrows(InvalidRequestException.class, () -> eventService.update(2,
                request(nextWeek, LocalTime.of(9, 0), LocalTime.of(11, 0))));

        verify(auditService, never()).log(any(), any(), any());
    }
}