package com.school_event.school_event_management.service;

import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.school_event.school_event_management.audit.AuditAction;
import com.school_event.school_event_management.audit.AuditService;
import com.school_event.school_event_management.dto.ParticipantRequest;
import com.school_event.school_event_management.dto.ParticipantResponse;
import com.school_event.school_event_management.entity.Participant;
import com.school_event.school_event_management.exception.DuplicateResourceException;
import com.school_event.school_event_management.exception.ResourceNotFoundException;
import com.school_event.school_event_management.repository.ParticipantRepository;
import com.school_event.school_event_management.dto.PageResult;

@Service
public class ParticipantService {

    private static final String AUDIT_TABLE = "participant";

    private final ParticipantRepository participants;
    private final AuditService auditService;

    public ParticipantService(ParticipantRepository participants, AuditService auditService) {
        this.participants = participants;
        this.auditService = auditService;
    }

    @Transactional(readOnly = true)
    public PageResult<ParticipantResponse> search(String search, String gradeLevel, int page, int size) {
        Sort sort = Sort.by("lastName", "firstName", "participantId");
        String gradeFilter = gradeLevel == null ? "" : gradeLevel.trim();
        String searchText = search == null ? "" : search.trim();

        List<ParticipantResponse> items = participants
                .search(gradeFilter, searchText,
                        PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100), sort))
                .stream()
                .map(ParticipantResponse::from)
                .toList();
        return new PageResult<>(items, participants.countSearch(gradeFilter, searchText));
    }

    @Transactional(readOnly = true)
    public ParticipantResponse findById(Integer id) {
        return ParticipantResponse.from(getOrThrow(id));
    }

    @Transactional
    public ParticipantResponse create(ParticipantRequest request) {
        String studentNumber = request.studentNumber().trim();
        if (participants.existsByStudentNumberIgnoreCase(studentNumber)) {
            throw new DuplicateResourceException(
                    "A participant with student number '" + studentNumber + "' already exists.");
        }
        Participant saved = participants.save(new Participant(
                studentNumber,
                request.firstName().trim(),
                request.lastName().trim(),
                normalize(request.gradeLevel())));
        auditService.log(AuditAction.CREATED, AUDIT_TABLE, saved.getParticipantId());
        return ParticipantResponse.from(saved);
    }

    @Transactional
    public ParticipantResponse update(Integer id, ParticipantRequest request) {
        Participant participant = getOrThrow(id);
        String studentNumber = request.studentNumber().trim();
        if (participants.existsByStudentNumberIgnoreCaseAndParticipantIdNot(studentNumber, id)) {
            throw new DuplicateResourceException(
                    "A participant with student number '" + studentNumber + "' already exists.");
        }
        participant.setStudentNumber(studentNumber);
        participant.setFirstName(request.firstName().trim());
        participant.setLastName(request.lastName().trim());
        participant.setGradeLevel(normalize(request.gradeLevel()));
        Participant saved = participants.save(participant);
        auditService.log(AuditAction.UPDATED, AUDIT_TABLE, saved.getParticipantId());
        return ParticipantResponse.from(saved);
    }

    @Transactional
    public void delete(Integer id) {
        Participant participant = getOrThrow(id);
        participants.delete(participant);
        try {
            // Force the DELETE now so a foreign-key refusal (attendance exists) is caught here.
            participants.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new DuplicateResourceException(
                    "This participant has attendance records and cannot be deleted.");
        }
        auditService.log(AuditAction.DELETED, AUDIT_TABLE, id);
    }

    private Participant getOrThrow(Integer id) {
        return participants.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Participant", id));
    }

    private static String normalize(String text) {
        return (text == null || text.isBlank()) ? null : text.trim();
    }
}