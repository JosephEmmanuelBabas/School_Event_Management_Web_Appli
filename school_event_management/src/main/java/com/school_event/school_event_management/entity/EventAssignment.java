package com.school_event.school_event_management.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "event_assignment")
public class EventAssignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "assignment_id")
    private Integer assignmentId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "event_id", nullable = false)
    private Event event;

    // Plain text on purpose (Business Rule 5): staff are not system users.
    @Column(name = "staff_name", nullable = false, length = 100)
    private String staffName;

    @Column(name = "staff_role", length = 50)
    private String staffRole;

    @Column(name = "assignment_status", nullable = false, length = 20)
    private String assignmentStatus;

    protected EventAssignment() {
    }

    public EventAssignment(Event event, String staffName, String staffRole, String assignmentStatus) {
        this.event = event;
        this.staffName = staffName;
        this.staffRole = staffRole;
        this.assignmentStatus = assignmentStatus;
    }

    public Integer getAssignmentId() { return assignmentId; }

    public Event getEvent() { return event; }

    public String getStaffName() { return staffName; }
    public void setStaffName(String staffName) { this.staffName = staffName; }

    public String getStaffRole() { return staffRole; }
    public void setStaffRole(String staffRole) { this.staffRole = staffRole; }

    public String getAssignmentStatus() { return assignmentStatus; }
    public void setAssignmentStatus(String assignmentStatus) { this.assignmentStatus = assignmentStatus; }
}