package com.school_event.school_event_management.dto;

import com.school_event.school_event_management.entity.Venue;

public record VenueResponse(
        Integer venueId,
        String venueName,
        String location,
        Integer capacity) {

    public static VenueResponse from(Venue venue) {
        return new VenueResponse(
                venue.getVenueId(),
                venue.getVenueName(),
                venue.getLocation(),
                venue.getCapacity());
    }
}