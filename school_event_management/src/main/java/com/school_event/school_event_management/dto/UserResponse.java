package com.school_event.school_event_management.dto;

import com.school_event.school_event_management.entity.userAccount;

public record UserResponse(
        Integer userId,
        String username,
        String firstName,
        String lastName,
        String email,
        String roleName,
        String accountStatus) {

    public static UserResponse from(userAccount account) {
        return new UserResponse(
                account.getUserId(),
                account.getUsername(),
                account.getFirstName(),
                account.getLastName(),
                account.getEmail(),
                account.getRole().getRoleName(),
                account.getAccountStatus());
    }
}