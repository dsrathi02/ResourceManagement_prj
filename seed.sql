-- Reserva — seed.sql
-- Sample data. Run after schema.sql, against the same database.
-- user.password values below are werkzeug generate_password_hash() output
-- (scrypt) for the plaintext demo passwords listed at the bottom of this
-- file. A fresh schema.sql + seed.sql load never inserts plaintext.

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
    (1, 'Amit',  'Sharma',   'IT',    'amit@gmail.com',     'scrypt:32768:8:1$1315ZY9yp6L4YBoj$be38610bd95600adb6b2754ea1f313b13ed2187f5ee01719cc5401d23400a8ac410e14b4c071cd5b7d11a0b02b8ab87c4bc82fc378cc6d15ee7d6c0acd27edb7', 'Student'),
    (2, 'Sneha', 'Patil',    'EXTC',  'sneha@gmail.com',    'scrypt:32768:8:1$rUTgEo06OWy66hCp$64d6a4adf7dbb489b872b90e5efd51950791749cec014c930901443028b135c2262038cf35c8b3d734b4c7e90e688ea09dc4991b2acdc2d4c4acc72787bef85a', 'Student'),
    (3, 'Dr',    'Kulkarni', 'IT',    'kulkarni@gmail.com', 'scrypt:32768:8:1$hs8qEmfQUyUR3xQm$8a1eecdef433aee3b5d2873f7367c4c3643e4adbe42ef295416b997e54275c416d6a0ba1f816b015df0d4a524fd6739fcf256ca8e0c8fa34eabcd36bf60100d1', 'Faculty'),
    (4, 'Admin', 'Joshi',    'Admin', 'admin@gmail.com',    'scrypt:32768:8:1$G3pqVD7i1UOdjOMQ$8b4572129620c30ff738c6bc3fd2f0cd18c581415dc29e9baa8efa31b0f80a4a4cad478157dda09384ca52ddf3fa0cbd99384081125c9987b59ba7f67da2af11', 'Admin');

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

-- Demo credentials (password column above stores the werkzeug hash, not these):
--   Student : amit@gmail.com     / student123
--   Faculty : kulkarni@gmail.com / faculty123
--   Admin   : admin@gmail.com    / admin123
