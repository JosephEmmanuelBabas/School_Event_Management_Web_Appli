package com.school_event.school_event_management.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import com.school_event.school_event_management.entity.AuditLog;
import com.school_event.school_event_management.repository.AuditLogRepository;
import com.school_event.school_event_management.security.AppUserPrincipal;

@ExtendWith(MockitoExtension.class)
class AuditServiceTest {

    @Mock
    private AuditLogRepository auditLogRepository;

    @InjectMocks
    private AuditService auditService;

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void log_refusesToRunWithoutALoggedInUser() {
        SecurityContextHolder.clearContext();

        assertThrows(IllegalStateException.class,
                () -> auditService.log(AuditAction.CREATED, "venue", 1));

        verify(auditLogRepository, never()).save(any());
    }

    @Test
    void log_recordsTheLoggedInUsersId() {
        AppUserPrincipal principal =
                new AppUserPrincipal(7, "organizer1", "hash", "Event Organizer", true);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        auditService.log(AuditAction.UPDATED, "venue", 3);

        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        assertEquals(7, captor.getValue().getUserId());
        assertEquals("Updated", captor.getValue().getActionPerformed());
        assertEquals("venue", captor.getValue().getAffectedTable());
        assertEquals(3, captor.getValue().getAffectedRecordId());
    }
}