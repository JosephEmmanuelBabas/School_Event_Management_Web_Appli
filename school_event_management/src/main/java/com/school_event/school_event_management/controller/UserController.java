package com.school_event.school_event_management.controller;

import java.net.URI;
import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.CreateUserRequest;
import com.school_event.school_event_management.dto.ResetPasswordRequest;
import com.school_event.school_event_management.dto.UpdateUserRequest;
import com.school_event.school_event_management.dto.UserResponse;
import com.school_event.school_event_management.security.AppUserPrincipal;
import com.school_event.school_event_management.service.UserService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public List<UserResponse> list() {
        return userService.findAll();
    }

    @GetMapping("/{id}")
    public UserResponse get(@PathVariable Integer id) {
        return userService.findById(id);
    }

    @PostMapping
    public ResponseEntity<UserResponse> create(@Valid @RequestBody CreateUserRequest request) {
        UserResponse created = userService.create(request);
        return ResponseEntity.created(URI.create("/api/users/" + created.userId())).body(created);
    }

    @PutMapping("/{id}")
    public UserResponse update(@PathVariable Integer id,
                               @Valid @RequestBody UpdateUserRequest request,
                               @AuthenticationPrincipal AppUserPrincipal principal) {
        return userService.update(id, request, principal.getUserId());
    }

    @PostMapping("/{id}/reset-password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@PathVariable Integer id,
                              @Valid @RequestBody ResetPasswordRequest request) {
        userService.resetPassword(id, request);
    }
}