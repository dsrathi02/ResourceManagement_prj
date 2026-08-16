-- Reserva — seed.sql
-- Sample data. Run after schema.sql, against the same database.
-- Passwords are plaintext demo values here; Stage 4's
-- hash_existing_passwords.py converts them to hashes before the app relies
-- on werkzeug's check_password_hash.

USE mini_project;

-- ── resource_incharge ────────────────────────────────────────────────────
INSERT INTO resource_incharge (incharge_id, name, email, department) VALUES
    (101, 'Mr. Patil', 'patil@gmail.com', 'IT'),
    (102, 'Ms. Desai', 'desai@gmail.com', 'EXTC');

-- ── resources ────────────────────────────────────────────────────────────
INSERT INTO resources
    (resource_id, resource_name, resource_type, location, capacity, status, incharge_id, available_from, available_to)
VALUES
    (201, 'Lab 1',                 'Lab',             'Building A - Floor 1', 40,  'Available', 101, '09:00:00', '18:00:00'),
    (202, 'Lab 2',                 'Lab',             'Building A - Floor 2', 35,  'Available', 101, '09:00:00', '18:00:00'),
    (203, 'Conference Room A',     'Conference Room', 'Building B - Floor 1', 20,  'Available', 102, '09:00:00', '18:00:00'),
    (204, 'Conference Room B',     'Conference Room', 'Building B - Floor 2', 15,  'Available', 102, '09:00:00', '18:00:00'),
    (205, 'Seminar Hall',          'Hall',            'Main Block',           100, 'Available', 102, '09:00:00', '18:00:00'),
    (206, 'Projector 1',           'Equipment',       'Store Room',           1,   'Available', 101, '09:00:00', '18:00:00'),
    (207, 'Projector 2',           'Equipment',       'Store Room',           1,   'Available', 101, '09:00:00', '18:00:00'),
    (208, 'Computer Lab Advanced', 'Lab',             'Building C',           50,  'Available', 102, '09:00:00', '18:00:00');

-- ── user ─────────────────────────────────────────────────────────────────
INSERT INTO user (user_id, first_name, last_name, department, email, password, role) VALUES
    (1, 'Amit',  'Sharma',   'IT',    'amit@gmail.com',     'student123', 'Student'),
    (2, 'Sneha', 'Patil',    'EXTC',  'sneha@gmail.com',    'student123', 'Student'),
    (3, 'Dr',    'Kulkarni', 'IT',    'kulkarni@gmail.com', 'faculty123', 'Faculty'),
    (4, 'Admin', 'Joshi',    'Admin', 'admin@gmail.com',    'admin123',   'Admin');

-- ── user_phone ───────────────────────────────────────────────────────────
INSERT INTO user_phone (user_id, phone_no) VALUES
    (1, '9123456780'),
    (1, '9876543210'),
    (2, '9988776655'),
    (3, '9765432109'),
    (4, '9000000001');

-- ── event ────────────────────────────────────────────────────────────────
INSERT INTO event (event_id, event_name, date, end_date, location, organiser) VALUES
    (1, 'Tech Workshop',        '2026-04-15', '2026-04-15', 'Building A',            'Dr. Kulkarni'),
    (2, 'Seminar on AI',        '2026-04-20', '2026-04-20', 'Seminar Hall',          'Prof. Mehta'),
    (3, 'Coding Competition',   '2026-04-25', '2026-04-25', 'Computer Lab Advanced', 'Mr. Patil'),
    (4, 'Dance Workshop',       '2026-04-18', '2026-04-18', 'Seminar Hall',          'Ms. Desai'),
    (5, 'Project Presentation', '2026-04-22', '2026-04-22', 'Conference Room A',     'Admin Joshi'),
    (7, 'dance',                '2026-04-06', '2026-04-06', 'TBD',                   'TBD');

-- ── booking ──────────────────────────────────────────────────────────────
INSERT INTO booking (booking_id, user_id, resource_id, event_id, start_datetime, end_datetime, booking_status, approved_by) VALUES
    (1, 1, 201, 1, '2026-04-15 10:00:00', '2026-04-15 12:00:00', 'confirmed', NULL),
    (2, 2, 202, 2, '2026-04-16 14:00:00', '2026-04-16 16:00:00', 'confirmed', NULL),
    (3, 1, 203, 4, '2026-04-18 11:00:00', '2026-04-18 13:00:00', 'pending',   NULL),
    (8, 4, 202, 7, '2026-04-14 15:36:00', '2026-04-15 15:36:00', 'confirmed', NULL);

-- ── announcement ─────────────────────────────────────────────────────────
INSERT INTO announcement (announcement_id, title, body, priority) VALUES
    (1, 'Tech Fest 2026 Registration Open',
        'Register before April 1st to claim early-bird slots for all workshops and competitions.',
        'high'),
    (2, 'Campus WiFi Maintenance — Apr 17',
        'The campus network will be unavailable on Apr 17 from 11 PM to 2 AM due to scheduled upgrades.',
        'urgent'),
    (3, 'Library Extended Hours During Exams',
        'The library and advanced computer lab will remain open until 10 PM starting Apr 20.',
        'normal'),
    (4, 'New Seminar Hall Booking Policy',
        'All seminar hall bookings now require faculty approval at least 48 hours in advance.',
        'normal');

-- Demo credentials (plaintext until Stage 4 hashes them):
--   Student : amit@gmail.com     / student123
--   Faculty : kulkarni@gmail.com / faculty123
--   Admin   : admin@gmail.com    / admin123
