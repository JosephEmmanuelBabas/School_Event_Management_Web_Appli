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

import com.school_event.school_event_management.dto.ParticipantRequest;
import com.school_event.school_event_management.dto.ParticipantResponse;
import com.school_event.school_event_management.service.ParticipantService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/participants")
public class ParticipantController {

    private final ParticipantService participantService;

    public ParticipantController(ParticipantService participantService) {
        this.participantService = participantService;
    }

    @GetMapping
    public ResponseEntity<List<ParticipantResponse>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String gradeLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        return PagedResponses.of(participantService.search(search, gradeLevel, page, size));
    }

    @GetMapping("/{id}")
    public ParticipantResponse get(@PathVariable Integer id) {
        return participantService.findById(id);
    }

    @PostMapping
    public ResponseEntity<ParticipantResponse> create(@Valid @RequestBody ParticipantRequest request) {
        ParticipantResponse created = participantService.create(request);
        return ResponseEntity
                .created(URI.create("/api/participants/" + created.participantId()))
                .body(created);
    }

    @PutMapping("/{id}")
    public ParticipantResponse update(@PathVariable Integer id,
                                      @Valid @RequestBody ParticipantRequest request) {
        return participantService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        participantService.delete(id);
    }
}