package com.school_event.school_event_management.exception;

// A well-formed request that breaks a business rule (maps to HTTP 400).
public class InvalidRequestException extends RuntimeException {

    public InvalidRequestException(String message) {
        super(message);
    }
}