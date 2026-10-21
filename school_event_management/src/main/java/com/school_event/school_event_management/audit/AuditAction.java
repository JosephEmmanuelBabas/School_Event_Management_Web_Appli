package com.school_event.school_event_management.audit;

// The labels match the CHECK constraint on audit_log.action_performed.
public enum AuditAction {
    CREATED("Created"),
    UPDATED("Updated"),
    DELETED("Deleted");

    private final String label;

    AuditAction(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }
}