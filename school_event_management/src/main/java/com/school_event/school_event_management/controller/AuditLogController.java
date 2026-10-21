package com.school_event.school_event_management.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.AuditLogResponse;

@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {

    private final AuditService auditService;

    public AuditLogController(AuditService auditService) {
        this.auditService = auditService;
    }

    // Read-only. There is deliberately no POST, PUT or DELETE.
    @GetMapping
    public List<AuditLogResponse> list(@RequestParam(defaultValue = "0") int page,
                                       @RequestParam(defaultValue = "50") int size) {
        return auditService.findRecent(page, size);
    }
}