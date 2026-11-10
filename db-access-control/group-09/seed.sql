INSERT INTO trainers (first_name, last_name, specialty, contact_number)
VALUES
('Mark', 'Santos', 'Strength Training', '09171234567'),
('John', 'Reyes', 'Cardio Fitness', '09181234567'),
('Alex', 'Cruz', 'Yoga and Flexibility', '09191234567');


INSERT INTO membership_plans (plan_name, duration_months, price)
VALUES
('Monthly', 1, 1000.00),
('Quarterly', 3, 2700.00),
('Annual', 12, 10000.00);


INSERT INTO members
(first_name, last_name, email, contact_number, emergency_contact, status, trainer_id)
VALUES
('Daniel', 'Garcia', 'daniel@gmail.com', '09201234567', '09211234567', 'Active', 1),
('Michael', 'Torres', 'michael@gmail.com', '09221234567', '09231234567', 'Active', 2),
('Sarah', 'Mendoza', 'sarah@gmail.com', '09241234567', '09251234567', 'Active', 3),
('Kevin', 'Flores', 'kevin@gmail.com', '09261234567', '09271234567', 'Active', 1),
('Angela', 'Ramos', 'angela@gmail.com', '09281234567', '09291234567', 'Active', NULL);


INSERT INTO memberships
(member_id, plan_id, start_date, end_date, status)
VALUES
(1, 1, '2026-11-01', '2026-12-01', 'Active'),
(2, 2, '2026-10-15', '2027-01-15', 'Active'),
(3, 3, '2026-09-01', '2027-09-01', 'Active'),
(4, 1, '2026-11-01', '2026-12-01', 'Active'),
(5, 2, '2026-08-01', '2026-11-01', 'Expired');

INSERT INTO payments
(membership_id, amount, payment_date, payment_method)
VALUES
(1, 1000.00, '2026-11-01', 'Cash'),
(2, 2700.00, '2026-10-15', 'GCash'),
(3, 10000.00, '2026-09-01', 'Cash'),
(4, 1000.00, '2026-11-01', 'GCash'),
(5, 2700.00, '2026-08-01', 'Cash');

INSERT INTO classes
(class_name, trainer_id, room, class_date, start_time, end_time, capacity)
VALUES
('Morning Strength Training', 1, 'Room A', '2026-11-10', '08:00', '09:00', 15),
('Cardio Blast', 2, 'Room B', '2026-11-11', '10:00', '11:00', 20),
('Beginner Yoga', 3, 'Room C', '2026-11-12', '14:00', '15:00', 12);

INSERT INTO class_enrollments (member_id, class_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 1);

INSERT INTO attendance (member_id, check_in_time)
VALUES
(1, '2026-11-04 08:00:00'),
(2, '2026-11-04 08:15:00'),
(3, '2026-11-04 09:00:00'),
(4, '2026-11-04 09:30:00');

