
from flask import (Flask, jsonify, render_template, request,
                   redirect, url_for, session, flash)
import mysql.connector
import os
import re
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-fallback-key-change-in-production')


# ─── Template Filters ─────────────────────────────────────────────────────────

@app.template_filter('fmt_date')
def fmt_date(v, fmt='%b %d, %Y'):
    if not v: return '—'
    if hasattr(v, 'strftime'): return v.strftime(fmt)
    return str(v)

@app.template_filter('fmt_dt')
def fmt_dt(v):
    if not v: return '—'
    if hasattr(v, 'strftime'): return v.strftime('%b %d, %Y · %I:%M %p')
    try:
        from datetime import datetime
        return datetime.fromisoformat(str(v)).strftime('%b %d, %Y · %I:%M %p')
    except: return str(v)

@app.template_filter('short_date')
def short_date(v):
    if not v: return '—'
    if hasattr(v, 'strftime'): return v.strftime('%b %d')
    return str(v)[:10]

@app.template_filter('month_name')
def month_name(v):
    if not v: return ''
    if hasattr(v, 'strftime'): return v.strftime('%b').upper()
    return str(v)[5:7]

@app.template_filter('day_num')
def day_num(v):
    if not v: return ''
    if hasattr(v, 'strftime'): return v.strftime('%d')
    return str(v)[8:10]


# ─── Database ─────────────────────────────────────────────────────────────────

def get_db():
    return mysql.connector.connect(
        host='localhost', user='root',
        password='root123', database='mini_project'
    )


# ─── Auth Decorators ──────────────────────────────────────────────────────────

def login_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return dec

def admin_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        if session.get('role') not in ('Admin', 'Dean'):
            flash('Admin access required.', 'error')
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return dec


def _valid_password(pw):
    """Returns True if password meets strength requirements."""
    return (
        len(pw) >= 8 and
        bool(re.search(r'[A-Z]', pw)) and
        bool(re.search(r'[0-9]', pw)) and
        bool(re.search(r'[^A-Za-z0-9]', pw))
    )


# ─── Auth Routes ──────────────────────────────────────────────────────────────

@app.route('/')
def index():
    return redirect(url_for('dashboard') if 'user_id' in session else url_for('login'))

@app.route('/app')
def old_app():
    return redirect(url_for('dashboard'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    error = None
    if request.method == 'POST':
        email    = request.form.get('email', '').strip()
        password = request.form.get('password', '').strip()
        conn = get_db(); cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM user WHERE email=%s", (email,))
        user = cursor.fetchone()
        conn.close()
        if user and check_password_hash(user['password'], password):
            session.clear()
            session.update({
                'user_id':    user['user_id'],
                'name':       f"{user['first_name']} {user['last_name']}",
                'role':       user['role'],
                'email':      user['email'],
                'department': user.get('department', ''),
            })
            return redirect(url_for('dashboard'))
        error = 'Invalid email or password. Check the demo credentials below.'
    return render_template('login.html', error=error)

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    error = None
    if request.method == 'POST':
        fn   = request.form.get('first_name', '').strip()
        ln   = request.form.get('last_name',  '').strip()
        dept = request.form.get('department', '').strip()
        email= request.form.get('email', '').strip()
        pw   = request.form.get('password', '').strip()
        role = request.form.get('role', 'Student')
        # Only allow Student role from public signup
        if role not in ('Student',):
            role = 'Student'
        if not all([fn, ln, email, pw]):
            error = 'All fields are required.'
        elif not _valid_password(pw):
            error = ('Your password must be at least 8 characters and include '
                     'at least one uppercase letter, one number, and one special character.')
        else:
            conn = get_db(); cursor = conn.cursor()
            try:
                cursor.execute(
                    "INSERT INTO user (first_name,last_name,department,email,password,role)"
                    " VALUES (%s,%s,%s,%s,%s,%s)",
                    (fn, ln, dept, email, generate_password_hash(pw), role))
                conn.commit(); uid = cursor.lastrowid; conn.close()
                session.update({'user_id': uid, 'name': f"{fn} {ln}",
                                'role': role, 'email': email, 'department': dept})
                return redirect(url_for('dashboard'))
            except mysql.connector.IntegrityError:
                conn.close()
                error = 'Email already registered. Please log in.'
    return render_template('signup.html', error=error)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


# ─── Forgot Password ──────────────────────────────────────────────────────────

@app.route('/forgot-password', methods=['GET', 'POST'])
def forgot_password():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    message = None
    error   = None
    if request.method == 'POST':
        email = request.form.get('email', '').strip()
        if not email:
            error = 'Please enter your email address.'
        else:
            conn = get_db(); cursor = conn.cursor(dictionary=True)
            cursor.execute("SELECT user_id, first_name FROM user WHERE email=%s", (email,))
            user = cursor.fetchone(); conn.close()
            # Always show a success message to prevent email enumeration
            message = ('If an account with that email exists, a password reset '
                       'link has been sent. Please contact your administrator.')
    return render_template('forgot_password.html', message=message, error=error)


# ─── Dashboard ────────────────────────────────────────────────────────────────

@app.route('/dashboard')
@login_required
def dashboard():
    conn = get_db(); cursor = conn.cursor(dictionary=True)

    cursor.execute("SELECT * FROM event WHERE date >= CURDATE() ORDER BY date ASC LIMIT 4")
    upcoming_events = cursor.fetchall()
    for e in upcoming_events:
        e.setdefault('end_date', e['date'])
        e.setdefault('description', '')

    cursor.execute(
        "SELECT * FROM announcement ORDER BY priority DESC, created_at DESC LIMIT 4")
    announcements = cursor.fetchall()

    cursor.execute("SELECT COUNT(*) c FROM resources WHERE status='Available'")
    avail = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM booking WHERE user_id=%s", (session['user_id'],))
    my_cnt = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM event WHERE date >= CURDATE()")
    up_cnt = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM booking WHERE booking_status='pending'")
    pend_cnt = cursor.fetchone()['c']
    cursor.execute(
        "SELECT resource_id,resource_name,location,capacity,status"
        " FROM resources WHERE status='Available' ORDER BY resource_name LIMIT 6")
    quick_res = cursor.fetchall()

    conn.close()
    return render_template('dashboard.html',
        upcoming_events=upcoming_events, announcements=announcements,
        avail_resources=avail, my_bookings_count=my_cnt,
        upcoming_count=up_cnt, pending_count=pend_cnt,
        quick_resources=quick_res)


# ─── Events ───────────────────────────────────────────────────────────────────

@app.route('/events')
@login_required
def events():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM event ORDER BY date ASC")
    all_events = cursor.fetchall()
    cursor.execute("SELECT COUNT(*) c FROM event WHERE date >= CURDATE()")
    upcoming_count = cursor.fetchone()['c']
    conn.close()
    for e in all_events:
        e.setdefault('end_date', e['date'])
        e.setdefault('description', '')
    return render_template('events.html', events=all_events,
                           upcoming_count=upcoming_count,
                           today_str=str(__import__('datetime').date.today()))

@app.route('/events/<int:eid>')
@login_required
def event_detail(eid):
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM event WHERE event_id=%s", (eid,))
    event = cursor.fetchone()
    if not event:
        conn.close(); return redirect(url_for('events'))
    event.setdefault('end_date', event['date'])
    event.setdefault('description', '')
    cursor.execute("""
        SELECT DISTINCT r.resource_id, r.resource_name, r.location, r.capacity, r.status
        FROM booking b JOIN resources r ON b.resource_id=r.resource_id
        WHERE b.event_id=%s
    """, (eid,))
    resources_used = cursor.fetchall()
    conn.close()
    return render_template('event_detail.html', event=event, resources_used=resources_used)


# ─── Resources ────────────────────────────────────────────────────────────────

@app.route('/resources-page')
@login_required
def resources_page():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT r.resource_id, r.resource_name, r.location, r.capacity, r.status,
               ri.name AS incharge_name
        FROM resources r
        LEFT JOIN resource_incharge ri ON r.incharge_id=ri.incharge_id
        ORDER BY r.status DESC, r.resource_name
    """)
    all_res = cursor.fetchall(); conn.close()
    return render_template('resources.html', resources=all_res)


# ─── Booking ──────────────────────────────────────────────────────────────────

@app.route('/booking', methods=['GET', 'POST'])
@login_required
def booking_page():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT resource_id,resource_name,location,capacity FROM resources"
        " WHERE status='Available' ORDER BY resource_name")
    resources = cursor.fetchall()
    cursor.execute("SELECT event_id,event_name,date FROM event ORDER BY date ASC")
    evts = cursor.fetchall()
    for e in evts: e.setdefault('end_date', e['date'])
    error = None

    # ── Booking History (default: past month) ─────────────────────────
    period = request.args.get('period', 'month')
    if period == 'week':
        since_clause = "AND b.start_datetime >= DATE_SUB(NOW(), INTERVAL 7 DAY)"
    else:
        since_clause = "AND b.start_datetime >= DATE_SUB(NOW(), INTERVAL 30 DAY)"

    cursor.execute(f"""
        SELECT b.booking_id, r.resource_name, r.location, e.event_name,
               b.start_datetime, b.end_datetime, b.booking_status
        FROM booking b
        JOIN resources r ON b.resource_id=r.resource_id
        LEFT JOIN event e ON b.event_id=e.event_id
        WHERE b.user_id=%s {since_clause}
        ORDER BY b.booking_id DESC
    """, (session['user_id'],))
    booking_history = cursor.fetchall()
    for b in booking_history:
        b['start_datetime'] = str(b['start_datetime'])
        b['end_datetime']   = str(b['end_datetime'])

    if request.method == 'POST':
        rid   = request.form.get('resource_id')
        date  = request.form.get('date')
        st    = request.form.get('start_time')
        et    = request.form.get('end_time')
        eid   = request.form.get('event_id') or None
        ename = request.form.get('event_name', '').strip()

        if not all([rid, date, st, et]):
            error = 'Please complete all required fields.'
        elif st >= et:
            error = 'End time must be after start time.'
        else:
            start_dt = f"{date} {st}:00"
            end_dt   = f"{date} {et}:00"
            cursor.execute("""
                SELECT booking_id FROM booking
                WHERE resource_id=%s AND booking_status!='cancelled'
                  AND NOT (%s >= end_datetime OR %s <= start_datetime)
            """, (rid, start_dt, end_dt))
            if cursor.fetchone():
                error = 'This resource is already booked for that time slot. Pick a different time.'
            else:
                if not eid and ename:
                    cursor.execute(
                        "INSERT INTO event (event_name,date,organiser,location) VALUES (%s,%s,%s,'TBD')",
                        (ename, date, session['name']))
                    conn.commit(); eid = cursor.lastrowid
                cursor.execute("""
                    INSERT INTO booking
                      (user_id,resource_id,start_datetime,end_datetime,booking_status,event_id)
                    VALUES (%s,%s,%s,%s,'pending',%s)
                """, (session['user_id'], rid, start_dt, end_dt, eid))
                conn.commit(); bid = cursor.lastrowid; conn.close()
                return redirect(url_for('my_bookings') + f'?success={bid}')

    conn.close()
    return render_template('booking.html', resources=resources, events=evts, error=error,
                           preselect_resource=request.args.get('resource_id'),
                           preselect_event=request.args.get('event_id'),
                           booking_history=booking_history, period=period)


# ─── My Bookings ──────────────────────────────────────────────────────────────

@app.route('/my-bookings')
@login_required
def my_bookings():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT b.booking_id, r.resource_name, r.location, e.event_name,
               b.start_datetime, b.end_datetime, b.booking_status
        FROM booking b
        JOIN resources r ON b.resource_id=r.resource_id
        LEFT JOIN event e  ON b.event_id=e.event_id
        WHERE b.user_id=%s ORDER BY b.booking_id DESC
    """, (session['user_id'],))
    bookings = cursor.fetchall(); conn.close()
    for b in bookings:
        b['start_datetime'] = str(b['start_datetime'])
        b['end_datetime']   = str(b['end_datetime'])
    return render_template('my_bookings.html', bookings=bookings,
                           success_id=request.args.get('success'))

@app.route('/cancel-my-booking/<int:bid>', methods=['POST'])
@login_required
def cancel_my_booking(bid):
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "UPDATE booking SET booking_status='cancelled' WHERE booking_id=%s AND user_id=%s",
        (bid, session['user_id']))
    conn.commit(); conn.close()
    return redirect(url_for('my_bookings'))


# ─── Campus Map ───────────────────────────────────────────────────────────────

@app.route('/campus-map')
@login_required
def campus_map():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT resource_id,resource_name,location,capacity,status"
        " FROM resources ORDER BY location, resource_name")
    resources = cursor.fetchall(); conn.close()
    buildings = {}
    for r in resources:
        loc = r['location']
        bld = loc.split(' - ')[0] if ' - ' in loc else loc.split(',')[0].strip()
        buildings.setdefault(bld, []).append(r)
    return render_template('campus_map.html', buildings=buildings)


# ─── Admin ────────────────────────────────────────────────────────────────────

@app.route('/admin')
@admin_required
def admin_panel():
    conn = get_db(); cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT b.booking_id,
               CONCAT(u.first_name,' ',u.last_name) AS user_name,
               u.department, r.resource_name, e.event_name,
               b.start_datetime, b.end_datetime, b.booking_status
        FROM booking b
        JOIN user u      ON b.user_id=u.user_id
        JOIN resources r ON b.resource_id=r.resource_id
        LEFT JOIN event e ON b.event_id=e.event_id
        ORDER BY FIELD(b.booking_status,'pending','confirmed','cancelled'),
                 b.booking_id DESC
    """)
    all_bookings = cursor.fetchall()
    for b in all_bookings:
        b['start_datetime'] = str(b['start_datetime'])
        b['end_datetime']   = str(b['end_datetime'])

    cursor.execute("SELECT * FROM event ORDER BY date DESC")
    all_events = cursor.fetchall()
    for e in all_events:
        e.setdefault('end_date', e['date'])
        e.setdefault('description', '')

    cursor.execute("""
        SELECT r.*, ri.name AS incharge_name
        FROM resources r
        LEFT JOIN resource_incharge ri ON r.incharge_id=ri.incharge_id
        ORDER BY r.resource_name
    """)
    all_resources = cursor.fetchall()

    cursor.execute("SELECT COUNT(*) c FROM booking WHERE booking_status='pending'")
    pend = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM booking WHERE booking_status='confirmed'")
    conf = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM booking")
    total = cursor.fetchone()['c']
    cursor.execute("SELECT COUNT(*) c FROM user")
    users = cursor.fetchone()['c']

    conn.close()
    return render_template('admin.html',
        all_bookings=all_bookings, all_events=all_events,
        all_resources=all_resources,
        pending_count=pend, confirmed_count=conf,
        total_bookings=total, user_count=users)

@app.route('/admin/approve/<int:bid>', methods=['POST'])
@admin_required
def approve_booking(bid):
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "UPDATE booking SET booking_status='confirmed', approved_by=%s WHERE booking_id=%s",
        (session['user_id'], bid))
    conn.commit(); conn.close()
    return redirect(url_for('admin_panel'))

@app.route('/admin/reject/<int:bid>', methods=['POST'])
@admin_required
def reject_booking(bid):
    conn = get_db(); cursor = conn.cursor()
    cursor.execute("UPDATE booking SET booking_status='cancelled' WHERE booking_id=%s", (bid,))
    conn.commit(); conn.close()
    return redirect(url_for('admin_panel'))

@app.route('/admin/create-event', methods=['POST'])
@admin_required
def create_event():
    f = request.form
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO event (event_name,date,end_date,location,organiser,description)"
        " VALUES (%s,%s,%s,%s,%s,%s)",
        (f.get('event_name'), f.get('date'), f.get('end_date') or f.get('date'),
         f.get('location'), f.get('organiser'), f.get('description','')))
    conn.commit(); conn.close()
    return redirect(url_for('admin_panel') + '#tab-events')

@app.route('/admin/add-resource', methods=['POST'])
@admin_required
def add_resource():
    f = request.form
    av_from = f.get('available_from') or None
    av_to   = f.get('available_to')   or None
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO resources (resource_name,resource_type,location,capacity,status,available_from,available_to)"
        " VALUES (%s,%s,%s,%s,'Available',%s,%s)",
        (f.get('resource_name'), f.get('resource_type') or None,
         f.get('location'), f.get('capacity') or None, av_from, av_to))
    conn.commit(); conn.close()
    return redirect(url_for('admin_panel') + '#tab-resources')

@app.route('/admin/add-resource-ajax', methods=['POST'])
@admin_required
def add_resource_ajax():
    """AJAX endpoint — returns JSON."""
    f = request.form
    name    = f.get('resource_name', '').strip()
    rtype   = f.get('resource_type', '').strip() or None
    loc     = f.get('location', '').strip()
    cap     = f.get('capacity', '').strip() or None
    av_from = f.get('available_from', '').strip() or None
    av_to   = f.get('available_to', '').strip()   or None

    # Server-side validation
    if not name:
        return jsonify({'ok': False, 'error': 'Resource name is required.'}), 400
    if not loc:
        return jsonify({'ok': False, 'error': 'Location is required.'}), 400
    if cap:
        try:
            cap_int = int(cap)
            if cap_int < 1 or cap_int > 5000:
                return jsonify({'ok': False, 'error': 'Capacity must be between 1 and 5000.'}), 400
        except ValueError:
            return jsonify({'ok': False, 'error': 'Capacity must be a number.'}), 400
    if av_from and av_to and av_from >= av_to:
        return jsonify({'ok': False, 'error': '"Available To" must be after "Available From".'}), 400

    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO resources (resource_name,resource_type,location,capacity,status,available_from,available_to)"
        " VALUES (%s,%s,%s,%s,'Available',%s,%s)",
        (name, rtype, loc, cap or None, av_from, av_to))
    conn.commit()
    rid = cursor.lastrowid; conn.close()
    return jsonify({'ok': True, 'resource': {
        'resource_id':   rid,
        'resource_name': name,
        'resource_type': rtype or 'Other',
        'location':      loc,
        'capacity':      cap,
        'status':        'Available',
        'available_from': av_from,
        'available_to':   av_to,
    }})


@app.route('/admin/delete-resource/<int:rid>', methods=['POST'])
@admin_required
def delete_resource(rid):
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "UPDATE booking SET booking_status='cancelled' WHERE resource_id=%s AND booking_status IN ('pending','confirmed')",
        (rid,))
    cursor.execute("DELETE FROM resources WHERE resource_id=%s", (rid,))
    conn.commit(); conn.close()
    return redirect(url_for('admin_panel') + '#tab-resources')

@app.route('/admin/delete-resource-ajax/<int:rid>', methods=['POST'])
@admin_required
def delete_resource_ajax(rid):
    """AJAX endpoint — returns JSON."""
    conn = get_db(); cursor = conn.cursor()
    cursor.execute(
        "UPDATE booking SET booking_status='cancelled' WHERE resource_id=%s AND booking_status IN ('pending','confirmed')",
        (rid,))
    cancelled = cursor.rowcount
    cursor.execute("DELETE FROM resources WHERE resource_id=%s", (rid,))
    deleted = cursor.rowcount
    conn.commit(); conn.close()
    if deleted:
        return jsonify({'ok': True, 'bookings_cancelled': cancelled})
    return jsonify({'ok': False, 'error': 'Resource not found.'}), 404

@app.route('/admin/toggle-resource/<int:rid>', methods=['POST'])
@admin_required
def toggle_resource(rid):
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT status FROM resources WHERE resource_id=%s", (rid,))
    row = cursor.fetchone()
    if row:
        new_status = 'Unavailable' if row['status'] == 'Available' else 'Available'
        cursor.execute("UPDATE resources SET status=%s WHERE resource_id=%s", (new_status, rid))
        conn.commit()
    conn.close()
    return redirect(url_for('admin_panel') + '#tab-resources')

@app.route('/admin/toggle-resource-ajax/<int:rid>', methods=['POST'])
@admin_required
def toggle_resource_ajax(rid):
    """AJAX endpoint — returns JSON."""
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT status FROM resources WHERE resource_id=%s", (rid,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return jsonify({'ok': False, 'error': 'Resource not found.'}), 404
    new_status = 'Unavailable' if row['status'] == 'Available' else 'Available'
    cursor.execute("UPDATE resources SET status=%s WHERE resource_id=%s", (new_status, rid))
    conn.commit(); conn.close()
    return jsonify({'ok': True, 'new_status': new_status})


# ─── About ────────────────────────────────────────────────────────────────────

@app.route('/about')
@login_required
def about():
    return render_template('about.html')


# ─── Legacy JSON API (kept for backwards compat) ──────────────────────────────

@app.route('/resources')
def get_resources():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT r.resource_id, r.resource_name, r.location, r.capacity, r.status,
               ri.name AS incharge_name
        FROM resources r
        LEFT JOIN resource_incharge ri ON r.incharge_id=ri.incharge_id
        ORDER BY r.status DESC, r.resource_name
    """)
    data = cursor.fetchall(); conn.close()
    return jsonify(data)

@app.route('/bookings')
def all_bookings_api():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT b.booking_id, CONCAT(u.first_name,' ',u.last_name) AS user_name,
               u.department, r.resource_name, r.location,
               b.start_datetime, b.end_datetime, b.booking_status
        FROM booking b
        JOIN user u      ON b.user_id=u.user_id
        JOIN resources r ON b.resource_id=r.resource_id
        ORDER BY b.booking_id DESC
    """)
    rows = cursor.fetchall(); conn.close()
    for r in rows:
        r['start_datetime'] = str(r['start_datetime'])
        r['end_datetime']   = str(r['end_datetime'])
    return jsonify(rows)

@app.route('/create-booking', methods=['POST'])
def create_booking():
    d = request.json
    uid, rid, st, et = d.get('user_id'), d.get('resource_id'), d.get('start_time'), d.get('end_time')
    if not all([uid, rid, st, et]):
        return jsonify({'message': 'All fields required'}), 400
    if st >= et:
        return jsonify({'message': 'End time must be after start time'}), 400
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT booking_id FROM booking WHERE resource_id=%s AND booking_status!='cancelled'"
        " AND NOT (%s>=end_datetime OR %s<=start_datetime)", (rid, st, et))
    if cursor.fetchone():
        conn.close(); return jsonify({'message': 'Resource already booked'}), 409
    cursor.execute(
        "INSERT INTO booking (user_id,resource_id,start_datetime,end_datetime,booking_status)"
        " VALUES (%s,%s,%s,%s,'confirmed')", (uid, rid, st, et))
    conn.commit(); bid = cursor.lastrowid; conn.close()
    return jsonify({'message': 'Booking successful', 'booking_id': bid})

@app.route('/cancel-booking/<int:bid>', methods=['POST'])
def cancel_booking(bid):
    conn = get_db(); cursor = conn.cursor()
    cursor.execute("UPDATE booking SET booking_status='cancelled' WHERE booking_id=%s", (bid,))
    conn.commit(); aff = cursor.rowcount; conn.close()
    if aff: return jsonify({'message': 'Cancelled'})
    return jsonify({'message': 'Not found'}), 404

@app.route('/users')
def get_users():
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute(
        "SELECT user_id,first_name,last_name,department,role FROM user ORDER BY first_name")
    data = cursor.fetchall(); conn.close()
    return jsonify(data)


@app.route('/get-events')
def get_map_events_api():
    """Legacy endpoint — kept for compatibility."""
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT location, event_name FROM event WHERE date >= CURDATE()")
    events = cursor.fetchall(); conn.close()

    buildings_events = {}
    for e in events:
        loc = e['location'] or 'Main Campus'
        buildings_events.setdefault(loc, []).append(e['event_name'])

    BUILDING_COORDS = _building_coord_map()
    result = []
    for name, coord in BUILDING_COORDS.items():
        result.append({'name': name, 'coord': coord,
                       'events': buildings_events.get(name, ['No upcoming events'])})
    return jsonify(result)


@app.route('/get-building-resources')
@login_required
def get_building_resources():
    """Returns all buildings with their resources (id, name, capacity, status)
    and a lat/lng coordinate for the campus map marker."""
    conn = get_db(); cursor = conn.cursor(dictionary=True)
    cursor.execute("""
        SELECT r.resource_id, r.resource_name, r.location, r.capacity, r.status
        FROM resources r ORDER BY r.location, r.resource_name
    """)
    resources = cursor.fetchall(); conn.close()

    # Group by building (first segment of location before ' - ' or ',')
    buildings = {}
    for r in resources:
        loc = r['location'] or 'Other'
        bld = loc.split(' - ')[0].split(',')[0].strip()
        buildings.setdefault(bld, []).append({
            'resource_id':   r['resource_id'],
            'resource_name': r['resource_name'],
            'capacity':      r['capacity'],
            'status':        r['status'],
            'location':      r['location'],
        })

    BUILDING_COORDS = _building_coord_map()

    result = []
    for bld, res_list in buildings.items():
        # Use mapped coord or fallback to campus center
        coord = BUILDING_COORDS.get(bld, [18.48636, 73.81600])
        result.append({'name': bld, 'coord': coord, 'resources': res_list})

    return jsonify(result)


def _building_coord_map():
    """
    Returns a dict mapping building names → [lat, lng] inside
    the Cummins College boundary polygon.
    Adjust these to match your actual building positions.
    """
    return {
        'Main Building':      [18.4863,  73.8160],
        'IT Department':      [18.4858,  73.8161],
        'Building A':         [18.4862,  73.8157],
        'Building B':         [18.4865,  73.8163],
        'Building C':         [18.4860,  73.8165],
        'Main Auditorium':    [18.4867,  73.8162],
        'Seminar Hall':       [18.4866,  73.8158],
        'Conference Room':    [18.4864,  73.8164],
        'Lab 1':              [18.4861,  73.8159],
        'Lab 2':              [18.4857,  73.8164],
        'Lab 3':              [18.4859,  73.8162],
        'Suswaad Canteen':    [18.4862,  73.8166],
        'Main Campus':        [18.48636, 73.81600],
    }


if __name__ == '__main__':
    app.run(debug=True)