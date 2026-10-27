package com.school_event.school_event_management.dto;

import java.util.List;

// One page of results plus the total number of matching records.
public record PageResult<T>(List<T> items, long totalCount) {
}