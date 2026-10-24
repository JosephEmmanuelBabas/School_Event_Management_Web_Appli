package com.school_event.school_event_management.controller;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.ChangePasswordRequest;
import com.school_event.school_event_management.dto.UpdateProfileRequest;
import com.school_event.school_event_management.dto.UserResponse;
import com.school_event.school_event_management.security.AppUserPrincipal;
import com.school_event.school_event_management.service.AccountService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/account")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal AppUserPrincipal principal) {
        return accountService.getMe(principal.getUserId());
    }

    @PutMapping("/me")
    public UserResponse updateProfile(@AuthenticationPrincipal AppUserPrincipal principal,
                                      @Valid @RequestBody UpdateProfileRequest request) {
        return accountService.updateProfile(principal.getUserId(), request);
    }

    @PostMapping("/me/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal AppUserPrincipal principal,
                               @Valid @RequestBody ChangePasswordRequest request) {
        accountService.changePassword(principal.getUserId(), request);
    }
}