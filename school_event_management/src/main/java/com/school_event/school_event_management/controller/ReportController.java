package com.school_event.school_event_management.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.AttendanceReportResponse;
import com.school_event.school_event_management.dto.GradeAttendanceResponse;
import com.school_event.school_event_management.service.ReportService;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/attendance-by-event")
    public List<AttendanceReportResponse> attendanceByEvent(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) Integer venueId,
            @RequestParam(required = false) String status) {
        return reportService.attendanceByEvent(from, to, venueId, status);
    }

    @GetMapping("/attendance-by-grade")
    public List<GradeAttendanceResponse> attendanceByGrade(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return reportService.attendanceByGrade(from, to);
    }
}