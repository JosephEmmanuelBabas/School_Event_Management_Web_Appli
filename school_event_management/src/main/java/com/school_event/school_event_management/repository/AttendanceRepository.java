package com.school_event.school_event_management.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.school_event.school_event_management.dto.AttendanceByEventRow;
import com.school_event.school_event_management.dto.AttendanceByGradeRow;
import com.school_event.school_event_management.entity.Attendance;

public interface AttendanceRepository extends JpaRepository<Attendance, Integer> {

    // status "" = any status. Participants load in the same query.
    @Query("""
            select a from Attendance a
              join fetch a.participant p
            where a.event.eventId = :eventId
              and (:status = '' or a.attendanceStatus = :status)
            order by p.lastName, p.firstName, a.attendanceId
            """)
    List<Attendance> findForEvent(@Param("eventId") Integer eventId, @Param("status") String status);

    // The event id in the lookup stops one event from touching another event's records.
    Optional<Attendance> findByAttendanceIdAndEvent_EventId(Integer attendanceId, Integer eventId);

    boolean existsByEvent_EventIdAndParticipant_ParticipantId(Integer eventId, Integer participantId);

    long countByEvent_EventIdAndAttendanceStatus(Integer eventId, String attendanceStatus);

    long countByAttendanceStatus(String attendanceStatus);

    // One row per event, including events with no attendance yet (left join, counts are 0).
    // venueId 0 = any venue, status "" = any event status.
    @Query("""
            select new com.school_event.school_event_management.dto.AttendanceByEventRow(
                e.eventId, e.eventName, e.eventDate, v.venueName, e.eventStatus,
                sum(case when a.attendanceStatus = 'Present' then 1L else 0L end),
                sum(case when a.attendanceStatus = 'Late' then 1L else 0L end),
                sum(case when a.attendanceStatus = 'Absent' then 1L else 0L end))
            from Event e
              join e.venue v
              left join Attendance a on a.event = e
            where e.eventDate >= :fromDate
              and e.eventDate <= :toDate
              and (:venueId = 0 or v.venueId = :venueId)
              and (:status = '' or e.eventStatus = :status)
            group by e.eventId, e.eventName, e.eventDate, v.venueName, e.eventStatus
            order by e.eventDate desc, e.eventId desc
            """)
    List<AttendanceByEventRow> reportByEvent(@Param("fromDate") LocalDate fromDate,
                                             @Param("toDate") LocalDate toDate,
                                             @Param("venueId") Integer venueId,
                                             @Param("status") String status);

    // One row per grade level. Students without a grade come back with a null grade.
    @Query("""
            select new com.school_event.school_event_management.dto.AttendanceByGradeRow(
                p.gradeLevel,
                sum(case when a.attendanceStatus = 'Present' then 1L else 0L end),
                sum(case when a.attendanceStatus = 'Late' then 1L else 0L end),
                sum(case when a.attendanceStatus = 'Absent' then 1L else 0L end))
            from Attendance a
              join a.participant p
              join a.event e
            where e.eventDate >= :fromDate
              and e.eventDate <= :toDate
            group by p.gradeLevel
            """)
    List<AttendanceByGradeRow> reportByGrade(@Param("fromDate") LocalDate fromDate,
                                             @Param("toDate") LocalDate toDate);
}