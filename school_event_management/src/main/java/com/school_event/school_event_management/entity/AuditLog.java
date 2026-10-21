package com.school_event.school_event_management.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.Immutable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

// @Immutable tells Hibernate this row is never updated after insert.
@Entity
@Immutable
@Table(name = "audit_log")
public class AuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Integer logId;

    // The database enforces the foreign key to user_account.
    @Column(name = "user_id", nullable = false, updatable = false)
    private Integer userId;

    @Column(name = "action_performed", nullable = false, updatable = false, length = 100)
    private String actionPerformed;

    @Column(name = "affected_table", nullable = false, updatable = false, length = 50)
    private String affectedTable;

    @Column(name = "affected_record_id", nullable = false, updatable = false)
    private Integer affectedRecordId;

    // Hibernate inserts every column, so the database DEFAULT would not apply.
    @Column(name = "log_timestamp", nullable = false, updatable = false)
    private LocalDateTime logTimestamp;

    protected AuditLog() {
    }

    public AuditLog(Integer userId, String actionPerformed,
                    String affectedTable, Integer affectedRecordId) {
        this.userId = userId;
        this.actionPerformed = actionPerformed;
        this.affectedTable = affectedTable;
        this.affectedRecordId = affectedRecordId;
        this.logTimestamp = LocalDateTime.now();
    }

    // Getters only: an audit entry has no setters.
    public Integer getLogId() { return logId; }
    public Integer getUserId() { return userId; }
    public String getActionPerformed() { return actionPerformed; }
    public String getAffectedTable() { return affectedTable; }
    public Integer getAffectedRecordId() { return affectedRecordId; }
    public LocalDateTime getLogTimestamp() { return logTimestamp; }
}