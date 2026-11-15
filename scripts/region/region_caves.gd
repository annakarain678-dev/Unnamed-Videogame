class_name RegionCaves
extends RefCounted
## The caves of the first region. They are not part of the height-field: each cave system is a set of
## tunnels and rooms described as a signed distance field (negative = open air), turned into a mesh by
## RegionBuilder in 48 m cubes, and it sits in the same world space under the terrain. So there is no
## loading screen: you walk down a ramp in the ground and you are in the cave.
##
## Where a cave opens to the surface, the cave mesh also builds the ground around the opening (the
## terrain skips those squares), so the mouth is carved naturally: the tunnel dips below the ground and
## the ground simply becomes its roof. No holes, lids or invisible walls.
##
##  - The underwater way: dive into the deep lake, down a shaft, along a drowned tunnel, and up
##    through a pool into the village's cavern (like the U-bend of a pipe: water on both ends, and the
##    pool inside the cavern is at the same level as the lake).
##  - The hatchery arm: a ramp into the ruins hill, a chamber (the hatchery), then a tunnel to the village.
##  - The smugglers' way: from the village cavern to a ramp in the quarry floor at the bandit camp.
##  - The Black: a winding passage down from the village cavern to a deep chamber with a pit.

const CELL := 1.5
const CELLS := 32
const CHUNK := CELL * CELLS
const ROUGHNESS := 1.1

# Key places other scripts need.
static var pool := Vector2.ZERO
static var village_floor := 0.0
static var hatchery := Vector3.ZERO     # center of the hatchery chamber floor
static var shaft := Vector2.ZERO
static var quarry_ramp := Vector2.ZERO
static var hatchery_mouth := Vector2.ZERO
static var pit := Vector3.ZERO          # the floor of the deep chamber at the bottom of the Black

static var _prims: Array = []
static var _flood: Array[Vector2] = []
static var _noise: FastNoiseLite
static var _ready_flag := false
## Cave cubes whose column of ground is built by the cave mesh too: Vector2i(cx, cz) -> true.
static var _ground_columns := {}
static var _extra_keys := {}


## Call once on the main thread, after RegionTerrain.setup().
static func setup() -> void:
	if _ready_flag:
		return
	_ready_flag = true
	_noise = FastNoiseLite.new()
	_noise.seed = 99
	_noise.frequency = 0.055
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_noise.fractal_octaves = 2
	var level := RegionTerrain.lake_level()
	var base := RegionTerrain.BASE
	var village := RegionTerrain.VILLAGE
	var lake := RegionTerrain.LAKE
	var ruins := RegionTerrain.RUINS
	var bandit := RegionTerrain.BANDIT
	village_floor = level + 3.0
	pool = village + Vector2(-45.0, -17.0)
	shaft = Vector2(lake.x + 10.0, lake.y)

	# --- The underwater way: lake shaft, drowned tunnel, pool, village cavern. ----------------
	var floor_y := RegionTerrain.height(shaft.x, shaft.y)
	var siphon := _route(shaft, pool, [
		floor_y + 2.5, level - 32.0, level - 40.0, level - 45.0, level - 46.0,
		level - 44.0, level - 38.0, level - 28.0, level - 16.0,
	] as Array[float], 12.0)
	siphon.append(Vector3(pool.x - 3.0, level - 4.0, pool.y - 2.0))
	_chain(siphon, [6.0, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.8, 5.0] as Array[float])
	for point in siphon:
		_flood.append(Vector2(point.x, point.z))
	_mouth(shaft)
	# The pool inside the cavern, at lake level.
	_capsule(Vector3(pool.x, level - 7.0, pool.y), Vector3(pool.x, level + 3.0, pool.y), 8.0, 8.0)
	# The village cavern: a wide room whose floor rises from the pool's edge.
	_chamber(Vector3(village.x, level + 12.0, village.y), Vector3(70.0, 22.0, 45.0), level, pool)

	# --- The hatchery arm. --------------------------------------------------------------------
	var hatch_floor := base - 4.0
	hatchery = Vector3(ruins.x, hatch_floor, ruins.y)
	_chamber(Vector3(ruins.x, hatch_floor + 10.0, ruins.y), Vector3(42.0, 14.0, 34.0), hatch_floor, Vector2(INF, INF))
	hatchery_mouth = ruins + Vector2(110.0, 40.0)
	var outer := hatchery_mouth + Vector2(0.94, 0.34) * 8.0
	var g0 := RegionTerrain.height(outer.x, outer.y)
	var entry := _route(outer, ruins + Vector2(32.0, 14.0), [g0 + 4.2, g0 - 2.0, base + 2.0, hatch_floor + 4.0] as Array[float], 0.0)
	_chain(entry, [4.6, 4.5, 4.5, 4.5] as Array[float])
	_mouth(hatchery_mouth)
	var arm := _route(ruins + Vector2(-10.0, 30.0), village + Vector2(5.0, 35.0), [
		hatch_floor + 4.0, level - 18.0, level - 24.0, level - 24.0, level - 24.0, level - 24.0, level - 14.0, level + 5.0,
	] as Array[float], 40.0)
	_chain(arm, [4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 5.0] as Array[float])

	# --- The smugglers' way: village cavern to a ramp in the quarry floor. --------------------
	quarry_ramp = bandit + Vector2(25.0, 5.0)
	var quarry_floor := base - RegionTerrain.QUARRY_FLOOR
	var east_end := village + Vector2(60.0, 5.0)
	var go := (east_end - quarry_ramp).normalized()
	var p2 := quarry_ramp + go * 70.0
	var smugglers: Array[Vector3] = [
		Vector3(quarry_ramp.x, quarry_floor + 4.2, quarry_ramp.y),
		Vector3(quarry_ramp.x + go.x * 30.0, quarry_floor - 2.0, quarry_ramp.y + go.y * 30.0),
		Vector3(p2.x, quarry_floor - 8.0, p2.y),
	]
	var rest := _route(p2, east_end, [quarry_floor - 8.0, level - 22.0, level - 24.0, level - 24.0, level - 14.0, level + 5.0] as Array[float], 30.0)
	for i in range(1, rest.size()):
		smugglers.append(rest[i])
	var smuggler_radii: Array[float] = []
	for i in smugglers.size():
		smuggler_radii.append(4.6 if i < 3 else 4.5)
	_chain(smugglers, smuggler_radii)
	_mouth(quarry_ramp)

	# --- The Black: a winding passage from the cavern's east side to a deep chamber. -----------
	var pit_xz := village + Vector2(-20.0, 150.0)
	var passage := _route(village + Vector2(45.0, 20.0), pit_xz, [
		level + 4.0, level - 10.0, level - 24.0, level - 38.0, level - 50.0, level - 56.0,
	] as Array[float], 55.0)
	_chain(passage, [5.0, 4.5, 4.5, 4.5, 4.5, 5.0] as Array[float])
	pit = Vector3(pit_xz.x, level - 56.0, pit_xz.y)
	_chamber(Vector3(pit_xz.x, level - 46.0, pit_xz.y), Vector3(24.0, 14.0, 24.0), level - 56.0, Vector2(INF, INF))


# --- Describing the caves ----------------------------------------------------------

## Points from `from` to `to` (both (x, z)) at the given heights, wandering a little side to side in
## between (but not at the ends).
static func _route(from: Vector2, to: Vector2, heights: Array[float], wander: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var along := to - from
	var side := Vector2(-along.y, along.x).normalized()
	var n := heights.size()
	for i in n:
		var t := float(i) / float(n - 1)
		var p := from + along * t + side * sin(t * TAU * 1.5) * wander * sin(t * PI)
		points.append(Vector3(p.x, heights[i], p.y))
	return points


static func _chain(points: Array[Vector3], radii: Array[float]) -> void:
	for i in points.size() - 1:
		_capsule(points[i], points[i + 1], radii[i], radii[i + 1])


static func _capsule(a: Vector3, b: Vector3, ra: float, rb: float) -> void:
	var pad := maxf(ra, rb) + 8.0
	_prims.append({
		"t": 0, "a": a, "b": b, "ra": ra, "rb": rb,
		"lo": Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z)) - Vector3.ONE * pad,
		"hi": Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z)) + Vector3.ONE * pad,
	})


## A room: an ellipsoid with a flat floor. If a pool is given the floor dips to the water's edge there
## and rises gently away from it, by up to 3 m.
static func _chamber(center: Vector3, radii: Vector3, floor_y: float, pool_at: Vector2) -> void:
	_prims.append({
		"t": 1, "c": center, "r": radii, "fy": floor_y, "pool": pool_at,
		"lo": center - radii - Vector3.ONE * 8.0, "hi": center + radii + Vector3.ONE * 8.0,
	})


## A place where a cave opens to the surface: the 48 m squares of ground round it are built by the
## cave mesh (so the cave can break through the ground), and the terrain skips them.
static func _mouth(at: Vector2) -> void:
	for cz in range(floori((at.y - 30.0) / CHUNK), floori((at.y + 30.0) / CHUNK) + 1):
		for cx in range(floori((at.x - 30.0) / CHUNK), floori((at.x + 30.0) / CHUNK) + 1):
			var column := Vector2i(cx, cz)
			if _ground_columns.has(column):
				continue
			_ground_columns[column] = true
			RegionTerrain.add_hole(Rect2(cx * CHUNK, cz * CHUNK, CHUNK, CHUNK))
			# Every cube from a bit below the ground up to a bit above it.
			var low := 1.0e9
			var high := -1.0e9
			for k in 9:
				for i in 9:
					var h := RegionTerrain.height(cx * CHUNK + i * CHUNK / 8.0, cz * CHUNK + k * CHUNK / 8.0)
					low = minf(low, h)
					high = maxf(high, h)
			for cy in range(floori((low - 3.0) / CHUNK), floori((high + 3.0) / CHUNK) + 1):
				_extra_keys[Vector3i(cx, cy, cz)] = true


static func has_ground(cx: int, cz: int) -> bool:
	return _ground_columns.has(Vector2i(cx, cz))


## All the cave chunks (by index of 48 m cube) that have any cave in them.
static func chunk_keys() -> Array[Vector3i]:
	var seen := _extra_keys.duplicate()
	for prim in _prims:
		if prim["t"] == 0:
			# Walk along the tunnel, marking the cubes round each point.
			var a: Vector3 = prim["a"]
			var b: Vector3 = prim["b"]
			var reach := maxf(float(prim["ra"]), float(prim["rb"])) + 4.0
			var steps := maxi(1, int(a.distance_to(b) / 12.0))
			for s in steps + 1:
				var at := a.lerp(b, float(s) / steps)
				_mark_box(seen, at - Vector3.ONE * reach, at + Vector3.ONE * reach)
		else:
			_mark_box(seen, prim["lo"], prim["hi"])
	var keys: Array[Vector3i] = []
	for key in seen:
		keys.append(key)
	return keys


static func _mark_box(seen: Dictionary, lo: Vector3, hi: Vector3) -> void:
	for k in range(floori(lo.z / CHUNK), floori(hi.z / CHUNK) + 1):
		for j in range(floori(lo.y / CHUNK), floori(hi.y / CHUNK) + 1):
			for i in range(floori(lo.x / CHUNK), floori(hi.x / CHUNK) + 1):
				seen[Vector3i(i, j, k)] = true


## Only the pieces that can matter inside this box.
static func prims_near(lo: Vector3, hi: Vector3) -> Array:
	var near := []
	for prim in _prims:
		var plo: Vector3 = prim["lo"]
		var phi: Vector3 = prim["hi"]
		if plo.x < hi.x and phi.x > lo.x and plo.y < hi.y and phi.y > lo.y and plo.z < hi.z and phi.z > lo.z:
			near.append(prim)
	return near


## Is this (x, z) over the drowned tunnel or its pool? (Water is there wherever you are below lake level.)
static func in_flooded_zone(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	if p.distance_squared_to(pool) < 81.0:
		return true
	for i in _flood.size() - 1:
		var a := _flood[i]
		var ab := _flood[i + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if p.distance_squared_to(a + ab * t) < 64.0:
			return true
	return false


# --- The distance field --------------------------------------------------------------

static func _smin(a: float, b: float, k: float) -> float:
	var h := maxf(k - absf(a - b), 0.0) / k
	return minf(a, b) - h * h * k * 0.25


## Negative inside the open air, positive in rock. `ground` is the height of the ground here, if this
## is a cube that builds the ground too (then the sky above it counts as open air).
static func sdf(p: Vector3, prims: Array, ground := NAN) -> float:
	var d := 1.0e9
	for prim in prims:
		var v: float
		if prim["t"] == 0:
			var a: Vector3 = prim["a"]
			var ab: Vector3 = (prim["b"] as Vector3) - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			v = p.distance_to(a + ab * t) - lerpf(float(prim["ra"]), float(prim["rb"]), t)
		else:
			var c: Vector3 = prim["c"]
			var r: Vector3 = prim["r"]
			var q := (p - c) / r
			v = (q.length() - 1.0) * minf(r.x, minf(r.y, r.z))
			var floor_y: float = prim["fy"]
			var pool_at: Vector2 = prim["pool"]
			if not is_inf(pool_at.x):
				floor_y += clampf((Vector2(p.x, p.z).distance_to(pool_at) - 6.0) * 0.25, 0.0, 3.0)
			v = maxf(v, floor_y - p.y)
		d = v if d > 1.0e8 else _smin(d, v, 2.5)
	d += _noise.get_noise_3dv(p) * ROUGHNESS
	if is_nan(ground):
		return d
	return _smin(d, ground - p.y, 1.2)
