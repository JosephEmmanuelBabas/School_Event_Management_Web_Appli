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

import com.school_event.school_event_management.dto.AssignmentRequest;
import com.school_event.school_event_management.dto.AssignmentResponse;
import com.school_event.school_event_management.service.AssignmentService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/events/{eventId}/assignments")
public class AssignmentController {

    private final AssignmentService assignmentService;

    public AssignmentController(AssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping
    public List<AssignmentResponse> list(@PathVariable Integer eventId) {
        return assignmentService.list(eventId);
    }

    @PostMapping
    public ResponseEntity<AssignmentResponse> create(@PathVariable Integer eventId,
                                                     @Valid @RequestBody AssignmentRequest request) {
        AssignmentResponse created = assignmentService.create(eventId, request);
        return ResponseEntity
                .created(URI.create("/api/events/" + eventId + "/assignments/" + created.assignmentId()))
                .body(created);
    }

    @PutMapping("/{assignmentId}")
    public AssignmentResponse update(@PathVariable Integer eventId, @PathVariable Integer assignmentId,
                                     @Valid @RequestBody AssignmentRequest request) {
        return assignmentService.update(eventId, assignmentId, request);
    }

    @DeleteMapping("/{assignmentId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer eventId, @PathVariable Integer assignmentId) {
        assignmentService.delete(eventId, assignmentId);
    }
}