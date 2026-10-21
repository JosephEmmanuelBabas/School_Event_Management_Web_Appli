package com.school_event.school_event_management.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.school_event.school_event_management.entity.Venue;

public interface venueRepository extends JpaRepository<Venue, Integer> {

    // Exact match, because the database rule on venue_name is case-sensitive.
    boolean existsByVenueName(String venueName);

    // Used by updates: another venue (different id) already has this name.
    boolean existsByVenueNameAndVenueIdNot(String venueName, Integer venueId);
}