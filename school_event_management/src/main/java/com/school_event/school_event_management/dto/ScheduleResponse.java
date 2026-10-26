package com.school_event.school_event_management.dto;

import java.time.LocalTime;

import com.school_event.school_event_management.entity.EventSchedule;

public record ScheduleResponse(
        Integer scheduleId,
        Integer eventId,
        String activityName,
        LocalTime startTime,
        LocalTime endTime) {

    // Call this inside a service transaction (the event loads lazily).
    public static ScheduleResponse from(EventSchedule schedule) {
        return new ScheduleResponse(
                schedule.getScheduleId(),
                schedule.getEvent().getEventId(),
                schedule.getActivityName(),
                schedule.getStartTime(),
                schedule.getEndTime());
    }
}