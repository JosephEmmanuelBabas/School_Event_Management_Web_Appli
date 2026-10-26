package com.school_event.school_event_management.service;

import com.school_event.school_event_management.entity.Event;
import com.school_event.school_event_management.exception.InvalidRequestException;

// Completed and cancelled events are frozen: their schedule and staff stay readable only.
final class EventLock {

    private EventLock() {
    }

    static void ensureOpen(Event event) {
        String status = event.getEventStatus();
        if (!"Upcoming".equals(status) && !"Ongoing".equals(status)) {
            throw new InvalidRequestException(
                    "The schedule and staff of a " + status.toLowerCase() + " event cannot be changed.");
        }
    }
}