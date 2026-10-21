package com.school_event.school_event_management.service;

import java.util.List;

import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.dto.VenueRequest;
import com.school_event.school_event_management.dto.VenueResponse;
import com.school_event.school_event_management.entity.Venue;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.venueRepository;

@Service
public class VenueService {

    private final venueRepository venueRepository;

    public VenueService(venueRepository venueRepository) {
        this.venueRepository = venueRepository;
    }

    @Transactional(readOnly = true)
    public List<VenueResponse> findAll() {
        return venueRepository.findAll(Sort.by("venueName"))
                .stream()
                .map(VenueResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public VenueResponse findById(Integer id) {
        return VenueResponse.from(getVenueOrThrow(id));
    }

    @Transactional
    public VenueResponse create(VenueRequest request) {
        String name = request.venueName().trim();
        if (venueRepository.existsByVenueName(name)) {
            throw new DuplicateResourceException("A venue named '" + name + "' already exists.");
        }
        Venue venue = new Venue(name, request.location().trim(), request.capacity());
        return VenueResponse.from(venueRepository.save(venue));
    }

    @Transactional
    public VenueResponse update(Integer id, VenueRequest request) {
        Venue venue = getVenueOrThrow(id);
        String name = request.venueName().trim();
        if (venueRepository.existsByVenueNameAndVenueIdNot(name, id)) {
            throw new DuplicateResourceException("A venue named '" + name + "' already exists.");
        }
        venue.setVenueName(name);
        venue.setLocation(request.location().trim());
        venue.setCapacity(request.capacity());
        return VenueResponse.from(venueRepository.save(venue));
    }

    @Transactional
    public void delete(Integer id) {
        Venue venue = getVenueOrThrow(id);
        venueRepository.delete(venue);
        // Force the DELETE now, so a foreign-key violation (venue still used
        // by an event) surfaces here and becomes a 409 response.
        venueRepository.flush();
    }

    private Venue getVenueOrThrow(Integer id) {
        return venueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Venue", id));
    }
}