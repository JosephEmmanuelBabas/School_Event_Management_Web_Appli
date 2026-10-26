package com.school_event.school_event_management.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.school_event.school_event_management.entity.EventAssignment;

public interface EventAssignmentRepository extends JpaRepository<EventAssignment, Integer> {

    List<EventAssignment> findByEvent_EventIdOrderByStaffNameAscAssignmentIdAsc(Integer eventId);

    Optional<EventAssignment> findByAssignmentIdAndEvent_EventId(Integer assignmentId, Integer eventId);
}