package com.school_event.school_event_management.controller;

import java.net.URI;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.AttendanceRequest;
import com.school_event.school_event_management.dto.AttendanceResponse;
import com.school_event.school_event_management.dto.AttendanceSummaryResponse;
import com.school_event.school_event_management.dto.AttendanceUpdateRequest;
import com.school_event.school_event_management.service.AttendanceService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/events/{eventId}/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    @GetMapping
    public List<AttendanceResponse> list(@PathVariable Integer eventId,
                                         @RequestParam(required = false) String status) {
        return attendanceService.list(eventId, status);
    }

    @GetMapping("/summary")
    public AttendanceSummaryResponse summary(@PathVariable Integer eventId) {
        return attendanceService.summary(eventId);
    }

    @PostMapping
    public ResponseEntity<AttendanceResponse> record(@PathVariable Integer eventId,
                                                     @Valid @RequestBody AttendanceRequest request) {
        AttendanceResponse created = attendanceService.record(eventId, request);
        return ResponseEntity
                .created(URI.create("/api/events/" + eventId + "/attendance/" + created.attendanceId()))
                .body(created);
    }

    @PutMapping("/{attendanceId}")
    public AttendanceResponse changeStatus(@PathVariable Integer eventId,
                                           @PathVariable Integer attendanceId,
                                           @Valid @RequestBody AttendanceUpdateRequest request) {
        return attendanceService.changeStatus(eventId, attendanceId, request);
    }

    @DeleteMapping("/{attendanceId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer eventId, @PathVariable Integer attendanceId) {
        attendanceService.delete(eventId, attendanceId);
    }
}