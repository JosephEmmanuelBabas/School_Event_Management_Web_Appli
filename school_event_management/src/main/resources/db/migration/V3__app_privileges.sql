-- The application connects as event_app. It gets only what it needs.
GRANT USAGE ON SCHEMA school_event_management_db TO event_app;

GRANT SELECT ON role TO event_app;                       -- read-only
GRANT SELECT, INSERT, UPDATE ON user_account TO event_app;  -- never deleted, only deactivated
GRANT SELECT, INSERT, UPDATE, DELETE ON
    venue, participant, event, event_schedule, event_assignment, attendance
    TO event_app;
GRANT SELECT, INSERT ON audit_log TO event_app;          -- append-only: no UPDATE, no DELETE

GRANT USAGE ON ALL SEQUENCES IN SCHEMA school_event_management_db TO event_app;