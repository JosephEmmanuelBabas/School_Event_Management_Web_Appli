package com.school_event.school_event_management.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

// The associative table between Event and Participant (Business Rule 6).
// The database enforces UNIQUE (event_id, participant_id).
@Entity
@Table(name = "attendance")
public class Attendance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "attendance_id")
    private Integer attendanceId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "participant_id", nullable = false)
    private Participant participant;

    // Hibernate inserts every column, so the database DEFAULT would not apply.
    @Column(name = "time_recorded", nullable = false)
    private LocalDateTime timeRecorded;

    @Column(name = "attendance_status", nullable = false, length = 20)
    private String attendanceStatus;

    protected Attendance() {
    }

    public Attendance(Event event, Participant participant, String attendanceStatus) {
        this.event = event;
        this.participant = participant;
        this.attendanceStatus = attendanceStatus;
        this.timeRecorded = LocalDateTime.now();
    }

    public Integer getAttendanceId() { return attendanceId; }

    // A record never moves to another event or participant, so there are no setters for them.
    public Event getEvent() { return event; }
    public Participant getParticipant() { return participant; }

    public LocalDateTime getTimeRecorded() { return timeRecorded; }
    public String getAttendanceStatus() { return attendanceStatus; }

    // Changing the status also refreshes the time (for a "Late", this is the arrival time).
    public void changeStatus(String newStatus) {
        this.attendanceStatus = newStatus;
        this.timeRecorded = LocalDateTime.now();
    }
}