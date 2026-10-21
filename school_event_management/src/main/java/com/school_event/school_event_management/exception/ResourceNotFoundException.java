package com.school_event.school_event_management.exception;

public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String resource, Integer id) {
        super(resource + " with id " + id + " was not found.");
    }
}