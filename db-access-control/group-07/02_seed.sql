-- =====================================================================
-- Applicant Management System (AMS) - Group 7
-- File    : db/02_seed.sql
-- Purpose : Mock sample data for testing. Run AFTER db/01_schema.sql.
--
--   psql -U postgres -d grp07_applicantdb -f db/02_seed.sql
--
-- Safe to re-run: every INSERT uses ON CONFLICT DO NOTHING.
-- All names, emails and phone numbers are fictional.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- DEPARTMENT (5)
-- ---------------------------------------------------------------------
INSERT INTO department (department_id, department_name, description) VALUES
    (1, 'Human Resources',        'Handles recruitment, employee relations, and HR policies.'),
    (2, 'Information Technology', 'Maintains systems, networks, databases, and software development.'),
    (3, 'Finance and Accounting', 'Manages budgeting, bookkeeping, and financial reporting.'),
    (4, 'Marketing',              'Handles branding, promotions, and customer outreach.'),
    (5, 'Operations',             'Oversees daily business operations and logistics.')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- POSITION (8)
-- ---------------------------------------------------------------------
INSERT INTO position (position_id, department_id, position_title, description, employment_type, status) VALUES
    (1, 1, 'HR Assistant',          'Supports daily HR administrative tasks and record keeping.',        'Full-time',  'Open'),
    (2, 1, 'Recruitment Officer',   'Sources candidates and coordinates the hiring process.',            'Full-time',  'Open'),
    (3, 2, 'Software Developer',    'Develops and maintains internal web applications.',                 'Full-time',  'Open'),
    (4, 2, 'Network Administrator', 'Manages office network infrastructure and security.',               'Full-time',  'Closed'),
    (5, 3, 'Accountant',            'Prepares financial statements and reconciles accounts.',            'Full-time',  'Open'),
    (6, 4, 'Marketing Associate',   'Assists with campaigns, social media, and content creation.',       'Part-time',  'Open'),
    (7, 5, 'Operations Supervisor', 'Supervises daily operations and coordinates staff schedules.',      'Contract',   'Closed'),
    (8, 2, 'Database Administrator','Administers PostgreSQL databases, backups, and user privileges.',   'Full-time',  'Open')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- APPLICANT (10)
-- ---------------------------------------------------------------------
INSERT INTO applicant (applicant_id, first_name, last_name, email, phone, address, date_of_birth, created_at) VALUES
    (1,  'Maria',   'Santos',    'maria.santos@example.com',    '09171234501', '12 Mabini St., Las Pinas City',        '1999-03-14', '2026-09-01 09:15:00'),
    (2,  'Juan',    'Dela Cruz', 'juan.delacruz@example.com',   '09171234502', '45 Rizal Ave., Quezon City',           '1997-07-22', '2026-09-03 10:30:00'),
    (3,  'Angela',  'Reyes',     'angela.reyes@example.com',    '09171234503', '88 Bonifacio Rd., Makati City',        '2000-11-05', '2026-09-05 13:45:00'),
    (4,  'Mark',    'Villanueva','mark.villanueva@example.com', '09171234504', '23 Luna St., Paranaque City',          '1995-01-30', '2026-09-08 08:20:00'),
    (5,  'Katrina', 'Garcia',    'katrina.garcia@example.com',  '09171234505', '67 Aguinaldo Hwy., Bacoor, Cavite',    '1998-09-17', '2026-09-10 11:05:00'),
    (6,  'Paolo',   'Mendoza',   'paolo.mendoza@example.com',   '09171234506', '9 Del Pilar St., Muntinlupa City',     '1996-05-02', '2026-09-12 14:10:00'),
    (7,  'Jasmine', 'Torres',    'jasmine.torres@example.com',  '09171234507', '101 Katipunan Ave., Pasig City',       '2001-12-25', '2026-09-15 09:40:00'),
    (8,  'Carlo',   'Ramos',     'carlo.ramos@example.com',     '09171234508', '34 Quezon Blvd., Manila',              '1994-08-11', '2026-09-18 15:25:00'),
    (9,  'Bianca',  'Aquino',    'bianca.aquino@example.com',   '09171234509', '56 Taft Ave., Pasay City',             '1999-06-28', '2026-09-20 10:00:00'),
    (10, 'Rafael',  'Lim',       'rafael.lim@example.com',      '09171234510', '78 Shaw Blvd., Mandaluyong City',      '1993-02-19', '2026-09-22 16:35:00')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- APPLICATION_STATUS (5)
-- ---------------------------------------------------------------------
INSERT INTO application_status (status_id, status_name, description) VALUES
    (1, 'Pending',      'Application received and awaiting initial screening.'),
    (2, 'Under Review', 'Application is being evaluated by HR or the hiring team.'),
    (3, 'Interview',    'Applicant is in the interview stage.'),
    (4, 'Accepted',     'Applicant has been selected for the position.'),
    (5, 'Rejected',     'Application was not successful.')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- APPLICATION (12)  -- one row per unique (applicant, position) pair
-- ---------------------------------------------------------------------
INSERT INTO application (application_id, applicant_id, position_id, status_id, application_date) VALUES
    (1,  1, 1, 3, '2026-09-02'),
    (2,  2, 2, 2, '2026-09-04'),
    (3,  3, 3, 1, '2026-09-06'),
    (4,  4, 1, 4, '2026-09-09'),
    (5,  5, 4, 5, '2026-09-11'),
    (6,  6, 5, 3, '2026-09-13'),
    (7,  7, 6, 2, '2026-09-16'),
    (8,  8, 7, 1, '2026-09-19'),
    (9,  9, 8, 3, '2026-09-21'),
    (10, 10, 2, 5, '2026-09-23'),
    (11, 1, 6, 1, '2026-10-05'),
    (12, 3, 5, 2, '2026-10-08')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- INTERVIEW (8)
-- ---------------------------------------------------------------------
INSERT INTO interview (interview_id, application_id, interview_date, interview_type, results, notes) VALUES
    (1, 1,  '2026-10-20 10:00:00', 'Phone',     'Passed',  'Good communication skills; proceeds to panel interview.'),
    (2, 1,  '2026-11-05 14:00:00', 'Panel',     'Pending', 'Scheduled with HR manager and department head.'),
    (3, 4,  '2026-10-15 09:00:00', 'In-person', 'Passed',  'Strong HR background and relevant experience.'),
    (4, 4,  '2026-10-22 13:30:00', 'Panel',     'Passed',  'Unanimous recommendation from the panel.'),
    (5, 5,  '2026-10-12 11:00:00', 'Phone',     'Failed',  'Insufficient networking experience for the role.'),
    (6, 6,  '2026-11-04 10:00:00', 'Technical', 'Pending', 'Accounting technical assessment scheduled.'),
    (7, 9,  '2026-11-03 15:00:00', 'Video',     'Pending', 'PostgreSQL administration discussion via video call.'),
    (8, 10, '2026-10-14 10:00:00', 'Phone',     'Failed',  'Did not meet minimum recruitment experience.')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- REQUIREMENT (6)
-- ---------------------------------------------------------------------
INSERT INTO requirement (requirement_id, requirement_name, description, is_required) VALUES
    (1, 'Resume / Curriculum Vitae',  'Updated resume with work history and education.',        TRUE),
    (2, 'Transcript of Records',      'Official or certified copy of academic records.',        TRUE),
    (3, 'NBI Clearance',              'Valid National Bureau of Investigation clearance.',      TRUE),
    (4, 'Valid Government ID',        'Photocopy of at least one valid government-issued ID.',  TRUE),
    (5, 'PSA Birth Certificate',      'Birth certificate issued by the PSA.',                   FALSE),
    (6, 'Medical Certificate',        'Medical certificate issued within the last 6 months.',   FALSE)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- APPLICANT_REQUIREMENT (20)
-- ---------------------------------------------------------------------
INSERT INTO applicant_requirement (applicant_id, requirement_id, submitted_date, status, remarks) VALUES
    (1, 1, '2026-09-02', 'Verified',  'Complete and verified.'),
    (1, 2, '2026-09-02', 'Verified',  'Certified true copy.'),
    (1, 3, '2026-09-10', 'Submitted', 'Awaiting HR verification.'),
    (1, 4, '2026-09-02', 'Verified',  NULL),
    (2, 1, '2026-09-04', 'Verified',  NULL),
    (2, 2, NULL,         'Pending',   'Applicant to submit by end of month.'),
    (2, 4, '2026-09-04', 'Submitted', NULL),
    (3, 1, '2026-09-06', 'Submitted', 'Portfolio link included.'),
    (3, 4, '2026-09-06', 'Rejected',  'ID photocopy is unreadable; resubmission requested.'),
    (4, 1, '2026-09-09', 'Verified',  NULL),
    (4, 2, '2026-09-09', 'Verified',  NULL),
    (4, 3, '2026-09-15', 'Verified',  NULL),
    (4, 4, '2026-09-09', 'Verified',  NULL),
    (4, 6, '2026-10-25', 'Verified',  'Pre-employment medical completed.'),
    (5, 1, '2026-09-11', 'Verified',  NULL),
    (5, 2, '2026-09-11', 'Submitted', NULL),
    (6, 1, '2026-09-13', 'Verified',  NULL),
    (6, 2, '2026-09-13', 'Verified',  NULL),
    (6, 3, NULL,         'Pending',   'NBI clearance still being processed.'),
    (9, 1, '2026-09-21', 'Submitted', 'Includes list of certifications.')
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- Re-sync SERIAL sequences after inserting explicit IDs, so that new
-- rows created through the application do not collide with seed rows.
-- ---------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('department',         'department_id'), (SELECT MAX(department_id)  FROM department));
SELECT setval(pg_get_serial_sequence('position',           'position_id'),   (SELECT MAX(position_id)    FROM position));
SELECT setval(pg_get_serial_sequence('applicant',          'applicant_id'),  (SELECT MAX(applicant_id)   FROM applicant));
SELECT setval(pg_get_serial_sequence('application_status', 'status_id'),     (SELECT MAX(status_id)      FROM application_status));
SELECT setval(pg_get_serial_sequence('application',        'application_id'),(SELECT MAX(application_id) FROM application));
SELECT setval(pg_get_serial_sequence('interview',          'interview_id'),  (SELECT MAX(interview_id)   FROM interview));
SELECT setval(pg_get_serial_sequence('requirement',        'requirement_id'),(SELECT MAX(requirement_id) FROM requirement));

COMMIT;
