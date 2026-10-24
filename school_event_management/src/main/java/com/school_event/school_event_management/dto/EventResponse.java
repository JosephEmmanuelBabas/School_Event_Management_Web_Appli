package com.school_event.school_event_management.dto;

import java.time.LocalDate;
import java.time.LocalTime;

import com.school_event.school_event_management.entity.Event;

public record EventResponse(
        Integer eventId,
        String eventName,
        String description,
        LocalDate eventDate,
        LocalTime startTime,
        LocalTime endTime,
        String eventStatus,
        Integer organizerId,
        String organizerName,
        Integer venueId,
        String venueName) {

    // Call this inside a service transaction: organizer and venue load lazily.
    public static EventResponse from(Event event) {
        return new EventResponse(
                event.getEventId(),
                event.getEventName(),
                event.getDescription(),
                event.getEventDate(),
                event.getStartTime(),
                event.getEndTime(),
                event.getEventStatus(),
                event.getOrganizer().getUserId(),
                event.getOrganizer().getFirstName() + " " + event.getOrganizer().getLastName(),
                event.getVenue().getVenueId(),
                event.getVenue().getVenueName());
    }
}