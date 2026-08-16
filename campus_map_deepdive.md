# 🗺️ Campus Map — Deep Dive Explanation

---

## ✅ SECTION 1 — What is Leaflet.js and Why Do We Use It?

### The Problem
You want to show a real map inside a web page with clickable markers.  
Options:
- **Google Maps API** → requires a credit card, charges money after free tier
- **Leaflet.js** → 100% free, open source, no API key needed

### What Leaflet Actually Is
Leaflet is a **JavaScript library** — a collection of pre-written code that gives you tools to:
- Draw an interactive map
- Place pins/markers at GPS coordinates
- Show popups when you click things
- Draw shapes (polygons, circles)
- Handle zoom, pan, scroll

You include it in your HTML with two lines:
```html
<!-- Step 1: CSS (makes the map look good) -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>

<!-- Step 2: JavaScript (gives you the L.map(), L.marker() etc. functions) -->
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
```
These download the library from the internet (unpkg.com is a free CDN).  
After this, you have access to a global object called `L` which is your entry point to everything.

---

### How Does the Map Actually Appear? (Tile System)

A world map is **huge**. Leaflet doesn't download one giant image.  
Instead, the world is divided into tiny **256×256 pixel squares called tiles**.

```
Zoom Level 1 (whole world):        Zoom Level 18 (building level):
┌──────────┬──────────┐            ┌──┬──┬──┬──┬──┬──┬──┬──┐
│          │          │            ├──┼──┼──┼──┼──┼──┼──┼──┤
│  tile 0  │  tile 1  │            ├──┼──┼──┼──┼──┼──┼──┼──┤
│          │          │            ├──┼──┼──┼──┼──┼──┼──┼──┤
├──────────┼──────────┤            ├──┼──┼──┼──┼──┼──┼──┼──┤
│          │          │            └──┴──┴──┴──┴──┴──┴──┴──┘
│  tile 2  │  tile 3  │            Each tile = 256x256 pixels
└──────────┴──────────┘
```

At zoom 18, millions of tiles exist. Leaflet only downloads the ones currently visible on screen.

```javascript
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 21
}).addTo(map);
```

The URL has placeholders:
- `{s}` → **subdomain** (a, b, or c) — OpenStreetMap has 3 servers, Leaflet rotates between them for speed
- `{z}` → **zoom level** (e.g. 18)
- `{x}` → **tile column** (a number calculated from longitude)
- `{y}` → **tile row** (a number calculated from latitude)

Leaflet **automatically** fills in these values as you zoom/pan. You never touch this manually.

---

## ✅ SECTION 2 — What Are Coordinates and How Do We Get Them?

### Latitude & Longitude — The Basics

Imagine the Earth as a grid:

```
                        90°N (North Pole)
                            |
                            |
-180°W ─────────────────── 0° ─────────────────── 180°E
        (West)         (Equator)              (East)
                            |
                            |
                        90°S (South Pole)
```

Every point on Earth has:
- **Latitude** = how far north or south of the equator → ranges from -90 to +90
- **Longitude** = how far east or west of the prime meridian (UK) → ranges from -180 to +180

**Cummins College, Pune example:**
```
Latitude:  18.4863   means "18.4863 degrees North of equator" (India is north)
Longitude: 73.8160   means "73.8160 degrees East of prime meridian" (India is east)
```

In code we always write: `[latitude, longitude]` — **lat first, lng second**.

### How Do We Know the Coordinates of Each Building?

**We hardcoded them manually.** Here's how to get them:

1. Open [maps.google.com](https://maps.google.com)
2. Find your college on the map
3. Navigate to a specific building
4. **Right-click** directly on the building
5. The first item in the menu shows the coordinates like: `18.4862, 73.8157`
6. Copy those numbers into `_building_coord_map()` in `app.py`

> This is entirely manual — there's no magic. Someone looked at Google Maps and copied the numbers for each building.

---

## ✅ SECTION 3 — The Backend (`app.py`) — Line by Line

This is the main area you said you didn't understand. Let's go **very slowly**.

### The Big Picture of What the Backend Does

```
MySQL Database has this:
┌─────────────────┬────────────────────────────────┬──────────┬───────────┐
│ resource_name   │ location                       │ capacity │ status    │
├─────────────────┼────────────────────────────────┼──────────┼───────────┤
│ Lab 1           │ Building A - Floor 1           │ 40       │ Available │
│ Lab 2           │ Building A - Floor 2           │ 35       │ Available │
│ Conference Rm A │ Building B - Floor 1           │ 20       │ Available │
│ Seminar Hall    │ Main Block                     │ 100      │ Available │
│ Projector 1     │ Store Room                     │ 1        │ Available │
└─────────────────┴────────────────────────────────┴──────────┴───────────┘

The backend needs to:
1. Group these resources by their BUILDING (ignore the "Floor X" part)
2. Find the GPS coordinates of each building
3. Return one entry per building, with all its resources inside

Output JSON (what gets sent to browser):
[
  { "name": "Building A", "coord": [18.4862, 73.8157], 
    "resources": [Lab 1, Lab 2] },
  { "name": "Building B", "coord": [18.4865, 73.8163], 
    "resources": [Conference Rm A] },
  { "name": "Main Block",  "coord": [18.4863, 73.8160], 
    "resources": [Seminar Hall] }
]
```

---

### Step 1: The Route Definition

```python
@app.route('/get-building-resources')
@login_required
def get_building_resources():
```

- `@app.route('/get-building-resources')` → when the browser goes to this URL, run this function
- `@login_required` → only logged-in users can call this (security)
- This function is what the JavaScript calls with `fetch('/get-building-resources')`

---

### Step 2: Query the Database

```python
conn = get_db()
cursor = conn.cursor(dictionary=True)

cursor.execute("""
    SELECT r.resource_id, r.resource_name, r.location, r.capacity, r.status
    FROM resources r ORDER BY r.location, r.resource_name
""")
resources = cursor.fetchall()
conn.close()
```

- `get_db()` → opens a MySQL connection
- `cursor(dictionary=True)` → results come back as dictionaries like `{"resource_name": "Lab 1", ...}` instead of tuples
- The SQL selects all resources, ordered by location then name
- `fetchall()` → gets every row as a list of dicts
- `conn.close()` → closes the database connection

After this, `resources` looks like:
```python
[
  {"resource_id": 201, "resource_name": "Lab 1",      "location": "Building A - Floor 1", "capacity": 40,  "status": "Available"},
  {"resource_id": 202, "resource_name": "Lab 2",      "location": "Building A - Floor 2", "capacity": 35,  "status": "Available"},
  {"resource_id": 203, "resource_name": "Conf Rm A",  "location": "Building B - Floor 1", "capacity": 20,  "status": "Available"},
  {"resource_id": 205, "resource_name": "Seminar Hall","location": "Main Block",           "capacity": 100, "status": "Available"},
]
```

---

### Step 3: Group Resources by Building (THE KEY LOGIC)

```python
buildings = {}
for r in resources:
    loc = r['location'] or 'Other'
    bld = loc.split(' - ')[0].split(',')[0].strip()
    buildings.setdefault(bld, []).append({...})
```

Let's trace through this **line by line** with an example.

#### Line: `buildings = {}`
Creates an empty dictionary. We'll fill it as we loop.

#### Line: `for r in resources:`
Loops over each resource row from the database, one at a time.  
On first iteration: `r = {"resource_name": "Lab 1", "location": "Building A - Floor 1", ...}`

#### Line: `loc = r['location'] or 'Other'`
Gets the location string. The `or 'Other'` handles the case where location is `None` (NULL in DB).
```
loc = "Building A - Floor 1"
```

#### Line: `bld = loc.split(' - ')[0].split(',')[0].strip()`

This is the most important line. It **extracts just the building name** from the full location string.  
Let's dissect it step by step:

**Example 1:** `loc = "Building A - Floor 1"`

```python
# Step A: loc.split(' - ')
# splits on " - " (space-dash-space)
# Result: ["Building A", "Floor 1"]

# Step B: [0]
# Takes the first part
# Result: "Building A"

# Step C: .split(',')
# splits on comma (for locations like "Block A, Wing 2")
# Result: ["Building A"]  ← only one element since no comma

# Step D: [0]
# Takes the first part again
# Result: "Building A"

# Step E: .strip()
# removes any leading/trailing spaces
# Result: "Building A"
```

**Example 2:** `loc = "Building B - Floor 1"`
```
→ split(' - ')[0] → "Building B"
→ split(',')[0]   → "Building B"
→ strip()         → "Building B"
```

**Example 3:** `loc = "Main Block"`  (no " - " in it)
```
→ split(' - ') → ["Main Block"]  (only 1 element, nothing to split)
→ [0]          → "Main Block"
→ split(',')   → ["Main Block"]
→ [0]          → "Main Block"
→ strip()      → "Main Block"
```

**Example 4:** `loc = "Store Room, Section B"`  (comma style)
```
→ split(' - ') → ["Store Room, Section B"]
→ [0]          → "Store Room, Section B"
→ split(',')   → ["Store Room", " Section B"]
→ [0]          → "Store Room"
→ strip()      → "Store Room"
```

So the logic handles three location formats:
- `"Building A - Floor 1"` → extracts `"Building A"`
- `"Main Block"` → keeps `"Main Block"`
- `"Store Room, Section B"` → extracts `"Store Room"`

---

#### Line: `buildings.setdefault(bld, []).append({...})`

This line **groups resources under their building**. Let's understand `.setdefault()`:

```python
# buildings.setdefault(key, default_value)
# Meaning:
#   IF key doesn't exist yet in buildings → add it with the default value
#   THEN return buildings[key]

# Example trace:

# --- Iteration 1: r = Lab 1, bld = "Building A" ---
buildings.setdefault("Building A", [])
# buildings = {"Building A": []}    ← key added with empty list
# then .append({resource info})
# buildings = {"Building A": [{"resource_id": 201, "resource_name": "Lab 1", ...}]}

# --- Iteration 2: r = Lab 2, bld = "Building A" ---
buildings.setdefault("Building A", [])
# "Building A" already exists → returns existing list (doesn't overwrite!)
# then .append({resource info})
# buildings = {"Building A": [Lab 1 dict, Lab 2 dict]}

# --- Iteration 3: r = Conf Rm A, bld = "Building B" ---
buildings.setdefault("Building B", [])
# "Building B" doesn't exist → adds it
# then .append({resource info})
# buildings = {
#   "Building A": [Lab 1 dict, Lab 2 dict],
#   "Building B": [Conf Rm A dict]
# }

# --- Iteration 4: r = Seminar Hall, bld = "Main Block" ---
# buildings = {
#   "Building A": [Lab 1, Lab 2],
#   "Building B": [Conf Rm A],
#   "Main Block":  [Seminar Hall]
# }
```

The `append` part adds a clean dictionary with just the fields we need:
```python
buildings.setdefault(bld, []).append({
    'resource_id':   r['resource_id'],    # needed for the "Book" link
    'resource_name': r['resource_name'],  # shown in popup
    'capacity':      r['capacity'],        # "Capacity: 40" shown in popup
    'status':        r['status'],          # determines green/red dot
    'location':      r['location'],        # full location text
})
```

---

### Step 4: Load the Coordinate Dictionary

```python
BUILDING_COORDS = _building_coord_map()
```

This calls the function that returns the hardcoded dict:
```python
def _building_coord_map():
    return {
        'Main Building':   [18.4863, 73.8160],
        'IT Department':   [18.4858, 73.8161],
        'Building A':      [18.4862, 73.8157],
        'Building B':      [18.4865, 73.8163],
        'Building C':      [18.4860, 73.8165],
        'Main Auditorium': [18.4867, 73.8162],
        'Seminar Hall':    [18.4866, 73.8158],
        'Conference Room': [18.4864, 73.8164],
        'Lab 1':           [18.4861, 73.8159],
        'Lab 2':           [18.4857, 73.8164],
        'Lab 3':           [18.4859, 73.8162],
        'Suswaad Canteen': [18.4862, 73.8166],
        'Main Campus':     [18.48636, 73.81600],
    }
```

> **Important:** The keys in this dict (`'Building A'`, `'Building B'` etc.) must **exactly match** the building names extracted from the `location` column in the database.  
> If the DB has `"Building A - Floor 1"` then the extracted name is `"Building A"` — so the dict key must be `"Building A"` (not `"building a"` or `"BuildingA"`).

After this line:
```python
BUILDING_COORDS = {
  "Main Building":   [18.4863, 73.8160],
  "IT Department":   [18.4858, 73.8161],
  "Building A":      [18.4862, 73.8157],
  # ... more buildings
}
```

---

### Step 5: Combine Buildings with Coordinates

```python
result = []
for bld, res_list in buildings.items():
    coord = BUILDING_COORDS.get(bld, [18.48636, 73.81600])
    result.append({'name': bld, 'coord': coord, 'resources': res_list})
```

#### `buildings.items()`
Returns each key-value pair from the `buildings` dict:
```
("Building A", [Lab 1 dict, Lab 2 dict])
("Building B", [Conf Rm A dict])
("Main Block",  [Seminar Hall dict])
```

#### `BUILDING_COORDS.get(bld, [18.48636, 73.81600])`

`.get(key, default)` is a safe dictionary lookup:
```python
# If "Building A" exists in BUILDING_COORDS → returns [18.4862, 73.8157]
# If "Unknown Hall" doesn't exist → returns [18.48636, 73.81600] (campus center)

# This prevents a crash if a building in DB has no coordinate defined.
# It just places the marker at the center of campus as a fallback.
```

#### `result.append({...})`

Builds the final list that will become JSON:
```python
result = [
  {
    "name": "Building A",
    "coord": [18.4862, 73.8157],
    "resources": [
      {"resource_id": 201, "resource_name": "Lab 1", "capacity": 40, "status": "Available", ...},
      {"resource_id": 202, "resource_name": "Lab 2", "capacity": 35, "status": "Available", ...},
    ]
  },
  {
    "name": "Building B",
    "coord": [18.4865, 73.8163],
    "resources": [
      {"resource_id": 203, "resource_name": "Conf Rm A", "capacity": 20, ...}
    ]
  }
]
```

---

### Step 6: Return as JSON

```python
return jsonify(result)
```

`jsonify()` converts the Python list into a **JSON string** and sends it to the browser with the correct HTTP headers.

The browser receives something like:
```json
[
  {
    "name": "Building A",
    "coord": [18.4862, 73.8157],
    "resources": [
      {"resource_id": 201, "resource_name": "Lab 1", "capacity": 40, "status": "Available"}
    ]
  }
]
```

---

## ✅ SECTION 4 — The Frontend (JavaScript) — Line by Line

### Step 1: Initialize the Map

```javascript
const map = L.map('map', { zoomControl: true }).setView([18.48611, 73.8162], 18);
```

| Part | Meaning |
|------|---------|
| `L.map('map')` | Find the `<div id="map">` element and turn it into a map |
| `zoomControl: true` | Show the + / - zoom buttons |
| `.setView([18.48611, 73.8162], 18)` | Center the map on this lat/lng at zoom level 18 |

### Step 2: Load Map Tiles

```javascript
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  maxZoom: 21
}).addTo(map);
```

Downloads and displays the street map images. As you zoom/pan, new tiles are fetched automatically.

### Step 3: Draw Campus Boundary

```javascript
const cumminsCoords = [
  [18.4853467, 73.8164168],  // point 1
  [18.4856872, 73.8167004],  // point 2
  [18.4857316, 73.8168962],  // point 3
  // ... more points ...
  [18.4853467, 73.8164168],  // same as point 1 → closes the shape
];

const boundary = L.polygon(cumminsCoords, {
  color: '#0d47a1',     // border color
  weight: 2.5,          // border thickness (pixels)
  fillColor: '#1d4ed8', // inside fill color
  fillOpacity: 0.06,    // almost transparent (0 = invisible, 1 = solid)
}).addTo(map);
```

`L.polygon()` connects the dots in order and draws a closed shape.

```javascript
map.fitBounds(bounds, { padding: [30, 30] });
```
Automatically zooms and pans so the whole campus polygon fits in view.

### Step 4: Fetch Building Data from Flask

```javascript
fetch('/get-building-resources')   // calls the Flask route
  .then(r => r.json())             // parses the JSON response
  .then(buildings => {             // 'buildings' = the Python list we built
    // now place markers...
  });
```

`fetch()` makes an HTTP GET request to `/get-building-resources`. This is asynchronous — it doesn't block the page. When Flask responds, `.then()` runs with the data.

### Step 5: Place a Marker for Each Building

```javascript
buildings.forEach(bld => {
  const [lat, lng] = bld.coord;   // destructure: lat=18.4862, lng=73.8157
```

`bld.coord` is `[18.4862, 73.8157]`. The line `const [lat, lng] = bld.coord` is called **destructuring** — it splits the array into two named variables.

```javascript
  const marker = L.marker([lat, lng], { icon: markerIcon }).addTo(map);
```

`L.marker([lat, lng])` places a pin at that GPS coordinate. `.addTo(map)` makes it appear on screen.

### Step 6: Add Building Name Label

```javascript
marker.bindTooltip(bld.name, {
  permanent: true,         // always visible (not just on hover)
  direction: 'right',      // text appears to the right of the pin
  className: 'building-label',
  offset: [10, -20]        // shift the label 10px right and 20px up
});
```

A tooltip is normally a hover hint. Setting `permanent: true` makes it always show like a map label.

### Step 7: Hover and Click Popups

```javascript
let hoverTimer = null;

// When mouse enters the marker area:
marker.on('mouseover', function () {
  hoverTimer = setTimeout(() => {          // wait 200ms before opening
    popup.setContent(buildPopupHTML(bld.name, bld.resources));
    marker.bindPopup(popup).openPopup();   // open the popup
  }, 200);
});

// When mouse leaves:
marker.on('mouseout', function () {
  clearTimeout(hoverTimer);   // cancel if mouse moved away quickly
});
```

The `setTimeout` with 200ms delay prevents popups from flashing open every time your mouse accidentally passes over a marker.

### Step 8: Building the Popup HTML

```javascript
function buildPopupHTML(bldName, resources) {
  const avail = resources.filter(r => r.status === 'Available').length;
```

`filter()` creates a new array of only the resources where `status === 'Available'`. `.length` counts them.

```javascript
  const icon = bldName.toLowerCase().includes('lab')    ? '💻'
             : bldName.toLowerCase().includes('audit')  ? '🎙️'
             : '🏢';
```

This is a **chain of ternary operators** (shorthand if-else). If the building name contains "lab" → use laptop emoji, else if contains "audit" → use mic emoji, else → use building emoji.

```javascript
  resources.forEach(r => {
    const isAvailable = r.status === 'Available';

    const btnHTML = isAvailable
      ? `<a href="/booking?resource_id=${r.resource_id}">Book →</a>`
      : `<span class="busy">Busy</span>`;
```

- If available → show a **link** to the booking page with the resource ID in the URL
- If not → show a greyed-out "Busy" text (not a link)

The final HTML structure returned looks like:
```html
<div class="rp-card">
  <div class="rp-header">
    💻 Building A
    2 available · 3 total resources
  </div>
  <ul class="rp-list">
    <li>
      <div class="rp-resource">
        <span class="rp-dot available"></span>   ← green dot
        <div class="rp-info">
          <div class="rp-name">Lab 1</div>
          <div class="rp-cap">Capacity: 40</div>
        </div>
        <a class="rp-book-btn" href="/booking?resource_id=201">Book →</a>
      </div>
    </li>
    <!-- more resources... -->
  </ul>
  <div class="rp-footer">Click "Book →" to reserve</div>
</div>
```

---

## ✅ SECTION 5 — Complete Data Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  MySQL Database (resources table)                        │
│  Lab 1  | Building A - Floor 1 | 40 | Available         │
│  Lab 2  | Building A - Floor 2 | 35 | Available         │
│  Conf A | Building B - Floor 1 | 20 | Available         │
└────────────────────┬────────────────────────────────────┘
                     │  cursor.execute(SELECT ...)
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Python list: resources = [                             │
│    {"resource_name": "Lab 1", "location": "Building A   │
│     - Floor 1", "capacity": 40, "status": "Available"}, │
│    ...                                                  │
│  ]                                                      │
└────────────────────┬────────────────────────────────────┘
                     │  GROUP BY BUILDING (loc.split(' - ')[0])
                     ▼
┌─────────────────────────────────────────────────────────┐
│  buildings = {                                          │
│    "Building A": [Lab 1 dict, Lab 2 dict],              │
│    "Building B": [Conf A dict],                         │
│  }                                                      │
└────────────────────┬────────────────────────────────────┘
                     │  ATTACH COORDINATES
                     │  BUILDING_COORDS.get("Building A")
                     ▼
┌─────────────────────────────────────────────────────────┐
│  result = [                                             │
│    { "name": "Building A",                              │
│      "coord": [18.4862, 73.8157],                       │
│      "resources": [Lab 1, Lab 2] },                     │
│    { "name": "Building B",                              │
│      "coord": [18.4865, 73.8163],                       │
│      "resources": [Conf A] },                           │
│  ]                                                      │
└────────────────────┬────────────────────────────────────┘
                     │  return jsonify(result)
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Browser: fetch('/get-building-resources')              │
│  Receives JSON → loops through buildings                │
│  For each building:                                     │
│    L.marker([18.4862, 73.8157]) → places pin on map    │
│    bindTooltip("Building A") → shows label             │
│    on click → buildPopupHTML() → shows Lab 1, Lab 2    │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ SECTION 6 — Common Questions

### Q: How does the map know where Cummins College is?
**A:** We told it by calling `.setView([18.48611, 73.8162], 18)`. We found those numbers by going to Google Maps, finding the college, and right-clicking to get the coordinates.

### Q: Where do the building coordinates come from?
**A:** They were manually looked up on Google Maps and hardcoded in `_building_coord_map()`. This is manual work — someone visited Google Maps, right-clicked on each building, and copied the lat/lng.

### Q: What if a resource's building isn't in the coordinate dict?
**A:** The `.get(bld, [18.48636, 73.81600])` fallback kicks in. The marker appears at the campus center instead. You'd see it but in the wrong place — that's a sign you need to add that building to the dict.

### Q: Why split on ` - ` and then `,`?
**A:** Different locations are written differently in the DB:
- Some say `"Building A - Floor 2"` (uses ` - `)  
- Some say `"Store Room, Section B"` (uses `,`)
The code handles both formats.

### Q: What is `setdefault()`?
**A:** It's a safe way to add to a dictionary. If the key exists, return the existing value. If not, add it with the given default first, then return it. It's equivalent to:
```python
if bld not in buildings:
    buildings[bld] = []
buildings[bld].append(...)
```
