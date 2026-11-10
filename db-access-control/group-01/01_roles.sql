-- ============================================================================
-- Group 1: DropBoxed - Role Creation & Hierarchy
-- ============================================================================

-- 1. Create Group Roles (NOLOGIN templates)
CREATE ROLE dropboxed_admin_grp NOLOGIN;
CREATE ROLE dropboxed_runtime_grp NOLOGIN;
CREATE ROLE dropboxed_readonly_grp NOLOGIN;

-- 2. Create Login Accounts
CREATE ROLE dropboxed_admin WITH LOGIN PASSWORD 'AdminPass2026!';
CREATE ROLE dropboxed_app WITH LOGIN PASSWORD 'AppRuntimePass2026!';
CREATE ROLE dropboxed_readonly WITH LOGIN PASSWORD 'ReadOnlyPass2026!';
CREATE ROLE dropboxed_report WITH LOGIN PASSWORD 'ReportPass2026!';
CREATE ROLE dropboxed_backup WITH LOGIN PASSWORD 'BackupPass2026!';

-- 3. Assign Role Memberships
GRANT dropboxed_admin_grp TO dropboxed_admin;
GRANT dropboxed_runtime_grp TO dropboxed_app;
GRANT dropboxed_readonly_grp TO dropboxed_readonly, dropboxed_report, dropboxed_backup;