package com.school_event.school_event_management.repository;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.school_event.school_event_management.entity.Participant;

public interface ParticipantRepository extends JpaRepository<Participant, Integer> {

    boolean existsByStudentNumberIgnoreCase(String studentNumber);

    boolean existsByStudentNumberIgnoreCaseAndParticipantIdNot(String studentNumber, Integer participantId);

    // gradeLevel "" = any grade, search "" = no text filter.
    @Query("""
            select p from Participant p
            where (:gradeLevel = '' or p.gradeLevel = :gradeLevel)
              and (:search = ''
                   or lower(p.studentNumber) like lower(concat('%', :search, '%'))
                   or lower(p.firstName) like lower(concat('%', :search, '%'))
                   or lower(p.lastName) like lower(concat('%', :search, '%')))
            """)
    List<Participant> search(@Param("gradeLevel") String gradeLevel,
                             @Param("search") String search,
                             Pageable pageable);




    // Same filters as search(), without paging. Used for the total count.
    @Query("""
            select count(p) from Participant p
            where (:gradeLevel = '' or p.gradeLevel = :gradeLevel)
              and (:search = ''
                   or lower(p.studentNumber) like lower(concat('%', :search, '%'))
                   or lower(p.firstName) like lower(concat('%', :search, '%'))
                   or lower(p.lastName) like lower(concat('%', :search, '%')))
            """)
    long countSearch(@Param("gradeLevel") String gradeLevel, @Param("search") String search);
}