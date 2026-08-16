# Reserva — Refactor Spec

This file is the source of truth for the refactor. Read it fully before making any change.

---

## 0. Ground rules (apply to every stage)

These are non-negotiable. The author must be able to explain every line in a viva.

- **No ORM.** Keep raw SQL with `mysql-connector-python` and `%s` placeholders.
- **No Flask blueprints, no factory pattern, no new abstraction layers.** Single `app.py` stays single `app.py`.
- **No new dependencies** except `bcrypt` (or `werkzeug.security`, already bundled with Flask).
- **No helper function unless it is used in 3+ places.** Inline is preferred over clever.
- **Do not rename existing columns or routes** unless this spec says to.
- After each stage: explain what changed and why, in plain language, in the commit message body.
- Work one stage at a time. Do not start the next stage until told to.

---

## 1. Target schema

Database: `mini_project`, MySQL 8, InnoDB, utf8mb4.

### role (NEW)

Removes the transitive dependency `user_id -> role -> priority`.

| Column | Type | Notes |
|---|---|---|
| role_name | VARCHAR(20) | PRIMARY KEY |
| priority | INT NOT NULL | |

Seed: `('Student',1), ('Faculty',3), ('Admin',5), ('Dean',5)`

### user

| Column | Type | Notes |
|---|---|---|
| user_id | INT | PK, AUTO_INCREMENT |
| first_name | VARCHAR(50) | NOT NULL |
| last_name | VARCHAR(50) | NOT NULL |
| department | VARCHAR(50) | |
| email | VARCHAR(100) | NOT NULL, UNIQUE |
| password | VARCHAR(255) | NOT NULL — stores a hash, never plaintext |
| role | VARCHAR(20) | NOT NULL, FK -> role(role_name) |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP |

**Drop the `priority` column.** Priority now comes from a join on `role`.

### user_phone

| Column | Type | Notes |
|---|---|---|
| user_id | INT | PK part 1, FK -> user(user_id) ON DELETE CASCADE |
| phone_no | VARCHAR(15) | PK part 2 |

Keep the composite primary key `(user_id, phone_no)`. Do **not** add a surrogate `phone_id`.
Reason: the composite key already guarantees a user cannot store the same number twice.
A surrogate key would allow duplicates unless a separate UNIQUE constraint were added.

### resource_incharge

| Column | Type | Notes |
|---|---|---|
| incharge_id | INT | PK, AUTO_INCREMENT |
| name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(100) | UNIQUE |
| department | VARCHAR(50) | |

**Drop the `proven` column.** It is unused and its meaning is unclear.

### resources

| Column | Type | Notes |
|---|---|---|
| resource_id | INT | PK, AUTO_INCREMENT |
| resource_name | VARCHAR(100) | NOT NULL |
| resource_type | VARCHAR(50) | NEW — app.py already inserts this |
| location | VARCHAR(100) | |
| capacity | INT | |
| status | ENUM('Available','Unavailable') | DEFAULT 'Available' |
| incharge_id | INT | FK -> resource_incharge ON DELETE SET NULL |
| available_from | TIME | NEW — app.py already inserts this |
| available_to | TIME | NEW — app.py already inserts this |

### booking

| Column | Type | Notes |
|---|---|---|
| booking_id | INT | PK, AUTO_INCREMENT |
| user_id | INT | NOT NULL, FK -> user ON DELETE CASCADE |
| resource_id | INT | NOT NULL, FK -> resources ON DELETE CASCADE |
| event_id | INT | NULL, FK -> event ON DELETE SET NULL |
| start_datetime | DATETIME | NOT NULL |
| end_datetime | DATETIME | NOT NULL |
| booking_status | ENUM('pending','confirmed','cancelled') | DEFAULT 'pending' |
| approved_by | INT | NULL, FK -> user(user_id) ON DELETE SET NULL |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP |

`approved_by` becomes a real foreign key (the self-relationship in the ER diagram).

Add a CHECK constraint: `CHECK (end_datetime > start_datetime)`.

### event

| Column | Type | Notes |
|---|---|---|
| event_id | INT | PK, AUTO_INCREMENT |
| event_name | VARCHAR(100) | NOT NULL |
| date | DATE | NOT NULL |
| end_date | DATE | |
| location | VARCHAR(100) | |
| organiser | VARCHAR(100) | |
| description | TEXT | |

### announcement

| Column | Type | Notes |
|---|---|---|
| announcement_id | INT | PK, AUTO_INCREMENT |
| title | VARCHAR(200) | NOT NULL |
| body | TEXT | |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP |
| priority | ENUM('normal','high','urgent') | DEFAULT 'normal' |

Independent entity. No foreign keys.

### Indexes on booking

Keep exactly these. Drop any others.

```sql
KEY idx_booking_resource_dates (resource_id, start_datetime, end_datetime)
KEY idx_booking_user           (user_id)
KEY idx_booking_status         (booking_status)
```

`idx_booking_resource_dates` serves the overlap check. Column order matters:
`resource_id` is the equality filter and goes first; the datetimes are range
filters and go last (leftmost prefix rule).

---

## 2. Authentication

### Password storage

- Use `werkzeug.security.generate_password_hash` and `check_password_hash`.
  (Bundled with Flask — no new dependency. Defaults to scrypt.)
- Signup: hash before insert. Never store plaintext.
- Login: fetch the row by email, then `check_password_hash(row['password'], entered)`.
  Do **not** put the password in the SQL WHERE clause.
- Write a one-off script `hash_existing_passwords.py` that reads every user row,
  hashes the current plaintext value, and writes it back. Run once, then delete.

### Login must not leak which field was wrong

Return the same message — "Invalid email or password" — whether the email does not
exist or the password is wrong. Different messages let an attacker enumerate accounts.

### Session

- Keep Flask's signed-cookie session. Do not add Flask-Login.
- Move `app.secret_key` out of the source file into an environment variable,
  with a development fallback. Add `.env` to `.gitignore`.
- On login, store: `user_id`, `name`, `role`, `email`. Do not store the password.
- Regenerate the session on login (`session.clear()` before `session.update()`)
  to prevent session fixation.

### Authorization

- Keep the two existing decorators, `@login_required` and `@admin_required`.
- Every route that reads or writes user-owned data must scope by
  `session['user_id']`, never by an ID taken from the URL or form.
- Audit every route. Any route without a decorator must either get one or be deleted.

---

## 3. ACID and transactions

Currently each route runs statements one at a time and calls `conn.commit()` at the end.
Any multi-statement route can fail halfway and leave the database inconsistent.

### Required pattern

Every route that performs **more than one write**, or that reads-then-writes based on
what it read, must run inside an explicit transaction:

```python
conn = get_db()
conn.start_transaction()
cursor = conn.cursor(dictionary=True)
try:
    # ... statements ...
    conn.commit()
except Exception:
    conn.rollback()
    raise
finally:
    cursor.close()
    conn.close()
```

### Routes that require this

| Route | Why |
|---|---|
| `/booking` (POST) | Reads for conflicts, may insert an event, then inserts a booking |
| `/admin/delete-resource/<rid>` | Multiple writes across two tables |
| `/admin/approve/<bid>` | Read-then-write on status |
| `/admin/reject/<bid>` | Read-then-write on status |
| `/signup` | Single insert, but wrap for consistency |

### Which ACID property each thing demonstrates

Keep this mapping in the code comments — it is the interview answer.

- **Atomicity** — the try/commit/rollback block. Event insert + booking insert
  either both happen or neither does.
- **Consistency** — foreign keys, the ENUM on `booking_status`, the
  `CHECK (end_datetime > start_datetime)` constraint. The database refuses
  invalid states regardless of what the application does.
- **Isolation** — `SELECT ... FOR UPDATE` in the booking route (see section 4).
  MySQL's default isolation level is REPEATABLE READ.
- **Durability** — InnoDB's redo log. Once `commit()` returns, the write survives
  a crash. Nothing to implement; be able to state it.

---

## 4. Concurrency control — the double-booking race

### The current bug

`/booking` does a `SELECT` for conflicts, then an `INSERT` if none were found.
Two users submitting at the same moment can both pass the SELECT and both INSERT.
The same room ends up booked twice. This is a check-then-act race condition.

### The fix: pessimistic locking with SELECT ... FOR UPDATE

```python
conn.start_transaction()
cursor.execute("""
    SELECT booking_id FROM booking
    WHERE resource_id = %s
      AND booking_status IN ('pending','confirmed')
      AND start_datetime < %s
      AND end_datetime   > %s
    FOR UPDATE
""", (resource_id, requested_end, requested_start))

if cursor.fetchone():
    conn.rollback()
    # show "already booked" error
else:
    cursor.execute("INSERT INTO booking (...) VALUES (...)", (...))
    conn.commit()
```

`FOR UPDATE` takes row and gap locks on the index range covered by the WHERE clause.
A second transaction running the same SELECT blocks until the first commits or rolls
back. By the time it proceeds, the first booking is visible, so it correctly finds a
conflict. The race is closed.

This requires `idx_booking_resource_dates` to exist. Without an index on those
columns, InnoDB escalates to locking every row it scans.

### Simplify the overlap condition

The current condition is `NOT (%s >= end_datetime OR %s <= start_datetime)`.
Rewrite it as the equivalent positive form, which is easier to read and explain:

```sql
start_datetime < requested_end AND end_datetime > requested_start
```

Two intervals overlap if each one starts before the other ends.

### Handle deadlocks

Wrap the transaction so `mysql.connector.errors.DatabaseError` with errno 1213
(deadlock) is caught and the user sees a "please try again" message rather than
a 500 page.

### Why not a UNIQUE constraint instead?

MySQL has no exclusion constraint for overlapping ranges (PostgreSQL does, via
`EXCLUDE USING gist`). A UNIQUE index cannot express "no two rows may have
overlapping time windows for the same resource." Application-level locking is
the correct approach on MySQL. Be able to say this.

---

## 5. Repository structure

Flask requires these folders. The repo currently has everything at the root, so
it does not run as committed.

```
ResourceManagement_prj/
├── app.py
├── requirements.txt          NEW
├── .gitignore                NEW
├── .env.example              NEW
├── schema.sql                replaces mini_project.sql + db_update.sql
├── seed.sql                  NEW — sample data, separate from schema
├── templates/                all 13 .html files move here
└── static/
    └── style.css
```

### Delete these files

They are not reachable from any route and are leftovers from an earlier prototype:

- `index.html`
- `script.js`
- `login.js`
- `signup.js`
- `db.py`
- `db.cpython-314.pyc`

### .gitignore must include

```
__pycache__/
*.pyc
.env
venv/
```

---

## 6. Stage order

Do these one at a time, in this order. Commit after each. Do not combine stages.

| Stage | Work | Verify by |
|---|---|---|
| 1 | Repo structure: create `templates/` and `static/`, move files, delete dead files, add `.gitignore` and `requirements.txt` | `flask run` serves the login page |
| 2 | New `schema.sql` and `seed.sql` matching section 1. Include the `role` table and all FK/CHECK constraints | Schema loads into a fresh database with no errors |
| 3 | Update every SQL query in `app.py` for the new schema — `priority` now comes from a join on `role` | Every page loads without a MySQL error |
| 4 | Password hashing, the migration script, and the login/signup changes from section 2 | Existing seeded users can log in after migration |
| 5 | Wrap the routes in section 3 in explicit transactions | Force an error mid-route; confirm rollback leaves no partial data |
| 6 | The `SELECT ... FOR UPDATE` booking fix and deadlock handling from section 4 | Two concurrent booking requests for the same slot — exactly one succeeds |

### Stage 6 verification

Write `test_concurrency.py` using Python's `threading` module: two threads each POST
the same booking slot at the same time. Assert that exactly one row exists in
`booking` for that resource and time window afterward. Run it before and after the
fix so the difference is visible.
