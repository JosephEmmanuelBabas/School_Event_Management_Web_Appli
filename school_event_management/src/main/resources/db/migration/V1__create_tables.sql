-- Creates the 9 documented tables.
-- Flyway runs this as event_owner with search_path set to
-- school_event_management_db, so table names are unqualified.

CREATE TABLE role (
    role_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name   VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    CONSTRAINT uq_role_name UNIQUE (role_name)
);

CREATE TABLE venue (
    venue_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    venue_name VARCHAR(100) NOT NULL,
    location   VARCHAR(150) NOT NULL,
    capacity   INT,
    CONSTRAINT uq_venue_name UNIQUE (venue_name),
    CONSTRAINT ck_venue_capacity CHECK (capacity > 0)
);

CREATE TABLE participant (
    participant_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    first_name     VARCHAR(50) NOT NULL,
    last_name      VARCHAR(50) NOT NULL,
    grade_level    VARCHAR(10),
    CONSTRAINT uq_participant_student_number UNIQUE (student_number)
);

CREATE TABLE user_account (
    user_id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username       VARCHAR(50)  NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    first_name     VARCHAR(50)  NOT NULL,
    last_name      VARCHAR(50)  NOT NULL,
    email          VARCHAR(100),
    role_id        INT NOT NULL REFERENCES role (role_id),
    account_status VARCHAR(20)  NOT NULL DEFAULT 'Active',
    CONSTRAINT ck_user_account_status
        CHECK (account_status IN ('Active', 'Inactive', 'Suspended'))
);
-- Case-insensitive uniqueness ("Admin" and "admin" are the same account).
-- Several NULL emails are still allowed.
CREATE UNIQUE INDEX uq_user_account_username_lower ON user_account (lower(username));
CREATE UNIQUE INDEX uq_user_account_email_lower    ON user_account (lower(email));

CREATE TABLE event (
    event_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_name   VARCHAR(100) NOT NULL,
    description  TEXT,
    event_date   DATE NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    event_status VARCHAR(20) NOT NULL,
    organizer_id INT NOT NULL REFERENCES user_account (user_id),
    venue_id     INT NOT NULL REFERENCES venue (venue_id),
    CONSTRAINT ck_event_status
        CHECK (event_status IN ('Upcoming', 'Ongoing', 'Completed', 'Cancelled')),
    CONSTRAINT ck_event_time_order CHECK (end_time > start_time),
    -- Rule 4: one venue cannot host two overlapping events.
    -- Ranges are half-open, so 09:00-11:00 and 11:00-12:00 do not conflict.
    -- Cancelled events release their venue.
    CONSTRAINT ex_event_venue_no_overlap EXCLUDE USING gist (
        venue_id WITH =,
        tsrange(event_date + start_time, event_date + end_time) WITH &&
    ) WHERE (event_status <> 'Cancelled')
);

CREATE TABLE event_schedule (
    schedule_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id      INT NOT NULL REFERENCES event (event_id) ON DELETE CASCADE,
    activity_name VARCHAR(100) NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    CONSTRAINT ck_event_schedule_time_order CHECK (end_time > start_time)
);

CREATE TABLE event_assignment (
    assignment_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id          INT NOT NULL REFERENCES event (event_id) ON DELETE CASCADE,
    staff_name        VARCHAR(100) NOT NULL,
    staff_role        VARCHAR(50),
    assignment_status VARCHAR(20) NOT NULL,
    CONSTRAINT ck_event_assignment_status
        CHECK (assignment_status IN ('Confirmed', 'Pending', 'Cancelled'))
);

CREATE TABLE attendance (
    attendance_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id          INT NOT NULL REFERENCES event (event_id),
    participant_id    INT NOT NULL REFERENCES participant (participant_id),
    time_recorded     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    attendance_status VARCHAR(20) NOT NULL,
    CONSTRAINT ck_attendance_status
        CHECK (attendance_status IN ('Present', 'Late', 'Absent')),
    CONSTRAINT uq_attendance_event_participant UNIQUE (event_id, participant_id)
);

CREATE TABLE audit_log (
    log_id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id            INT NOT NULL REFERENCES user_account (user_id),
    action_performed   VARCHAR(100) NOT NULL,
    affected_table     VARCHAR(50)  NOT NULL,
    affected_record_id INT NOT NULL,
    log_timestamp      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_audit_log_action
        CHECK (action_performed IN ('Created', 'Updated', 'Deleted'))
);

-- PostgreSQL does not index foreign keys automatically.
CREATE INDEX ix_user_account_role_id      ON user_account (role_id);
CREATE INDEX ix_event_organizer_id        ON event (organizer_id);
CREATE INDEX ix_event_venue_id            ON event (venue_id);
CREATE INDEX ix_event_event_date          ON event (event_date);
CREATE INDEX ix_event_schedule_event_id   ON event_schedule (event_id);
CREATE INDEX ix_event_assignment_event_id ON event_assignment (event_id);
CREATE INDEX ix_attendance_participant_id ON attendance (participant_id);
CREATE INDEX ix_audit_log_user_id         ON audit_log (user_id);
CREATE INDEX ix_audit_log_timestamp       ON audit_log (log_timestamp);