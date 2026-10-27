package com.school_event.school_event_management.repository;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

import com.school_event.school_event_management.dto.AuditLogResponse;
import com.school_event.school_event_management.entity.AuditLog;

public interface AuditLogRepository extends Repository<AuditLog, Integer> {

    <S extends AuditLog> S save(S entity);

    @Query("""
            select new com.school_event.school_event_management.dto.AuditLogResponse(
                a.logId, a.userId, u.username, a.actionPerformed,
                a.affectedTable, a.affectedRecordId, a.logTimestamp)
            from AuditLog a
            join userAccount u on u.userId = a.userId
            order by a.logTimestamp desc, a.logId desc
            """)
    List<AuditLogResponse> findRecent(Pageable pageable);

    long count();
}