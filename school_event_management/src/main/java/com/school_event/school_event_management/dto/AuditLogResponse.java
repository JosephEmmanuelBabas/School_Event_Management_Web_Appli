package com.school_event.school_event_management.dto;

import java.time.LocalDateTime;

public record AuditLogResponse(
        Integer logId,
        Integer userId,
        String username,
        String actionPerformed,
        String affectedTable,
        Integer affectedRecordId,
        LocalDateTime logTimestamp) {
}