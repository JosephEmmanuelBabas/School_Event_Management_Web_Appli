# Database User Roles Documentation
**Project:** Eventer: A High School Event Management System (HSEMS)

## 1. Overview
The High School Event Management System is a web-based application that centralizes school event information usually scattered across paper forms, spreadsheets, and messaging apps. It covers events, schedules, venues, staff assignments, participant attendance, and audit logs in one system.

**Scope:**
*   **Event Management:** Name, description, date, start/end time, status, organizer, venue, and assigned staff.
*   **Attendance Management:** Event-based only.
*   **Scheduling Management:** Manage event schedules, view scheduled activities, and view schedule conflicts.
*   **Venue and Staff Management:** Maintain records of available venues and assigned staff. 
*   **User and Account Management:** Role-based access control implemented for users.
*   **Analytics & Dashboard:** Overview of relevant event, attendance, user, and system information.
*   **Audit Logs:** Maintain records of significant user activities.

---

## 2. Application Roles and Database Role Mapping

| Application Role | Responsibilities in the Application | Functions and Data Access | Intended Database Role | 
| :--- | :--- | :--- | :--- |
| **Super Admin** | Manages the overall system, user accounts, and roles; monitors system activity. | Create, read, update, and deactivate on `user_account`; read on `role`, `event`, `attendance`, `participant`, `venue`, and `audit_log`; read and update own account; dashboard and analytics. | `app_admin_grp` (elevated group role, not a superuser) |
| **Event Organizer** | Creates and manages events, schedules, venue and staff assignments, and attendance. | Create, read, update, and delete on `event`, `event_schedule`, `event_assignment`, `participant`, `attendance`, and `venue`; read and update own account (profile and password). | `app_runtime_grp` |
| **Application Runtime** (system account) | The account the application uses to connect to PostgreSQL. | Only the operations the application code needs: read on `role` and `user_account` (login and RBAC checks), the operations listed for the roles above on operational tables, and insert on `audit_log`. | `app_runtime_grp` |

*Note: All organizers can manage all events (Business Rule 11); `organizer_id` records ownership only.*

---

## 3. Database Accounts & Privileges

This section outlines the specific PostgreSQL privileges assigned to each group role to enforce the principle of least privilege.

### A. Admin Group (`app_admin_grp`)
*   **Type:** Group role
*   **Login Account:** `[app_admin_user]` (Replace with actual secure username locally)
*   **Intended Privileges:** 
    *   `USAGE` on schema `public`
    *   `SELECT`, `INSERT`, `UPDATE` on `user_account`
    *   `SELECT` on all other application tables.

### B. Runtime Group (`app_runtime_grp`)
*   **Type:** Group role
*   **Login Account:** `[app_runtime_user]` (Replace with actual secure username locally)
*   **Intended Privileges:** 
    *   `USAGE` on schema `public`
    *   `SELECT` on all application tables.
    *   `INSERT` and `UPDATE` on `user_account`.
    *   `INSERT`, `UPDATE`, `DELETE` on `event`, `event_schedule`, `event_assignment`, `participant`, `attendance`, `venue`.
    *   `INSERT` on `audit_log`.
    *   `USAGE` on sequences (required for auto-incrementing primary keys).
