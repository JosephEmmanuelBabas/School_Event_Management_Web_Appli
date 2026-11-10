-- UniSync database initialization
-- PostgreSQL
-- WARNING: This script DROPS the existing UniSync tables and their data.
-- Run this only when you intend to reset the database.

BEGIN;

-- Drop tables in dependency order.
DROP TABLE IF EXISTS NOTIFICATION CASCADE;
DROP TABLE IF EXISTS REGISTRATION CASCADE;
DROP TABLE IF EXISTS EVENT_SCHEDULE CASCADE;
DROP TABLE IF EXISTS EVENT CASCADE;
DROP TABLE IF EXISTS MEMBERSHIP CASCADE;
DROP TABLE IF EXISTS VENUE CASCADE;
DROP TABLE IF EXISTS ORGANIZATION CASCADE;
DROP TABLE IF EXISTS ACCOUNT CASCADE;


-- 1. ACCOUNT
CREATE TABLE ACCOUNT (
    account_id      SERIAL PRIMARY KEY,
    account_name    VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    avatar_url      TEXT,
    account_status  VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT chk_account_status
        CHECK (account_status IN ('active', 'disabled', 'deleted'))
);


-- 2. ORGANIZATION
CREATE TABLE ORGANIZATION (
    organization_id     SERIAL PRIMARY KEY,
    organization_name   VARCHAR(150) NOT NULL,
    university_name     VARCHAR(150) NOT NULL,
    description         TEXT,
    avatar_url          TEXT,
    banner_url          TEXT,
    status              VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT chk_organization_status
        CHECK (status IN ('active', 'inactive', 'deleted'))
);


-- 3. MEMBERSHIP
-- status lifecycle:
--   pending  -> request to join, awaiting Admin/Manager approval
--   active   -> approved member
--   rejected -> request denied (row kept for history; user may re-request)
--   inactive -> left the organization
--   deleted  -> removed/kicked
CREATE TABLE MEMBERSHIP (
    membership_id    SERIAL PRIMARY KEY,
    account_id       INTEGER NOT NULL,
    organization_id  INTEGER NOT NULL,
    role             VARCHAR(20) NOT NULL DEFAULT 'Member',
    membership_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    status           VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_membership_account
        FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_membership_organization
        FOREIGN KEY (organization_id) REFERENCES ORGANIZATION(organization_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_account_organization
        UNIQUE (account_id, organization_id),

    CONSTRAINT chk_membership_role
        CHECK (role IN ('Admin', 'Manager', 'Member')),

    CONSTRAINT chk_membership_status
        CHECK (status IN ('pending', 'active', 'rejected', 'inactive', 'deleted')),

    -- A pending or rejected request can never carry elevated privileges.
    CONSTRAINT chk_membership_pending_role
        CHECK (status NOT IN ('pending', 'rejected') OR role = 'Member')
);


-- 4. EVENT
CREATE TABLE EVENT (
    event_id        SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL,
    event_name      VARCHAR(200) NOT NULL,
    description     TEXT,
    event_image     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_event_organization
        FOREIGN KEY (organization_id)
        REFERENCES ORGANIZATION(organization_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_event_status
        CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'deleted'))
);


-- 5. VENUE
CREATE TABLE VENUE (
    venue_id    SERIAL PRIMARY KEY,
    account_id  INTEGER NOT NULL,
    venue_name  VARCHAR(150) NOT NULL,
    location    TEXT NOT NULL,
    capacity    INT,
    latitude    DECIMAL(10, 7),
    longitude   DECIMAL(10, 7),
    status      VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_venue_account
        FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_provider_venue_name
        UNIQUE (account_id, venue_name),

    CONSTRAINT chk_venue_capacity
        CHECK (capacity IS NULL OR capacity > 0),

    CONSTRAINT chk_venue_latitude
        CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),

    CONSTRAINT chk_venue_longitude
        CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),

    CONSTRAINT chk_venue_coordinates
        CHECK (
            (latitude IS NULL AND longitude IS NULL)
            OR
            (latitude IS NOT NULL AND longitude IS NOT NULL)
        ),

    CONSTRAINT chk_venue_status
        CHECK (status IN ('active', 'inactive', 'deleted'))
);


-- 6. EVENT_SCHEDULE
-- Also serves as the venue application/request record.
CREATE TABLE EVENT_SCHEDULE (
    schedule_id  SERIAL PRIMARY KEY,
    event_id     INTEGER NOT NULL,
    venue_id     INTEGER NOT NULL,
    event_date   DATE NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    status       VARCHAR(30) NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_schedule_event
        FOREIGN KEY (event_id) REFERENCES EVENT(event_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_schedule_venue
        FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_schedule_time
        CHECK (end_time > start_time),

    CONSTRAINT chk_schedule_status
        CHECK (status IN ('pending', 'confirmed', 'rejected', 'cancelled', 'completed'))
);


-- 7. REGISTRATION
CREATE TABLE REGISTRATION (
    registration_id    SERIAL PRIMARY KEY,
    account_id         INTEGER NOT NULL,
    event_id           INTEGER NOT NULL,
    registration_date  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status             VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_registration_account
        FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_registration_event
        FOREIGN KEY (event_id) REFERENCES EVENT(event_id)
        ON DELETE CASCADE,

    CONSTRAINT uq_account_event
        UNIQUE (account_id, event_id),

    CONSTRAINT chk_registration_status
        CHECK (status IN ('active', 'cancelled', 'deleted'))
);


-- 8. NOTIFICATION
CREATE TABLE NOTIFICATION (
    notification_id      SERIAL PRIMARY KEY,
    account_id           INTEGER NOT NULL,
    organization_id      INTEGER NOT NULL,
    event_id             INTEGER,
    notification_message TEXT NOT NULL,
    is_read              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status               VARCHAR(30) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_notification_account
        FOREIGN KEY (account_id) REFERENCES ACCOUNT(account_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_notification_organization
        FOREIGN KEY (organization_id) REFERENCES ORGANIZATION(organization_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_notification_event
        FOREIGN KEY (event_id) REFERENCES EVENT(event_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_notification_status
        CHECK (status IN ('active', 'deleted'))
);


-- Helpful indexes for common lookups.
CREATE INDEX idx_membership_organization
    ON MEMBERSHIP(organization_id);

CREATE INDEX idx_membership_account
    ON MEMBERSHIP(account_id);

-- Fast lookup of join requests awaiting review for an organization.
CREATE INDEX idx_membership_pending
    ON MEMBERSHIP(organization_id)
    WHERE status = 'pending';

CREATE INDEX idx_event_organization
    ON EVENT(organization_id);

CREATE INDEX idx_venue_account
    ON VENUE(account_id);

CREATE INDEX idx_schedule_date_venue
    ON EVENT_SCHEDULE(event_date, venue_id);

CREATE INDEX idx_schedule_status
    ON EVENT_SCHEDULE(status);

CREATE INDEX idx_registration_event
    ON REGISTRATION(event_id);

CREATE INDEX idx_registration_account
    ON REGISTRATION(account_id);

CREATE INDEX idx_notification_account_created
    ON NOTIFICATION(account_id, created_at DESC);


COMMIT;