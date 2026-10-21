package com.school_event.school_event_management.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.school_event.school_event_management.entity.Role;

public interface roleRepository extends JpaRepository<Role, Integer> {

    Optional<Role> findByRoleName(String roleName);
}