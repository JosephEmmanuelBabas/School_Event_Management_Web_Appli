CREATE TABLE trainers (
    trainer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100),
    contact_number VARCHAR(20)
);

CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    contact_number VARCHAR(20) NOT NULL,
    emergency_contact VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    trainer_id INTEGER REFERENCES trainers(trainer_id)
);

CREATE TABLE membership_plans (
    plan_id SERIAL PRIMARY KEY,
    plan_name VARCHAR(100) NOT NULL,
    duration_months INTEGER NOT NULL CHECK (duration_months > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE memberships (
    membership_id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    plan_id INTEGER NOT NULL REFERENCES membership_plans(plan_id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CHECK (end_date > start_date)
);

CREATE UNIQUE INDEX unique_active_membership
ON memberships(member_id)
WHERE status = 'Active';


CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    membership_id INTEGER NOT NULL REFERENCES memberships(membership_id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method VARCHAR(50) NOT NULL
);


CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    trainer_id INTEGER NOT NULL REFERENCES trainers(trainer_id),
    room VARCHAR(100) NOT NULL,
    class_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    CHECK (end_time > start_time)
);

CREATE TABLE class_enrollments (
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    class_id INTEGER NOT NULL REFERENCES classes(class_id),
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (member_id, class_id)
);

CREATE TABLE attendance (
    attendance_id SERIAL PRIMARY KEY,
    member_id INTEGER NOT NULL REFERENCES members(member_id),
    check_in_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
