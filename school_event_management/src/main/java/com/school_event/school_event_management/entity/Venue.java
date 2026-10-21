package com.school_event.school_event_management.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "venue")
public class Venue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "venue_id")
    private Integer venueId;

    @Column(name = "venue_name", nullable = false, length = 100)
    private String venueName;

    @Column(name = "location", nullable = false, length = 150)
    private String location;

    @Column(name = "capacity")
    private Integer capacity;

    // JPA needs a no-argument constructor.
    protected Venue() {
    }

    public Venue(String venueName, String location, Integer capacity) {
        this.venueName = venueName;
        this.location = location;
        this.capacity = capacity;
    }

    public Integer getVenueId() { return venueId; }

    public String getVenueName() { return venueName; }
    public void setVenueName(String venueName) { this.venueName = venueName; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Integer getCapacity() { return capacity; }
    public void setCapacity(Integer capacity) { this.capacity = capacity; }
}