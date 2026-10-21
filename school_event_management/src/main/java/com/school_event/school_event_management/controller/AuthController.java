package com.school_event.school_event_management.controller;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.school_event.school_event_management.dto.CsrfResponse;
import com.school_event.school_event_management.dto.CurrentUserResponse;
import com.school_event.school_event_management.security.AppUserPrincipal;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    // The React app calls this to get the token it must send on writes.
    @GetMapping("/csrf")
    public CsrfResponse csrf(CsrfToken token) {
        return new CsrfResponse(token.getHeaderName(), token.getToken());
    }

    @GetMapping("/me")
    public CurrentUserResponse me(@AuthenticationPrincipal AppUserPrincipal principal) {
        return new CurrentUserResponse(
                principal.getUserId(), principal.getUsername(), principal.getRoleName());
    }
}