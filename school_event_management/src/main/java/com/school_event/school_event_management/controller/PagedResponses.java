package com.school_event.school_event_management.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;

import com.school_event.school_event_management.dto.PageResult;

// Turns a PageResult into a plain-list response with the total in a header.
final class PagedResponses {

    static final String TOTAL_COUNT_HEADER = "X-Total-Count";

    private PagedResponses() {
    }

    static <T> ResponseEntity<List<T>> of(PageResult<T> page) {
        return ResponseEntity.ok()
                .header(TOTAL_COUNT_HEADER, String.valueOf(page.totalCount()))
                .body(page.items());
    }
}