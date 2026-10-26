package com.school_event.school_event_management.repository;

import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.school_event.school_event_management.entity.EventSchedule;

public interface EventScheduleRepository extends JpaRepository<EventSchedule, Integer> {

    List<EventSchedule> findByEvent_EventIdOrderByStartTimeAscScheduleIdAsc(Integer eventId);

    // The event id in the lookup stops one event from touching another event's entries.
    Optional<EventSchedule> findByScheduleIdAndEvent_EventId(Integer scheduleId, Integer eventId);

    // How many of the event's entries start before, or end after, the given window.
    @Query("""
            select count(s) from EventSchedule s
            where s.event.eventId = :eventId
              and (s.startTime < :startTime or s.endTime > :endTime)
            """)
    long countOutsideWindow(@Param("eventId") Integer eventId,
                            @Param("startTime") LocalTime startTime,
                            @Param("endTime") LocalTime endTime);
}