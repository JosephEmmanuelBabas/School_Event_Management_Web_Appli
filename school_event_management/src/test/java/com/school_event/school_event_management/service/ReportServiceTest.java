package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.LocalDate;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.school_event.school_event_management.dto.AttendanceByEventRow;
import com.school_event.school_event_management.dto.AttendanceByGradeRow;
import com.school_event.school_event_management.dto.AttendanceReportResponse;
import com.school_event.school_event_management.dto.GradeAttendanceResponse;
import com.school_event.school_event_management.exception.InvalidRequestException;
import com.school_event.school_event_management.repository.AttendanceRepository;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock
    private AttendanceRepository attendance;

    @InjectMocks
    private ReportService reportService;

    private final LocalDate day = LocalDate.of(2027, 1, 15);

    @Test
    void attendanceByEvent_addsTotalAndRate() {
        when(attendance.reportByEvent(any(LocalDate.class), any(LocalDate.class), eq(0), eq("")))
                .thenReturn(List.of(new AttendanceByEventRow(
                        1, "Assembly", day, "Gym", "Completed", 6L, 2L, 2L)));

        List<AttendanceReportResponse> rows = reportService.attendanceByEvent(null, null, null, null);

        assertEquals(1, rows.size());
        assertEquals(10, rows.get(0).totalRecorded());
        assertEquals(80.0, rows.get(0).attendanceRatePercent(), 0.001);
    }

    @Test
    void attendanceByEvent_rateIsNullWhenNothingIsRecorded() {
        when(attendance.reportByEvent(any(LocalDate.class), any(LocalDate.class), eq(0), eq("")))
                .thenReturn(List.of(new AttendanceByEventRow(
                        2, "Quiet event", day, "Gym", "Upcoming", 0L, 0L, 0L)));

        List<AttendanceReportResponse> rows = reportService.attendanceByEvent(null, null, null, null);

        assertEquals(0, rows.get(0).totalRecorded());
        assertNull(rows.get(0).attendanceRatePercent());
    }

    @Test
    void attendanceByEvent_rejectsAReversedDateRange() {
        assertThrows(InvalidRequestException.class, () -> reportService.attendanceByEvent(
                LocalDate.of(2027, 2, 1), LocalDate.of(2027, 1, 1), null, null));

        verify(attendance, never()).reportByEvent(any(), any(), any(), any());
    }

    @Test
    void attendanceByGrade_labelsMissingGrade_andSortsNumerically() {
        when(attendance.reportByGrade(any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(List.of(
                        new AttendanceByGradeRow("10", 1L, 0L, 0L),
                        new AttendanceByGradeRow(null, 1L, 1L, 0L),
                        new AttendanceByGradeRow("9", 2L, 0L, 0L)));

        List<GradeAttendanceResponse> rows = reportService.attendanceByGrade(null, null);

        assertEquals("9", rows.get(0).gradeLevel());
        assertEquals("10", rows.get(1).gradeLevel());
        assertEquals("Unspecified", rows.get(2).gradeLevel());
        assertEquals(2, rows.get(2).totalRecorded());
    }
}