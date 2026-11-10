-- 1. Revoke Default Access
REVOKE ALL ON DATABASE grp07_applicantdb FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- 2. Create Group Roles (No login capability)
CREATE ROLE hr_admin_grp NOLOGIN;
CREATE ROLE applicant_grp NOLOGIN;

-- 3. Create Login Accounts (Replace with secure local passwords)
CREATE ROLE hr_user LOGIN PASSWORD 'hr_secure_pw';
CREATE ROLE applicant_user LOGIN PASSWORD 'app_secure_pw';

-- 4. Assign Login Accounts to Group Roles
GRANT hr_admin_grp TO hr_user;
GRANT applicant_grp TO applicant_user;

-- 5. Grant Connection and Schema Usage
GRANT CONNECT ON DATABASE grp07_applicantdb TO hr_admin_grp, applicant_grp;
GRANT USAGE ON SCHEMA public TO hr_admin_grp, applicant_grp;

-- 6. Grant Granular Table & Sequence Privileges

-- HR Admin: Full operational control over all tables and sequences
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hr_admin_grp;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO hr_admin_grp;

-- Applicant: Restricted Access
-- Can view available jobs, departments, statuses, and requirements:
GRANT SELECT ON department, position, application_status, requirement TO applicant_grp;

-- Can create and view their own profiles, applications, and requirements:
GRANT SELECT, INSERT, UPDATE ON applicant, application, applicant_requirement TO applicant_grp;

-- Cannot access the interview table (Internal HR use only)
-- Note: 'interview' is deliberately omitted from applicant_grp grants.

-- Allow applicants to use sequences to generate new IDs when inserting records:
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO applicant_grp;