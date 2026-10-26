package com.school_event.school_event_management.dto;

import java.util.List;

public record DashboardResponse(
        EventCounts events,
        UserCounts users,
        long venues,
        long participants,
        AttendanceTotals attendance,
        List<EventResponse> upcomingEvents,
        List<AuditLogResponse> recentActivity) {

    public record EventCounts(long upcoming, long ongoing, long completed, long cancelled, long total) {
    }

    public record UserCounts(long active, long inactive, long suspended, long total) {
    }

    public record AttendanceTotals(long present, long late, long absent, long total) {
    }
}