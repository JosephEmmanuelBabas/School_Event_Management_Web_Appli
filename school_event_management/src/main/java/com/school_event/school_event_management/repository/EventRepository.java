package com.school_event.school_event_management.repository;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.school_event.school_event_management.entity.Event;

public interface EventRepository extends JpaRepository<Event, Integer> {

    // Counts non-cancelled events at the same venue and date whose time range
    // overlaps [startTime, endTime). Back-to-back events do not overlap.
    // Pass excludeEventId = 0 when creating (ids start at 1).
    @Query("""
            select count(e) from Event e
            where e.venue.venueId = :venueId
              and e.eventDate = :eventDate
              and e.eventStatus <> 'Cancelled'
              and e.startTime < :endTime
              and e.endTime > :startTime
              and e.eventId <> :excludeEventId
            """)
    long countVenueConflicts(@Param("venueId") Integer venueId,
                             @Param("eventDate") LocalDate eventDate,
                             @Param("startTime") LocalTime startTime,
                             @Param("endTime") LocalTime endTime,
                             @Param("excludeEventId") Integer excludeEventId);

    // status "" = any, venueId 0 = any, search "" = any.
    @Query("""
            select e from Event e
              join fetch e.venue v
              join fetch e.organizer o
            where (:status = '' or e.eventStatus = :status)
              and (:venueId = 0 or v.venueId = :venueId)
              and e.eventDate >= :fromDate
              and e.eventDate <= :toDate
              and (:search = '' or lower(e.eventName) like lower(concat('%', :search, '%')))
            """)
    List<Event> search(@Param("status") String status,
                       @Param("venueId") Integer venueId,
                       @Param("fromDate") LocalDate fromDate,
                       @Param("toDate") LocalDate toDate,
                       @Param("search") String search,
                       Pageable pageable);
    
    long countByEventStatus(String eventStatus);

    // The next upcoming events from today onward. Venue and organizer load in the same query.
    @Query("""
            select e from Event e
              join fetch e.venue
              join fetch e.organizer
            where e.eventStatus = 'Upcoming'
              and e.eventDate >= :today
            """)
    List<Event> findUpcoming(@Param("today") LocalDate today, Pageable pageable); 
}