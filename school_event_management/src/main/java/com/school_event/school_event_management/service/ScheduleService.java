package com.school_event.school_event_management.service;

import java.time.LocalTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.ScheduleRequest;
import com.school_event.school_event_management.dto.ScheduleResponse;
import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.entity.EventSchedule;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.EventRepository;
import com.school_event.school_event_management.repository.EventScheduleRepository;

@Service
public class ScheduleService {

    private static final String AUDIT_TABLE = "event_schedule";

    private final EventRepository events;
    private final EventScheduleRepository schedules;
    private final AuditService auditService;

    public ScheduleService(EventRepository events, EventScheduleRepository schedules,
                           AuditService auditService) {
        this.events = events;
        this.schedules = schedules;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public List<ScheduleResponse> list(Integer eventId) {
        if (!events.existsById(eventId)) {
            throw new ResourceNotFoundException("Event", eventId);
        }
        return schedules.findByEvent_EventIdOrderByStartTimeAscScheduleIdAsc(eventId)
                .stream()
                .map(ScheduleResponse::from)
                .toList();
    }

    @Transactional
    public ScheduleResponse create(Integer eventId, ScheduleRequest request) {
        Event event = getOpenEvent(eventId);
        validateWithinEvent(event, request.startTime(), request.endTime());

        EventSchedule saved = schedules.save(new EventSchedule(
                event, request.activityName().trim(), request.startTime(), request.endTime()));
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getScheduleId());
        return ScheduleResponse.from(saved);
    }

    @Transactional
    public ScheduleResponse update(Integer eventId, Integer scheduleId, ScheduleRequest request) {
        Event event = getOpenEvent(eventId);
        EventSchedule schedule = getEntryOrThrow(scheduleId, eventId);
        validateWithinEvent(event, request.startTime(), request.endTime());

        schedule.setActivityName(request.activityName().trim());
        schedule.setStartTime(request.startTime());
        schedule.setEndTime(request.endTime());
        EventSchedule saved = schedules.save(schedule);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getScheduleId());
        return ScheduleResponse.from(saved);
    }

    @Transactional
    public void delete(Integer eventId, Integer scheduleId) {
        getOpenEvent(eventId);
        EventSchedule schedule = getEntryOrThrow(scheduleId, eventId);
        schedules.delete(schedule);
        auditService.log(AuditAction.DELETED, AUDIT_TABLE, scheduleId);
    }

    // ---- helpers ----

    private Event getOpenEvent(Integer eventId) {
        Event event = events.findById(eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Event", eventId));
        EventLock.ensureOpen(event);
        return event;
    }

    private EventSchedule getEntryOrThrow(Integer scheduleId, Integer eventId) {
        return schedules.findByScheduleIdAndEvent_EventId(scheduleId, eventId)
                .orElseThrow(() -> new ResourceNotFoundException("Schedule entry", scheduleId));
    }

    private static void validateWithinEvent(Event event, LocalTime start, LocalTime end) {
        if (!end.isAfter(start)) {
            throw new InvalidRequestException("End time must be after start time.");
        }
        if (start.isBefore(event.getStartTime()) || end.isAfter(event.getEndTime())) {
            throw new InvalidRequestException("The activity must fall within the event's time ("
                    + event.getStartTime() + " to " + event.getEndTime() + ").");
        }
    }
}