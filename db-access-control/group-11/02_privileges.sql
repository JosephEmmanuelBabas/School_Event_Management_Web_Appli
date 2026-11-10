-- Group 11 - ReserveIT: Activity 4 privileges (least privilege).
-- Run as postgres, connected to the ReserveIT database:
--     psql -U postgres -h localhost -d ReserveIT -f 02_privileges.sql
-- Safe to run again: it removes our groups' privileges first, then grants them again.

-- ---------------------------------------------------------------- database and schema access
REVOKE ALL ON DATABASE "ReserveIT" FROM PUBLIC;
GRANT CONNECT ON DATABASE "ReserveIT" TO a4_runtime_grp, a4_readonly_grp, a4_dataentry_grp, a4_auditor_grp;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO a4_runtime_grp, a4_readonly_grp, a4_dataentry_grp, a4_auditor_grp;

-- No default access for everyone else, and a clean start for our groups
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES    IN SCHEMA public FROM a4_runtime_grp, a4_readonly_grp, a4_dataentry_grp, a4_auditor_grp;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM a4_runtime_grp, a4_readonly_grp, a4_dataentry_grp, a4_auditor_grp;

-- ---------------------------------------------------------------- a4_runtime_grp (the web application)
GRANT SELECT, INSERT ON department, app_user, staff, reservation, reservation_material, penalty TO a4_runtime_grp;
GRANT SELECT, INSERT, DELETE ON room, material TO a4_runtime_grp;
GRANT UPDATE (status)                                                      ON app_user    TO a4_runtime_grp;
GRANT UPDATE (status)                                                      ON staff       TO a4_runtime_grp;
GRANT UPDATE (room_name, building, capacity, room_type, status)            ON room        TO a4_runtime_grp;
GRANT UPDATE (material_name, category, total_quantity, available_quantity) ON material    TO a4_runtime_grp;
GRANT UPDATE (status, staff_id)                                            ON reservation TO a4_runtime_grp;
GRANT UPDATE (paid_status, paid_date)                                      ON penalty     TO a4_runtime_grp;
-- Table privileges do not cover the ID sequences, so grant them separately
GRANT USAGE ON SEQUENCE department_department_id_seq, app_user_user_id_seq, staff_staff_id_seq,
                        room_room_id_seq, material_material_id_seq, reservation_reservation_id_seq,
                        penalty_penalty_id_seq TO a4_runtime_grp;

-- ---------------------------------------------------------------- a4_readonly_grp (reports)
GRANT SELECT ON department, room, material, reservation, reservation_material, penalty TO a4_readonly_grp;
-- People tables: no email addresses and never the password hashes
GRANT SELECT (user_id, first_name, last_name, role, department_id, status) ON app_user TO a4_readonly_grp;
GRANT SELECT (staff_id, full_name, role, status)                           ON staff    TO a4_readonly_grp;

-- ---------------------------------------------------------------- a4_dataentry_grp (front desk encodes requests)
GRANT SELECT ON department, room, material TO a4_dataentry_grp;
GRANT SELECT, INSERT ON reservation, reservation_material TO a4_dataentry_grp;
GRANT USAGE ON SEQUENCE reservation_reservation_id_seq TO a4_dataentry_grp;

-- ---------------------------------------------------------------- a4_auditor_grp (inspect, never change)
GRANT SELECT ON department, room, material, reservation, reservation_material, penalty TO a4_auditor_grp;
GRANT SELECT (user_id, first_name, last_name, email, role, department_id, status) ON app_user TO a4_auditor_grp;
GRANT SELECT (staff_id, full_name, email, role, status)                           ON staff    TO a4_auditor_grp;
