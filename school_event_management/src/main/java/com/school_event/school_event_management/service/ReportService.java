package com.school_event.school_event_management.service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.dto.AttendanceByEventRow;
import com.school_event.school_event_management.dto.AttendanceByGradeRow;
import com.school_event.school_event_management.dto.AttendanceReportResponse;
import com.school_event.school_event_management.dto.GradeAttendanceResponse;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.AttendanceRepository;

@Service
public class ReportService {

    private static final Set<String> EVENT_STATUSES =
            Set.of("Upcoming", "Ongoing", "Completed", "Cancelled");
    private static final LocalDate MIN_DATE = LocalDate.of(1900, 1, 1);
    private static final LocalDate MAX_DATE = LocalDate.of(9999, 12, 31);
    private static final String UNSPECIFIED = "Unspecified";

    // Numeric grades first (9 before 10), anything else after, alphabetically.
    private static final Comparator<GradeAttendanceResponse> GRADE_ORDER = Comparator
            .comparingInt((GradeAttendanceResponse r) -> gradeNumber(r.gradeLevel()))
            .thenComparing(GradeAttendanceResponse::gradeLevel);

    private final AttendanceRepository attendance;

    public ReportService(AttendanceRepository attendance) {
        this.attendance = attendance;
    }

    @Transactional(readOnly = true)
    public List<AttendanceReportResponse> attendanceByEvent(LocalDate from, LocalDate to,
                                                            Integer venueId, String status) {
        checkRange(from, to);
        String statusFilter = (status == null || status.isBlank()) ? "" : status.trim();
        if (!statusFilter.isEmpty() && !EVENT_STATUSES.contains(statusFilter)) {
            throw new InvalidRequestException("Unknown event status: '" + statusFilter + "'.");
        }
        return attendance.reportByEvent(
                        from == null ? MIN_DATE : from,
                        to == null ? MAX_DATE : to,
                        venueId == null ? 0 : venueId,
                        statusFilter)
                .stream()
                .map(ReportService::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<GradeAttendanceResponse> attendanceByGrade(LocalDate from, LocalDate to) {
        checkRange(from, to);
        return attendance.reportByGrade(from == null ? MIN_DATE : from, to == null ? MAX_DATE : to)
                .stream()
                .map(ReportService::toResponse)
                .sorted(GRADE_ORDER)
                .toList();
    }

    // ---- helpers ----

    private static void checkRange(LocalDate from, LocalDate to) {
        if (from != null && to != null && to.isBefore(from)) {
            throw new InvalidRequestException("The 'to' date cannot be before the 'from' date.");
        }
    }

    private static AttendanceReportResponse toResponse(AttendanceByEventRow row) {
        long present = orZero(row.present());
        long late = orZero(row.late());
        long absent = orZero(row.absent());
        long total = present + late + absent;
        return new AttendanceReportResponse(row.eventId(), row.eventName(), row.eventDate(),
                row.venueName(), row.eventStatus(), present, late, absent, total,
                rate(present, late, total));
    }

    private static GradeAttendanceResponse toResponse(AttendanceByGradeRow row) {
        long present = orZero(row.present());
        long late = orZero(row.late());
        long absent = orZero(row.absent());
        long total = present + late + absent;
        String grade = (row.gradeLevel() == null || row.gradeLevel().isBlank())
                ? UNSPECIFIED : row.gradeLevel();
        return new GradeAttendanceResponse(grade, present, late, absent, total,
                rate(present, late, total));
    }

    // Percent of recorded attendance that was Present or Late, to one decimal place.
    private static Double rate(long present, long late, long total) {
        if (total == 0) {
            return null;
        }
        return Math.round((present + late) * 1000.0 / total) / 10.0;
    }

    private static long orZero(Long value) {
        return value == null ? 0L : value;
    }

    private static int gradeNumber(String grade) {
        try {
            return Integer.parseInt(grade.trim());
        } catch (NumberFormatException ex) {
            return Integer.MAX_VALUE;
        }
    }
}