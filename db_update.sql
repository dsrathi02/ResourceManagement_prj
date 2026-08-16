-- ═══════════════════════════════════════════════════════════
-- RESERVA — DB Migration Script (MySQL 8.0 Compatible)
-- Run once BEFORE starting the Flask application
-- ═══════════════════════════════════════════════════════════

USE mini_project;

-- ── 1. Add password column to user (MySQL 8.0 safe) ─────────
DROP PROCEDURE IF EXISTS add_column_if_missing;

DELIMITER $$
CREATE PROCEDURE add_column_if_missing()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'user'
      AND COLUMN_NAME  = 'password'
  ) THEN
    ALTER TABLE user ADD COLUMN password VARCHAR(255) DEFAULT 'password123';
  END IF;
END$$
DELIMITER ;

CALL add_column_if_missing();
DROP PROCEDURE IF EXISTS add_column_if_missing;

-- Set role-specific demo passwords
UPDATE user SET password = 'student123' WHERE role = 'Student';
UPDATE user SET password = 'faculty123' WHERE role = 'Faculty';
UPDATE user SET password = 'admin123'   WHERE role = 'Admin';

-- Ensure admin user exists (for demo)
INSERT IGNORE INTO user (first_name, last_name, department, email, password, role, priority)
VALUES ('Admin', 'Joshi', 'Administration', 'admin@gmail.com', 'admin123', 'Admin', 3);

-- ── 2. Add end_date to event ─────────────────────────────────
DROP PROCEDURE IF EXISTS add_event_cols;

DELIMITER $$
CREATE PROCEDURE add_event_cols()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'event'
      AND COLUMN_NAME  = 'end_date'
  ) THEN
    ALTER TABLE event ADD COLUMN end_date DATE DEFAULT NULL;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'event'
      AND COLUMN_NAME  = 'description'
  ) THEN
    ALTER TABLE event ADD COLUMN description TEXT DEFAULT NULL;
  END IF;
END$$
DELIMITER ;

CALL add_event_cols();
DROP PROCEDURE IF EXISTS add_event_cols;

-- Populate end_date for existing events
UPDATE event SET end_date = date WHERE end_date IS NULL;

-- Make Tech Fest multi-day if it exists
UPDATE event SET end_date = DATE_ADD(date, INTERVAL 2 DAY)
WHERE event_name LIKE '%Tech Fest%' AND end_date = date;

-- ── 3. Announcements table ───────────────────────────────────
CREATE TABLE IF NOT EXISTS announcement (
  announcement_id INT          NOT NULL AUTO_INCREMENT,
  title           VARCHAR(200) NOT NULL,
  body            TEXT,
  created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
  priority        ENUM('normal','high','urgent') DEFAULT 'normal',
  PRIMARY KEY (announcement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sample announcements (idempotent)
INSERT IGNORE INTO announcement (announcement_id, title, body, priority) VALUES
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

-- ── Done ─────────────────────────────────────────────────────
SELECT 'Migration complete! Reserva is ready to run.' AS Status;

-- Demo credentials:
--   Student : amit@gmail.com       / student123
--   Faculty : kulkarni@gmail.com   / faculty123
--   Admin   : admin@gmail.com      / admin123
