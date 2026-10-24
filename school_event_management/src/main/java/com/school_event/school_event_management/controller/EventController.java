package com.school_event.school_event_management.controller;

import java.net.URI;
import java.time.LocalDate;
import java.util.List;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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

import com.school_event.school_event_management.dto.EventRequest;
import com.school_event.school_event_management.dto.EventResponse;
import com.school_event.school_event_management.dto.EventStatusRequest;
import com.school_event.school_event_management.security.AppUserPrincipal;
import com.school_event.school_event_management.service.EventService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/events")
public class EventController {

    private final EventService eventService;

    public EventController(EventService eventService) {
        this.eventService = eventService;
    }

    @GetMapping
    public List<EventResponse> list(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Integer venueId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(defaultValue = "eventDate") String sort,
            @RequestParam(defaultValue = "desc") String direction) {
        return eventService.search(status, venueId, search, from, to, page, size, sort, direction);
    }

    @GetMapping("/{id}")
    public EventResponse get(@PathVariable Integer id) {
        return eventService.findById(id);
    }

    @PostMapping
    public ResponseEntity<EventResponse> create(@Valid @RequestBody EventRequest request,
                                                @AuthenticationPrincipal AppUserPrincipal principal) {
        EventResponse created = eventService.create(request, principal.getUserId());
        return ResponseEntity.created(URI.create("/api/events/" + created.eventId())).body(created);
    }

    @PutMapping("/{id}")
    public EventResponse update(@PathVariable Integer id, @Valid @RequestBody EventRequest request) {
        return eventService.update(id, request);
    }

    @PostMapping("/{id}/status")
    public EventResponse changeStatus(@PathVariable Integer id,
                                      @Valid @RequestBody EventStatusRequest request) {
        return eventService.changeStatus(id, request.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        eventService.delete(id);
    }
}