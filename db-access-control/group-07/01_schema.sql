-- =====================================================================
-- Applicant Management System (AMS) - Group 7
-- File    : db/01_schema.sql
-- Database: grp07_applicantdb   (PostgreSQL 18.x, schema: public)
--
-- Usage (run once, from the project root):
--   1. Create the database (as a superuser such as postgres):
--        psql -U postgres -c "CREATE DATABASE grp07_applicantdb;"
--   2. Load this schema:
--        psql -U postgres -d grp07_applicantdb -f db/01_schema.sql
--   3. Load sample data:
--        psql -U postgres -d grp07_applicantdb -f db/02_seed.sql
--
-- This script is idempotent: it can be re-run safely (IF NOT EXISTS).
-- It does NOT drop anything and contains no passwords.
-- Roles/privileges are intentionally left for Activity 4.
-- =====================================================================

SET client_min_messages = WARNING;

-- ---------------------------------------------------------------------
-- 1. DEPARTMENT
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS department (
    department_id    SERIAL       PRIMARY KEY,
    department_name  VARCHAR(100) NOT NULL,
    description      TEXT,
    CONSTRAINT uq_department_name UNIQUE (department_name),
    CONSTRAINT ck_department_name_not_blank CHECK (btrim(department_name) <> '')
);

-- ---------------------------------------------------------------------
-- 2. POSITION  ("position" is a non-reserved keyword in PostgreSQL,
--    so it is valid as a table name; quote it only if your tool complains)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS position (
    position_id      SERIAL       PRIMARY KEY,
    department_id    INTEGER      NOT NULL,
    position_title   VARCHAR(100) NOT NULL,
    description      TEXT,
    employment_type  VARCHAR(30)  NOT NULL DEFAULT 'Full-time',
    status           VARCHAR(20)  NOT NULL DEFAULT 'Open',
    CONSTRAINT fk_position_department
        FOREIGN KEY (department_id) REFERENCES department (department_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT ck_position_employment_type
        CHECK (employment_type IN ('Full-time', 'Part-time', 'Contract', 'Internship', 'Temporary')),
    CONSTRAINT ck_position_status
        CHECK (status IN ('Open', 'Closed', 'On Hold')),
    CONSTRAINT ck_position_title_not_blank CHECK (btrim(position_title) <> '')
);

-- ---------------------------------------------------------------------
-- 3. APPLICANT
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS applicant (
    applicant_id   SERIAL       PRIMARY KEY,
    first_name     VARCHAR(50)  NOT NULL,
    last_name      VARCHAR(50)  NOT NULL,
    email          VARCHAR(100) NOT NULL,
    phone          VARCHAR(20)  NOT NULL,
    address        TEXT,
    date_of_birth  DATE,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_applicant_email UNIQUE (email),
    CONSTRAINT ck_applicant_email_format CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    CONSTRAINT ck_applicant_dob CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE),
    CONSTRAINT ck_applicant_names_not_blank CHECK (btrim(first_name) <> '' AND btrim(last_name) <> '')
);

-- ---------------------------------------------------------------------
-- 4. APPLICATION_STATUS  (lookup table)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application_status (
    status_id    SERIAL      PRIMARY KEY,
    status_name  VARCHAR(50) NOT NULL,
    description  TEXT,
    CONSTRAINT uq_application_status_name UNIQUE (status_name),
    CONSTRAINT ck_status_name_not_blank CHECK (btrim(status_name) <> '')
);

-- ---------------------------------------------------------------------
-- 5. APPLICATION
--    Deleting an applicant removes their applications (CASCADE).
--    Positions and statuses in use cannot be deleted (RESTRICT).
--    An applicant may apply to a given position only once (UNIQUE pair).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS application (
    application_id    SERIAL  PRIMARY KEY,
    applicant_id      INTEGER NOT NULL,
    position_id       INTEGER NOT NULL,
    status_id         INTEGER NOT NULL,
    application_date  DATE    NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_application_applicant
        FOREIGN KEY (applicant_id) REFERENCES applicant (applicant_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_application_position
        FOREIGN KEY (position_id) REFERENCES position (position_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_application_status
        FOREIGN KEY (status_id) REFERENCES application_status (status_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_application_applicant_position UNIQUE (applicant_id, position_id)
);

-- ---------------------------------------------------------------------
-- 6. INTERVIEW  (an application may have many interviews)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS interview (
    interview_id    SERIAL       PRIMARY KEY,
    application_id  INTEGER      NOT NULL,
    interview_date  TIMESTAMP    NOT NULL,
    interview_type  VARCHAR(30)  NOT NULL DEFAULT 'In-person',
    results          VARCHAR(30)  DEFAULT 'Pending',
    notes           TEXT,
    CONSTRAINT fk_interview_application
        FOREIGN KEY (application_id) REFERENCES application (application_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_interview_type
        CHECK (interview_type IN ('Phone', 'Video', 'In-person', 'Panel', 'Technical')),
    CONSTRAINT ck_interview_result
        CHECK (result IS NULL OR result IN ('Pending', 'Passed', 'Failed', 'No Show', 'Rescheduled'))
);

-- ---------------------------------------------------------------------
-- 7. REQUIREMENT
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS requirement (
    requirement_id    SERIAL       PRIMARY KEY,
    requirement_name  VARCHAR(100) NOT NULL,
    description       TEXT,
    is_required       BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_requirement_name UNIQUE (requirement_name),
    CONSTRAINT ck_requirement_name_not_blank CHECK (btrim(requirement_name) <> '')
);

-- ---------------------------------------------------------------------
-- 8. APPLICANT_REQUIREMENT  (associative table resolving applicant M:N requirement)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS applicant_requirement (
    applicant_id     INTEGER     NOT NULL,
    requirement_id   INTEGER     NOT NULL,
    submitted_date   DATE,
    status           VARCHAR(20) NOT NULL DEFAULT 'Pending',
    remarks          TEXT,
    CONSTRAINT pk_applicant_requirement PRIMARY KEY (applicant_id, requirement_id),
    CONSTRAINT fk_appreq_applicant
        FOREIGN KEY (applicant_id) REFERENCES applicant (applicant_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_appreq_requirement
        FOREIGN KEY (requirement_id) REFERENCES requirement (requirement_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_appreq_status
        CHECK (status IN ('Pending', 'Submitted', 'Verified', 'Rejected')),
    -- A requirement that is Submitted/Verified must carry a submission date.
    CONSTRAINT ck_appreq_date_when_submitted
        CHECK (status NOT IN ('Submitted', 'Verified') OR submitted_date IS NOT NULL)
);

-- ---------------------------------------------------------------------
-- INDEXES on foreign keys and common search columns
-- (PRIMARY KEY / UNIQUE constraints already create their own indexes)
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_position_department     ON position (department_id);
CREATE INDEX IF NOT EXISTS idx_application_position    ON application (position_id);
CREATE INDEX IF NOT EXISTS idx_application_status      ON application (status_id);
CREATE INDEX IF NOT EXISTS idx_interview_application   ON interview (application_id);
CREATE INDEX IF NOT EXISTS idx_interview_date          ON interview (interview_date);
CREATE INDEX IF NOT EXISTS idx_appreq_requirement      ON applicant_requirement (requirement_id);
CREATE INDEX IF NOT EXISTS idx_applicant_last_name     ON applicant (last_name, first_name);
