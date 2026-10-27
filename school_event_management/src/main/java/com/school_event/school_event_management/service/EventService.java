package com.school_event.school_event_management.service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.EventRequest;
import com.school_event.school_event_management.dto.EventResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.Venue;
import com.school_event.school_event_management.entity.userAccount;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.userAccountRepository;
import com.school_event.school_event_management.repository.venueRepository;
import com.school_event.school_event_management.repository.EventScheduleRepository;
import com.school_event.school_event_management.dto.PageResult;

@Service
public class EventService {

    private static final String AUDIT_TABLE = "event";

    private static final String UPCOMING = "Upcoming";
    private static final String ONGOING = "Ongoing";
    private static final String COMPLETED = "Completed";
    private static final String CANCELLED = "Cancelled";

    private static final Set<String> STATUSES = Set.of(UPCOMING, ONGOING, COMPLETED, CANCELLED);

    // Allowed status changes. Completed and Cancelled are final.
    private static final Map<String, Set<String>> TRANSITIONS = Map.of(
            UPCOMING, Set.of(ONGOING, CANCELLED),
            ONGOING, Set.of(COMPLETED, CANCELLED));

    private static final Set<String> SORT_FIELDS = Set.of("eventDate", "eventName", "eventStatus");

    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);

    private static final String VENUE_BOOKED =
            "The venue is already booked for an overlapping time on that date.";

    private final EventRepository events;
    private final EventScheduleRepository schedules;
    private final venueRepository venues;
    private final userAccountRepository users;
    private final AuditService auditService;

    public EventService(EventRepository events, EventScheduleRepository schedules,
                        venueRepository venues, userAccountRepository users,
                        AuditService auditService) {
        this.events = events;
        this.schedules = schedules;
        this.venues = venues;
        this.users = users;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public PageResult<EventResponse> search(String status, Integer venueId, String search,
                                            LocalDate from, LocalDate to,
                                            int page, int size, String sort, String direction) {
        String statusFilter = (status == null || status.isBlank()) ? "" : status.trim();
        if (!statusFilter.isEmpty() && !STATUSES.contains(statusFilter)) {
            throw new InvalidRequestException("Unknown status: '" + statusFilter + "'.");
        }
        if (from != null && to != null && to.isBefore(from)) {
            throw new InvalidRequestException("The 'to' date cannot be before the 'from' date.");
        }
        String sortField = (sort != null && SORT_FIELDS.contains(sort)) ? sort : "eventDate";
        Sort.Direction dir = "asc".equalsIgnoreCase(direction) ? Sort.Direction.ASC : Sort.Direction.DESC;
        Sort ordering = Sort.by(dir, sortField).and(Sort.by(dir, "startTime"));

        Integer venueFilter = venueId == null ? 0 : venueId;
        LocalDate fromDate = from == null ? MIN_DATE : from;
        LocalDate toDate = to == null ? MAX_DATE : to;
        String searchText = search == null ? "" : search.trim();

        List<EventResponse> items = events
                .search(statusFilter, venueFilter, fromDate, toDate, searchText,
                        PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100), ordering))
                .stream()
                .map(EventResponse::from)
                .toList();
        long total = events.countSearch(statusFilter, venueFilter, fromDate, toDate, searchText);
        return new PageResult<>(items, total);
    }

    @Transactional(readOnly = true)
    public EventResponse findById(Integer id) {
        return EventResponse.from(getOrThrow(id));
    }

    @Transactional
    public EventResponse create(EventRequest request, Integer organizerId) {
        validateTimes(request.startTime(), request.endTime());
        if (request.eventDate().isBefore(LocalDate.now())) {
            throw new InvalidRequestException("Event date cannot be in the past.");
        }
        
        Venue venue = findVenue(request.venueId());
        userAccount organizer = users.findById(organizerId)
                .orElseThrow(() -> new ResourceNotFoundException("User", organizerId));
        ensureVenueFree(venue.getVenueId(), request.eventDate(),
                request.startTime(), request.endTime(), 0);

        Event event = new Event(
                request.eventName().trim(),
                normalize(request.description()),
                request.eventDate(),
                request.startTime(),
                request.endTime(),
                UPCOMING,
                organizer,
                venue);
        Event saved = saveAndFlushChecked(event);
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getEventId());
        return EventResponse.from(saved);
    }

    @Transactional
    public EventResponse update(Integer id, EventRequest request) {
        Event event = getOrThrow(id);
        if (!UPCOMING.equals(event.getEventStatus()) && !ONGOING.equals(event.getEventStatus())) {
            throw new InvalidRequestException("Completed or cancelled events cannot be edited.");
        }
        validateTimes(request.startTime(), request.endTime());
        if (!request.eventDate().equals(event.getEventDate())
                && request.eventDate().isBefore(LocalDate.now())) {
            throw new InvalidRequestException("Event date cannot be moved into the past.");
        }
        
        if (schedules.countOutsideWindow(id, request.startTime(), request.endTime()) > 0) {
            throw new InvalidRequestException(
                    "Some schedule entries fall outside the new start and end time. "
                            + "Adjust or remove them first.");
        }
        Venue venue = findVenue(request.venueId());
        ensureVenueFree(venue.getVenueId(), request.eventDate(),
                request.startTime(), request.endTime(), id);

        event.setEventName(request.eventName().trim());
        event.setDescription(normalize(request.description()));
        event.setEventDate(request.eventDate());
        event.setStartTime(request.startTime());
        event.setEndTime(request.endTime());
        event.setVenue(venue);
        Event saved = saveAndFlushChecked(event);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getEventId());
        return EventResponse.from(saved);
    }

    @Transactional
    public EventResponse changeStatus(Integer id, String newStatus) {
        Event event = getOrThrow(id);
        String current = event.getEventStatus();
        if (!TRANSITIONS.getOrDefault(current, Set.of()).contains(newStatus)) {
            throw new InvalidRequestException(
                    "An event cannot change from " + current + " to " + newStatus + ".");
        }
        event.setEventStatus(newStatus);
        Event saved = events.save(event);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getEventId());
        return EventResponse.from(saved);
    }

    @Transactional
    public void delete(Integer id) {
        Event event = getOrThrow(id);
        events.delete(event);
        try {
            // Force the DELETE now so a foreign-key refusal is caught here.
            events.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new DuplicateResourceException(
                    "This event has attendance records and cannot be deleted. Cancel it instead.");
        }
        auditService.log(AuditAction.DELETED, AUDIT_TABLE, id);
    }

    // ---- helpers ----

    private Event getOrThrow(Integer id) {
        return events.findById(id).orElseThrow(() -> new ResourceNotFoundException("Event", id));
    }

    private Venue findVenue(Integer venueId) {
        // A bad venue id in a request body is a client error (400), not a missing page (404).
        return venues.findById(venueId)
                .orElseThrow(() -> new InvalidRequestException("Venue " + venueId + " does not exist."));
    }

    private static void validateTimes(LocalTime start, LocalTime end) {
        if (!end.isAfter(start)) {
            throw new InvalidRequestException("End time must be after start time.");
        }
    }

    private void ensureVenueFree(Integer venueId, LocalDate date, LocalTime start,
                                 LocalTime end, Integer excludeEventId) {
        if (events.countVenueConflicts(venueId, date, start, end, excludeEventId) > 0) {
            throw new DuplicateResourceException(VENUE_BOOKED);
        }
    }

    // Safety net: if two requests race past the check above, the database
    // exclusion constraint refuses the second one and we report the same conflict.
    private Event saveAndFlushChecked(Event event) {
        try {
            return events.saveAndFlush(event);
        } catch (DataIntegrityViolationException ex) {
            throw new DuplicateResourceException(VENUE_BOOKED);
        }
    }

    private static String normalize(String text) {
        return (text == null || text.isBlank()) ? null : text.trim();
    }
}