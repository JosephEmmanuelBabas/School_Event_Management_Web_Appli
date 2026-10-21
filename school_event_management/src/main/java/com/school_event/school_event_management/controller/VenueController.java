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

import com.school_event.school_event_management.dto.VenueRequest;
import com.school_event.school_event_management.dto.VenueResponse;
import com.school_event.school_event_management.service.VenueService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/venues")
public class VenueController {

    private final VenueService venueService;

    public VenueController(VenueService venueService) {
        this.venueService = venueService;
    }

    @GetMapping
    public List<VenueResponse> list() {
        return venueService.findAll();
    }

    @GetMapping("/{id}")
    public VenueResponse get(@PathVariable Integer id) {
        return venueService.findById(id);
    }

    @PostMapping
    public ResponseEntity<VenueResponse> create(@Valid @RequestBody VenueRequest request) {
        VenueResponse created = venueService.create(request);
        return ResponseEntity
                .created(URI.create("/api/venues/" + created.venueId()))
                .body(created);
    }

    @PutMapping("/{id}")
    public VenueResponse update(@PathVariable Integer id,
                                @Valid @RequestBody VenueRequest request) {
        return venueService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Integer id) {
        venueService.delete(id);
    }
}