-- ============================================================================
-- Group 1: DropBoxed - Security Hardening & Isolation
-- ============================================================================

-- Revoke default public schema and database permissions
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE dropboxed_db FROM PUBLIC;

-- Prevent non-admin roles from creating new objects in the application schema
REVOKE CREATE ON SCHEMA dropboxed FROM PUBLIC;