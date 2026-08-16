-- Reserva — schema.sql
-- Target schema per SPEC.md section 1. Run against a fresh MySQL 8 database.

CREATE DATABASE IF NOT EXISTS mini_project
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE mini_project;

-- ── role ─────────────────────────────────────────────────────────────────
-- Removes the transitive dependency user_id -> role -> priority.
CREATE TABLE role (
    role_name VARCHAR(20) NOT NULL,
    priority  INT         NOT NULL,
    PRIMARY KEY (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO role (role_name, priority) VALUES
    ('Student', 1),
    ('Faculty', 3),
    ('Admin',   5),
    ('Dean',    5);

-- ── user ─────────────────────────────────────────────────────────────────
-- priority column dropped: it now comes from a join on role.
CREATE TABLE user (
    user_id    INT          NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    department VARCHAR(50),
    email      VARCHAR(100) NOT NULL,
    password   VARCHAR(255) NOT NULL,
    role       VARCHAR(20)  NOT NULL,
    created_at DATETIME     DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_user_email (email),
    CONSTRAINT fk_user_role FOREIGN KEY (role) REFERENCES role (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── user_phone ───────────────────────────────────────────────────────────
-- Composite PK (user_id, phone_no): a user cannot store the same number
-- twice, with no surrogate key and no extra UNIQUE constraint needed.
CREATE TABLE user_phone (
    user_id  INT         NOT NULL,
    phone_no VARCHAR(15) NOT NULL,
    PRIMARY KEY (user_id, phone_no),
    CONSTRAINT fk_user_phone_user FOREIGN KEY (user_id)
        REFERENCES user (user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── resource_incharge ────────────────────────────────────────────────────
-- proven column dropped: unused, meaning unclear.
CREATE TABLE resource_incharge (
    incharge_id INT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100),
    department  VARCHAR(50),
    PRIMARY KEY (incharge_id),
    UNIQUE KEY uq_resource_incharge_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── resources ────────────────────────────────────────────────────────────
CREATE TABLE resources (
    resource_id    INT          NOT NULL AUTO_INCREMENT,
    resource_name  VARCHAR(100) NOT NULL,
    resource_type  VARCHAR(50),
    location       VARCHAR(100),
    capacity       INT,
    status         ENUM('Available','Unavailable') DEFAULT 'Available',
    incharge_id    INT,
    available_from TIME,
    available_to   TIME,
    PRIMARY KEY (resource_id),
    KEY fk_resources_incharge (incharge_id),
    CONSTRAINT fk_resources_incharge FOREIGN KEY (incharge_id)
        REFERENCES resource_incharge (incharge_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── event ────────────────────────────────────────────────────────────────
CREATE TABLE event (
    event_id    INT          NOT NULL AUTO_INCREMENT,
    event_name  VARCHAR(100) NOT NULL,
    date        DATE         NOT NULL,
    end_date    DATE,
    location    VARCHAR(100),
    organiser   VARCHAR(100),
    description TEXT,
    PRIMARY KEY (event_id),
    KEY idx_event_name (event_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── booking ──────────────────────────────────────────────────────────────
-- approved_by is a real FK now (self-relationship: an admin/faculty user
-- approves another user's booking). CHECK enforces end after start at the
-- database layer regardless of what the application sends.
CREATE TABLE booking (
    booking_id     INT      NOT NULL AUTO_INCREMENT,
    user_id        INT      NOT NULL,
    resource_id    INT      NOT NULL,
    event_id       INT,
    start_datetime DATETIME NOT NULL,
    end_datetime   DATETIME NOT NULL,
    booking_status ENUM('pending','confirmed','cancelled') DEFAULT 'pending',
    approved_by    INT,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (booking_id),
    KEY idx_booking_resource_dates (resource_id, start_datetime, end_datetime),
    KEY idx_booking_user (user_id),
    KEY idx_booking_status (booking_status),
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id)
        REFERENCES user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_resource FOREIGN KEY (resource_id)
        REFERENCES resources (resource_id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_event FOREIGN KEY (event_id)
        REFERENCES event (event_id) ON DELETE SET NULL,
    CONSTRAINT fk_booking_approved_by FOREIGN KEY (approved_by)
        REFERENCES user (user_id) ON DELETE SET NULL,
    CONSTRAINT chk_booking_dates CHECK (end_datetime > start_datetime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── announcement ─────────────────────────────────────────────────────────
-- Independent entity. No foreign keys.
CREATE TABLE announcement (
    announcement_id INT          NOT NULL AUTO_INCREMENT,
    title           VARCHAR(200) NOT NULL,
    body            TEXT,
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    priority        ENUM('normal','high','urgent') DEFAULT 'normal',
    PRIMARY KEY (announcement_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ── Views ────────────────────────────────────────────────────────────────
-- Kept from the original database; not part of SPEC.md section 1 but not
-- referenced by any route either, so they carry forward unchanged in
-- purpose. available_resources is updated for the new resources columns.

CREATE VIEW available_resources AS
SELECT
    r.resource_id,
    r.resource_name,
    r.resource_type,
    r.location,
    r.capacity,
    r.status,
    r.available_from,
    r.available_to,
    ri.name AS incharge_name
FROM resources r
LEFT JOIN resource_incharge ri ON r.incharge_id = ri.incharge_id
WHERE r.status = 'Available';

CREATE VIEW booking_details AS
SELECT
    b.booking_id,
    b.user_id,
    CONCAT(u.first_name, ' ', u.last_name) AS user_name,
    b.resource_id,
    r.resource_name,
    b.event_id,
    e.event_name,
    b.start_datetime,
    b.end_datetime,
    b.booking_status
FROM booking b
LEFT JOIN user u ON b.user_id = u.user_id
LEFT JOIN resources r ON b.resource_id = r.resource_id
LEFT JOIN event e ON b.event_id = e.event_id;
