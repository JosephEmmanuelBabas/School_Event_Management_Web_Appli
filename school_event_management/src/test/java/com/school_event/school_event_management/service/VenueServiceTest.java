package com.school_event.school_event_management.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.school_event.school_event_management.dto.VenueRequest;
import com.school_event.school_event_management.dto.VenueResponse;
import com.school_event.school_event_management.entity.Venue;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.venueRepository;

@ExtendWith(MockitoExtension.class)
class VenueServiceTest {

    @Mock
    private venueRepository venueRepository;

    @InjectMocks
    private VenueService venueService;

    @Test
    void create_rejectsDuplicateName() {
        when(venueRepository.existsByVenueName("Gym")).thenReturn(true);

        assertThrows(DuplicateResourceException.class,
                () -> venueService.create(new VenueRequest("Gym", "Main Building", 100)));

        verify(venueRepository, never()).save(any());
    }

    @Test
    void create_trimsTextBeforeSaving() {
        when(venueRepository.existsByVenueName("Gym")).thenReturn(false);
        when(venueRepository.save(any(Venue.class))).thenAnswer(call -> call.getArgument(0));

        VenueResponse response =
                venueService.create(new VenueRequest("  Gym  ", "  Main Building ", 100));

        assertEquals("Gym", response.venueName());
        assertEquals("Main Building", response.location());
    }

    @Test
    void findById_throwsWhenMissing() {
        when(venueRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> venueService.findById(99));
    }
}