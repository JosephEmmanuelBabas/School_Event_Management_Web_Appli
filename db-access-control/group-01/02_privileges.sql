-- ============================================================================
-- Group 1: DropBoxed - Privilege Grants (Least Privilege Model)
-- ============================================================================

-- Database and Schema Connection Access
GRANT CONNECT ON DATABASE dropboxed_db TO dropboxed_admin_grp, dropboxed_runtime_grp, dropboxed_readonly_grp;
GRANT USAGE ON SCHEMA dropboxed TO dropboxed_admin_grp, dropboxed_runtime_grp, dropboxed_readonly_grp;

-- Administrator Grants (Full CRUD on all dropboxed tables & sequences)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dropboxed TO dropboxed_admin_grp;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA dropboxed TO dropboxed_admin_grp;

-- Application Runtime Grants (DropBoxed Web App)
-- Core operational tables requiring write/update capabilities
GRANT SELECT, INSERT, UPDATE ON 
    dropboxed.users,
    dropboxed.complaints, 
    dropboxed.complaint_assignments, 
    dropboxed.attachments, 
    dropboxed.locations, 
    dropboxed.status_logs 
TO dropboxed_runtime_grp;

-- Administrative / Lookup tables (Read-Only for runtime app)
GRANT SELECT ON 
    dropboxed.staff, 
    dropboxed.complaint_categories 
TO dropboxed_runtime_grp;

-- Sequence generator access for new record primary keys
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA dropboxed TO dropboxed_runtime_grp;

-- Read-Only / Reporting / Audit Grants
GRANT SELECT ON ALL TABLES IN SCHEMA dropboxed TO dropboxed_readonly_grp;