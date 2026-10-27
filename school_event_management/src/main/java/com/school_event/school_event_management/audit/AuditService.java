package com.school_event.school_event_management.audit;

import java.util.List;

import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.dto.AuditLogResponse;
import com.school_event.school_event_management.entity.AuditLog;
import com.school_event.school_event_management.repository.AuditLogRepository;
import com.school_event.school_event_management.security.AppUserPrincipal;
import com.school_event.school_event_management.dto.PageResult;

@Service
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public AuditService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    // MANDATORY: must run inside the caller's transaction. The audit row and the
    // change it describes are saved together, or neither is.
    @Transactional(propagation = Propagation.MANDATORY)
    public void log(AuditAction action, String affectedTable, Integer affectedRecordId) {
        auditLogRepository.save(new AuditLog(
                currentUserId(), action.getLabel(), affectedTable, affectedRecordId));
    }

    @Transactional(readOnly = true)
    public List<AuditLogResponse> findRecent(int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        return auditLogRepository.findRecent(PageRequest.of(safePage, safeSize));
    }

    @Transactional(readOnly = true)
    public PageResult<AuditLogResponse> findPage(int page, int size) {
        int safePage = Math.max(page, 0);
        int safeSize = Math.min(Math.max(size, 1), 100);
        List<AuditLogResponse> items = auditLogRepository.findRecent(PageRequest.of(safePage, safeSize));
        return new PageResult<>(items, auditLogRepository.count());
    }

    private Integer currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof AppUserPrincipal principal) {
            return principal.getUserId();
        }
        throw new IllegalStateException("Cannot record an audit entry without a logged-in user.");
    }
}