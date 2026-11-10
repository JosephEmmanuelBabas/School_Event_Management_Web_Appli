-- UniSync access control (COMP 018 Activity 4)
-- PostgreSQL
--
-- Layer 1: group roles + GRANTs   (what each DB account may do to each table)
-- Layer 2: row-level security     (which rows, using the per-organization role
--                                  in MEMBERSHIP and the account id that php/db.php
--                                  sends in app.account_id)
--
-- Run as a PostgreSQL superuser, connected to grp10_unisyncdb,
-- AFTER db/init.sql and db/seed.sql:
--     psql -U postgres -d grp10_unisyncdb -f db/access-control.sql
-- Safe to re-run. Re-run it after every run of init.sql (init.sql drops the tables,
-- and their grants and policies with them).
--
-- Passwords are NOT in this file. After running it, set them locally:
--     psql -U postgres -c "\password unisync_app"
--     psql -U postgres -c "\password unisync_dba"
--     psql -U postgres -c "\password unisync_auditor"

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Roles
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_admin_grp') THEN
        CREATE ROLE unisync_admin_grp NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_runtime_grp') THEN
        CREATE ROLE unisync_runtime_grp NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_readonly_grp') THEN
        CREATE ROLE unisync_readonly_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_app') THEN
        CREATE ROLE unisync_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_dba') THEN
        CREATE ROLE unisync_dba LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'unisync_auditor') THEN
        CREATE ROLE unisync_auditor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
    END IF;
END
$$;

GRANT unisync_runtime_grp  TO unisync_app;
GRANT unisync_admin_grp    TO unisync_dba;
GRANT unisync_readonly_grp TO unisync_auditor;

-- ---------------------------------------------------------------------------
-- 2. Database and schema access
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO unisync_admin_grp, unisync_runtime_grp, unisync_readonly_grp',
        current_database());
END
$$;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public
    TO unisync_admin_grp, unisync_runtime_grp, unisync_readonly_grp;
GRANT CREATE ON SCHEMA public TO unisync_admin_grp;

-- ---------------------------------------------------------------------------
-- 3. Table and sequence privileges
-- ---------------------------------------------------------------------------
-- Start clean so re-runs do not leave old grants behind.

REVOKE ALL ON ALL TABLES    IN SCHEMA public
    FROM unisync_admin_grp, unisync_runtime_grp, unisync_readonly_grp;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public
    FROM unisync_admin_grp, unisync_runtime_grp, unisync_readonly_grp;

-- Admin group: everything on UniSync objects (not a superuser, not the owner)
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO unisync_admin_grp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO unisync_admin_grp;

-- Runtime group: no DELETE (soft deletes only), no DDL
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO unisync_runtime_grp;
GRANT USAGE, SELECT          ON ALL SEQUENCES IN SCHEMA public TO unisync_runtime_grp;

-- Read-only group: SELECT only, password_hash hidden
GRANT SELECT ON
    organization, membership, event, venue,
    event_schedule, registration, notification
    TO unisync_readonly_grp;
GRANT SELECT (account_id, account_name, email, avatar_url, account_status)
    ON account TO unisync_readonly_grp;

-- No ALTER DEFAULT PRIVILEGES on purpose: a future table gets no access until it is
-- granted explicitly AND given its own row-level security policies.

-- ---------------------------------------------------------------------------
-- 4. Helper functions
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER functions run as the owner (the superuser running this script),
-- so they can read MEMBERSHIP without triggering its own policies (no recursion).

-- Who is acting? NULL = not logged in. Set by php/db.php on every connection.
CREATE OR REPLACE FUNCTION app_account_id() RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT NULLIF(current_setting('app.account_id', true), '')::integer
$$;

-- The current account's active role in an organization ('Admin','Manager','Member') or NULL.
CREATE OR REPLACE FUNCTION app_org_role(p_org integer) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT m.role::text
    FROM public.membership m
    WHERE m.organization_id = p_org
      AND m.account_id = public.app_account_id()
      AND m.status = 'active'
$$;

-- The same, looked up through an event's organization.
CREATE OR REPLACE FUNCTION app_event_role(p_event integer) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT m.role::text
    FROM public.event e
    JOIN public.membership m ON m.organization_id = e.organization_id
    WHERE e.event_id = p_event
      AND m.account_id = public.app_account_id()
      AND m.status = 'active'
$$;

-- Does the organization have any membership row at all (any status)?
-- Used so only a brand-new organization can be claimed by its creator as Admin.
CREATE OR REPLACE FUNCTION app_org_has_membership(p_org integer) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (SELECT 1 FROM public.membership WHERE organization_id = p_org)
$$;

-- Does the organization currently have an active Admin?
CREATE OR REPLACE FUNCTION app_org_has_admin(p_org integer) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.membership
        WHERE organization_id = p_org AND role = 'Admin' AND status = 'active')
$$;

-- Has the current account ever had a membership row in this organization (any status)?
-- Lets a departing Admin hand over the Admin role after their own row is inactive.
CREATE OR REPLACE FUNCTION app_is_org_associated(p_org integer) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.membership
        WHERE organization_id = p_org AND account_id = public.app_account_id())
$$;

-- Who owns a venue?
CREATE OR REPLACE FUNCTION app_venue_owner(p_venue integer) RETURNS integer
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT account_id FROM public.venue WHERE venue_id = p_venue
$$;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public
    TO unisync_admin_grp, unisync_runtime_grp, unisync_readonly_grp;

-- ---------------------------------------------------------------------------
-- 5. Row-level security
-- ---------------------------------------------------------------------------
-- The tables stay owned by the superuser that ran init.sql, so the owner bypass
-- never applies to unisync_app, unisync_dba, or unisync_auditor.

ALTER TABLE account         ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization    ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership      ENABLE ROW LEVEL SECURITY;
ALTER TABLE event           ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue           ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_schedule  ENABLE ROW LEVEL SECURITY;
ALTER TABLE registration    ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification    ENABLE ROW LEVEL SECURITY;

-- Drop every existing policy so re-runs start clean.
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public' LOOP
        EXECUTE format('DROP POLICY %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END
$$;

-- Admin group: all rows. Read-only group: all rows, SELECT only (the GRANTs above
-- already limit the commands and columns).
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['account','organization','membership','event',
                             'venue','event_schedule','registration','notification']
    LOOP
        EXECUTE format(
            'CREATE POLICY %I ON public.%I FOR ALL TO unisync_admin_grp USING (true) WITH CHECK (true)',
            t || '_admin_all', t);
        EXECUTE format(
            'CREATE POLICY %I ON public.%I FOR SELECT TO unisync_readonly_grp USING (true)',
            t || '_readonly_select', t);
    END LOOP;
END
$$;

-- Runtime group (unisync_app): per-organization rules below.
-- With RLS enabled and no matching policy, a command is denied.

-- ACCOUNT -------------------------------------------------------------------
-- Anyone can be looked up (login, member lists). Registration happens while
-- logged out. Only your own row can be edited.
CREATE POLICY account_select ON account FOR SELECT TO unisync_runtime_grp
    USING (true);
CREATE POLICY account_register ON account FOR INSERT TO unisync_runtime_grp
    WITH CHECK (app_account_id() IS NULL);
CREATE POLICY account_update_own ON account FOR UPDATE TO unisync_runtime_grp
    USING (account_id = app_account_id())
    WITH CHECK (account_id = app_account_id());

-- ORGANIZATION --------------------------------------------------------------
-- Any logged-in account can create one. Only that organization's Admin can edit
-- or soft-delete it.
CREATE POLICY organization_select ON organization FOR SELECT TO unisync_runtime_grp
    USING (true);
CREATE POLICY organization_insert ON organization FOR INSERT TO unisync_runtime_grp
    WITH CHECK (app_account_id() IS NOT NULL);
CREATE POLICY organization_update ON organization FOR UPDATE TO unisync_runtime_grp
    USING (app_org_role(organization_id) = 'Admin')
    WITH CHECK (app_org_role(organization_id) = 'Admin');

-- MEMBERSHIP ----------------------------------------------------------------
CREATE POLICY membership_select ON membership FOR SELECT TO unisync_runtime_grp
    USING (true);

-- Join as Member, or become Admin of an organization that has no memberships yet
-- (the creator, right after inserting the organization). Only for yourself.
CREATE POLICY membership_insert ON membership FOR INSERT TO unisync_runtime_grp
    WITH CHECK (
        account_id = app_account_id()
        AND (role = 'Member'
             OR (role = 'Admin' AND NOT app_org_has_membership(organization_id)))
    );

-- Admin: change roles and remove anyone in their own organization.
CREATE POLICY membership_update_admin ON membership FOR UPDATE TO unisync_runtime_grp
    USING (app_org_role(organization_id) = 'Admin')
    WITH CHECK (app_org_role(organization_id) = 'Admin');

-- Manager: may only touch plain Members, and the row must stay a Member
-- (so a Manager can remove a Member but cannot promote anyone).
CREATE POLICY membership_update_manager ON membership FOR UPDATE TO unisync_runtime_grp
    USING (app_org_role(organization_id) = 'Manager' AND role = 'Member')
    WITH CHECK (app_org_role(organization_id) = 'Manager' AND role = 'Member');

-- Own row: leave (row becomes non-active) or rejoin (row must come back as Member).
-- Nobody can raise their own role through this policy.
CREATE POLICY membership_update_self ON membership FOR UPDATE TO unisync_runtime_grp
    USING (account_id = app_account_id())
    WITH CHECK (account_id = app_account_id() AND (role = 'Member' OR status <> 'active'));

-- Admin succession: while an organization has no active Admin, a current or former
-- member may promote an active Manager/Member to Admin.
CREATE POLICY membership_succession ON membership FOR UPDATE TO unisync_runtime_grp
    USING (status = 'active'
           AND role IN ('Manager', 'Member')
           AND NOT app_org_has_admin(organization_id)
           AND app_is_org_associated(organization_id))
    WITH CHECK (role = 'Admin'
                AND status = 'active'
                AND NOT app_org_has_admin(organization_id)
                AND app_is_org_associated(organization_id));
-- Note: PostgreSQL ORs the WITH CHECK of all policies on a command, so this check
-- repeats the "no active Admin" condition. Without it, any update could pass here.

-- EVENT ---------------------------------------------------------------------
-- Admin or Manager of the hosting organization only.
CREATE POLICY event_select ON event FOR SELECT TO unisync_runtime_grp
    USING (true);
CREATE POLICY event_insert ON event FOR INSERT TO unisync_runtime_grp
    WITH CHECK (app_org_role(organization_id) IN ('Admin', 'Manager'));
CREATE POLICY event_update ON event FOR UPDATE TO unisync_runtime_grp
    USING (app_org_role(organization_id) IN ('Admin', 'Manager'))
    WITH CHECK (app_org_role(organization_id) IN ('Admin', 'Manager'));

-- VENUE ---------------------------------------------------------------------
-- Visible to all; you can only add or edit venues under your own account.
CREATE POLICY venue_select ON venue FOR SELECT TO unisync_runtime_grp
    USING (true);
CREATE POLICY venue_insert ON venue FOR INSERT TO unisync_runtime_grp
    WITH CHECK (account_id = app_account_id());
CREATE POLICY venue_update ON venue FOR UPDATE TO unisync_runtime_grp
    USING (account_id = app_account_id())
    WITH CHECK (account_id = app_account_id());

-- EVENT_SCHEDULE ------------------------------------------------------------
-- Admin/Manager of the event's organization, plus the venue owner (who answers
-- the venue request by confirming or rejecting).
CREATE POLICY schedule_select ON event_schedule FOR SELECT TO unisync_runtime_grp
    USING (true);
CREATE POLICY schedule_insert ON event_schedule FOR INSERT TO unisync_runtime_grp
    WITH CHECK (app_event_role(event_id) IN ('Admin', 'Manager'));
CREATE POLICY schedule_update ON event_schedule FOR UPDATE TO unisync_runtime_grp
    USING (app_event_role(event_id) IN ('Admin', 'Manager')
           OR app_venue_owner(venue_id) = app_account_id())
    WITH CHECK (app_event_role(event_id) IN ('Admin', 'Manager')
                OR app_venue_owner(venue_id) = app_account_id());

-- REGISTRATION --------------------------------------------------------------
-- You see and manage your own registrations; Admins/Managers of the event's
-- organization see the attendee list and can remove attendees.
CREATE POLICY registration_select ON registration FOR SELECT TO unisync_runtime_grp
    USING (account_id = app_account_id()
           OR app_event_role(event_id) IN ('Admin', 'Manager'));
CREATE POLICY registration_insert ON registration FOR INSERT TO unisync_runtime_grp
    WITH CHECK (account_id = app_account_id());
CREATE POLICY registration_update ON registration FOR UPDATE TO unisync_runtime_grp
    USING (account_id = app_account_id()
           OR app_event_role(event_id) IN ('Admin', 'Manager'))
    WITH CHECK (account_id = app_account_id()
                OR app_event_role(event_id) IN ('Admin', 'Manager'));

-- NOTIFICATION (unused by the app) ------------------------------------------
CREATE POLICY notification_select ON notification FOR SELECT TO unisync_runtime_grp
    USING (account_id = app_account_id());
CREATE POLICY notification_insert ON notification FOR INSERT TO unisync_runtime_grp
    WITH CHECK (app_org_role(organization_id) IN ('Admin', 'Manager'));
CREATE POLICY notification_update ON notification FOR UPDATE TO unisync_runtime_grp
    USING (account_id = app_account_id())
    WITH CHECK (account_id = app_account_id());

COMMIT;