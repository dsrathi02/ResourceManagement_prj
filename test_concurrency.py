"""
Stage 6 concurrency test: two threads try to book the same resource for
the same time slot at (as close as threading.Barrier can manage) the
same instant. Exactly one booking should survive.

Why this drives the database directly instead of POSTing to a running
Flask app: Flask's dev server here runs as `app.run(debug=True)`, with
no `threaded=True`. That server handles one request at a time, so two
threads racing to POST /booking would just queue at the socket -- the
second request's SELECT would never run until the first request's
INSERT had already committed. The test would show exactly one booking
succeeding whether or not SELECT ... FOR UPDATE was in place, because
the server's own single-threadedness -- not the database locking -- is
what serialized them. That would prove nothing about the fix either way.

Running the same SELECT-then-INSERT sequence /booking uses, directly
against MySQL from two threads with their own connections, is what
actually exercises row locking: nothing here depends on how Flask
schedules requests.

Usage:
    python test_concurrency.py            # tests the fixed query (SELECT ... FOR UPDATE)
    python test_concurrency.py --no-lock  # tests the old, racy query (pre-Stage-6 /booking)
"""
import sys
import threading

from app import get_db

RESOURCE_ID = 205  # Seminar Hall
START = '2027-01-01 10:00:00'
END   = '2027-01-01 11:00:00'
USER_IDS = (1, 2)  # two different users racing for the same slot

USE_LOCK = '--no-lock' not in sys.argv


def attempt_booking(user_id, barrier, errors):
    conn = get_db()
    conn.start_transaction()
    cursor = conn.cursor()
    try:
        barrier.wait()  # line both threads up to hit the SELECT together
        if USE_LOCK:
            cursor.execute("""
                SELECT booking_id FROM booking
                WHERE resource_id=%s AND booking_status IN ('pending','confirmed')
                  AND start_datetime < %s AND end_datetime > %s
                FOR UPDATE
            """, (RESOURCE_ID, END, START))
        else:
            cursor.execute("""
                SELECT booking_id FROM booking
                WHERE resource_id=%s AND booking_status!='cancelled'
                  AND NOT (%s >= end_datetime OR %s <= start_datetime)
            """, (RESOURCE_ID, START, END))
        if cursor.fetchone():
            conn.rollback()
        else:
            cursor.execute("""
                INSERT INTO booking (user_id,resource_id,start_datetime,end_datetime,booking_status)
                VALUES (%s,%s,%s,%s,'pending')
            """, (user_id, RESOURCE_ID, START, END))
            conn.commit()
    except Exception as e:
        conn.rollback()
        errors.append(e)
    finally:
        cursor.close()
        conn.close()


def main():
    # Clean slate for this slot so the test is re-runnable.
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "DELETE FROM booking WHERE resource_id=%s AND start_datetime=%s AND end_datetime=%s",
        (RESOURCE_ID, START, END))
    conn.commit()
    cursor.close()
    conn.close()

    barrier = threading.Barrier(2)
    errors = []
    threads = [threading.Thread(target=attempt_booking, args=(uid, barrier, errors))
               for uid in USER_IDS]
    for t in threads: t.start()
    for t in threads: t.join()

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT COUNT(*) FROM booking
        WHERE resource_id=%s AND start_datetime=%s AND end_datetime=%s
          AND booking_status != 'cancelled'
    """, (RESOURCE_ID, START, END))
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()

    mode = 'WITH FOR UPDATE (fixed)' if USE_LOCK else 'WITHOUT FOR UPDATE (pre-fix, racy)'
    print(f"[{mode}] bookings surviving for the slot: {count}")
    if errors:
        print(f"  {len(errors)} thread(s) raised: {errors}")

    if USE_LOCK:
        assert count == 1, f"Expected exactly 1 booking, got {count} -- the lock failed to prevent the race"
        print("PASS: exactly one booking survived.")
    else:
        if count > 1:
            print(f"BUG REPRODUCED: {count} bookings both went through for the same slot, as expected without the lock.")
        else:
            print("Race did not reproduce this run (timing-dependent) -- try again.")


if __name__ == '__main__':
    main()
