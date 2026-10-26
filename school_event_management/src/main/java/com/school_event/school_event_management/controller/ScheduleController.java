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
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.ScheduleRequest;
import com.school_event.school_event_management.dto.ScheduleResponse;
import com.school_event.school_event_management.service.ScheduleService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/events/{eventId}/schedules")
public class ScheduleController {

    private final ScheduleService scheduleService;

    public ScheduleController(ScheduleService scheduleService) {
        this.scheduleService = scheduleService;
    }

    @GetMapping
    public List<ScheduleResponse> list(@PathVariable Integer eventId) {
        return scheduleService.list(eventId);
    }

    @PostMapping
    public ResponseEntity<ScheduleResponse> create(@PathVariable Integer eventId,
                                                   @Valid @RequestBody ScheduleRequest request) {
        ScheduleResponse created = scheduleService.create(eventId, request);
        return ResponseEntity
                .created(URI.create("/api/events/" + eventId + "/schedules/" + created.scheduleId()))
                .body(created);
    }

    @PutMapping("/{scheduleId}")
    public ScheduleResponse update(@PathVariable Integer eventId, @PathVariable Integer scheduleId,
                                   @Valid @RequestBody ScheduleRequest request) {
        return scheduleService.update(eventId, scheduleId, request);
    }

    @DeleteMapping("/{scheduleId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer eventId, @PathVariable Integer scheduleId) {
        scheduleService.delete(eventId, scheduleId);
    }
}