# One-off migration: hash every plaintext password in `user`.
# Run once against the seeded database, then delete this file.
from app import get_db
from werkzeug.security import generate_password_hash

HASH_PREFIXES = ('scrypt:', 'pbkdf2:')

conn = get_db()
cursor = conn.cursor(dictionary=True)
cursor.execute("SELECT user_id, password FROM user")
rows = cursor.fetchall()

update_cursor = conn.cursor()
hashed_count = 0
for row in rows:
    if row['password'].startswith(HASH_PREFIXES):
        continue
    hashed = generate_password_hash(row['password'])
    update_cursor.execute("UPDATE user SET password=%s WHERE user_id=%s", (hashed, row['user_id']))
    hashed_count += 1

conn.commit()
conn.close()
print(f"Hashed {hashed_count} of {len(rows)} user password(s). "
      f"{len(rows) - hashed_count} already hashed and left untouched.")
