package com.school_event.school_event_management.service;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.AuditLogResponse;
import com.school_event.school_event_management.dto.DashboardResponse;
import com.school_event.school_event_management.dto.DashboardResponse.AttendanceTotals;
import com.school_event.school_event_management.dto.DashboardResponse.EventCounts;
import com.school_event.school_event_management.dto.DashboardResponse.UserCounts;
import com.school_event.school_event_management.dto.EventResponse;
import com.school_event.school_event_management.repository.AttendanceRepository;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.ParticipantRepository;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.repository.venueRepository;

@Service
public class DashboardService {

    private static final int LIST_SIZE = 5;

    private final EventRepository events;
    private final userAccountRepository users;
    private final venueRepository venues;
    private final ParticipantRepository participants;
    private final AttendanceRepository attendance;
    private final AuditService auditService;

    public DashboardService(EventRepository events, userAccountRepository users,
                            venueRepository venues, ParticipantRepository participants,
                            AttendanceRepository attendance, AuditService auditService) {
        this.events = events;
        this.users = users;
        this.venues = venues;
        this.participants = participants;
        this.attendance = attendance;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public DashboardResponse get() {
        long upcoming = events.countByEventStatus("Upcoming");
        long ongoing = events.countByEventStatus("Ongoing");
        long completed = events.countByEventStatus("Completed");
        long cancelled = events.countByEventStatus("Cancelled");

        long active = users.countByAccountStatus("Active");
        long inactive = users.countByAccountStatus("Inactive");
        long suspended = users.countByAccountStatus("Suspended");

        long present = attendance.countByAttendanceStatus("Present");
        long late = attendance.countByAttendanceStatus("Late");
        long absent = attendance.countByAttendanceStatus("Absent");

        List<EventResponse> nextEvents = events
                .findUpcoming(LocalDate.now(),
                        PageRequest.of(0, LIST_SIZE, Sort.by("eventDate", "startTime")))
                .stream()
                .map(EventResponse::from)
                .toList();
        List<AuditLogResponse> recentActivity = auditService.findRecent(0, LIST_SIZE);

        return new DashboardResponse(
                new EventCounts(upcoming, ongoing, completed, cancelled,
                        upcoming + ongoing + completed + cancelled),
                new UserCounts(active, inactive, suspended, active + inactive + suspended),
                venues.count(),
                participants.count(),
                new AttendanceTotals(present, late, absent, present + late + absent),
                nextEvents,
                recentActivity);
    }
}