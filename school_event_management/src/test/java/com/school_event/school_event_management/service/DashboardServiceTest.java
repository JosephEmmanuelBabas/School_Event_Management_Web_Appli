package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.DashboardResponse;
import com.school_event.school_event_management.repository.AttendanceRepository;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.ParticipantRepository;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.repository.venueRepository;

@ExtendWith(MockitoExtension.class)
class DashboardServiceTest {

    @Mock
    private EventRepository events;

    @Mock
    private userAccountRepository users;

    @Mock
    private venueRepository venues;

    @Mock
    private ParticipantRepository participants;

    @Mock
    private AttendanceRepository attendance;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private DashboardService dashboardService;

    @Test
    void get_assemblesTheNumbersFromTheRepositories() {
        when(events.countByEventStatus("Upcoming")).thenReturn(4L);
        when(events.countByEventStatus("Ongoing")).thenReturn(1L);
        when(events.countByEventStatus("Completed")).thenReturn(10L);
        when(events.countByEventStatus("Cancelled")).thenReturn(2L);
        when(users.countByAccountStatus("Active")).thenReturn(3L);
        when(users.countByAccountStatus("Inactive")).thenReturn(2L);
        when(users.countByAccountStatus("Suspended")).thenReturn(0L);
        when(venues.count()).thenReturn(5L);
        when(participants.count()).thenReturn(120L);
        when(attendance.countByAttendanceStatus("Present")).thenReturn(80L);
        when(attendance.countByAttendanceStatus("Late")).thenReturn(10L);
        when(attendance.countByAttendanceStatus("Absent")).thenReturn(20L);
        when(events.findUpcoming(any(LocalDate.class), any(Pageable.class))).thenReturn(List.of());
        when(auditService.findRecent(0, 5)).thenReturn(List.of());

        DashboardResponse dashboard = dashboardService.get();

        assertEquals(17, dashboard.events().total());
        assertEquals(10, dashboard.events().completed());
        assertEquals(5, dashboard.users().total());
        assertEquals(5, dashboard.venues());
        assertEquals(120, dashboard.participants());
        assertEquals(110, dashboard.attendance().total());
    }
}