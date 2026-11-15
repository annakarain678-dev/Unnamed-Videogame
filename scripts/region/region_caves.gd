class_name RegionCaves
extends RefCounted
## The caves of the first region. They are not part of the height-field: each cave system is a set of
## tunnels and rooms described as a signed distance field (negative = open air), turned into a mesh by
## RegionBuilder in 48 m cubes, and it sits in the same world space under the terrain. So there is no
## loading screen: you walk down a hole in the ground and you are in the cave.
##
## Where a cave opens to the surface, the terrain has a hole (RegionTerrain.add_hole).
##
##  - The underwater way: dive into the deep lake, down a shaft, along a drowned tunnel, and up
##    through a pool into the village's cavern (like the U-bend of a pipe: water on both ends, and the
##    pool inside the cavern is at the same level as the lake).
##  - The hatchery arm: a mine-like slope in the ruins hill, a chamber (the hatchery), then a long
##    tunnel to the village cavern.
##  - The smugglers' way: from the village cavern to a ramp in the quarry floor at the bandit camp.

const CELL := 1.5
const CELLS := 32
const CHUNK := CELL * CELLS
const ROUGHNESS := 1.1

# Key places other scripts need.
static var pool := Vector2(225.0, 1088.0)
static var village_floor := 0.0
static var hatchery := Vector3.ZERO     # center of the hatchery chamber floor
static var shaft := Vector2(-90.0, 850.0)
static var quarry_ramp := Vector2(975.0, -95.0)
static var hatchery_mouth := Vector2(-690.0, 440.0)

static var _prims: Array = []
static var _flood: Array[Vector2] = []
static var _noise: FastNoiseLite
static var _ready_flag := false


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
	village_floor = level + 3.0

	# --- The underwater way: lake shaft, drowned tunnel, pool, village cavern. ----------------
	var floor_y := RegionTerrain.height(shaft.x, shaft.y)
	RegionTerrain.add_hole(shaft, shaft, 7.5)
	var siphon: Array[Vector3] = [
		Vector3(shaft.x, floor_y + 0.8, shaft.y),
		Vector3(-89.0, level - 32.0, 853.0),
		Vector3(-60.0, level - 42.0, 900.0),
		Vector3(20.0, level - 46.0, 970.0),
		Vector3(120.0, level - 38.0, 1040.0),
		Vector3(195.0, level - 18.0, 1075.0),
		Vector3(pool.x - 3.0, level - 4.0, pool.y - 2.0),
	]
	var siphon_radii: Array[float] = [6.5, 4.5, 4.5, 4.5, 4.5, 4.8, 5.0]
	_chain(siphon, siphon_radii)
	for point in siphon:
		_flood.append(Vector2(point.x, point.z))
	# The pool inside the cavern, at lake level.
	_capsule(Vector3(pool.x, level - 7.0, pool.y), Vector3(pool.x, level + 3.0, pool.y), 8.0, 8.0)
	# The village cavern: a wide room whose floor rises from the pool's edge.
	_chamber(Vector3(270.0, level + 12.0, 1105.0), Vector3(70.0, 22.0, 45.0), level, pool)

	# --- The hatchery arm. --------------------------------------------------------------------
	var ruins := RegionTerrain.RUINS
	var hatch_floor := base - 4.0
	hatchery = Vector3(ruins.x, hatch_floor, ruins.y)
	_chamber(Vector3(ruins.x, hatch_floor + 10.0, ruins.y), Vector3(42.0, 14.0, 34.0), hatch_floor, Vector2(INF, INF))
	var slot_end := Vector2(-715.0, 433.0)
	RegionTerrain.add_hole(hatchery_mouth, slot_end, 5.0)
	var ground := RegionTerrain.height(hatchery_mouth.x, hatchery_mouth.y)
	var entry: Array[Vector3] = [
		Vector3(hatchery_mouth.x, ground + 0.8, hatchery_mouth.y),
		Vector3(-715.0, base + 5.0, 433.0),
		Vector3(-740.0, base + 1.0, 424.0),
		Vector3(-765.0, hatch_floor + 4.0, 414.0),
	]
	_chain(entry, [5.5, 4.5, 4.5, 4.5] as Array[float])
	var arm: Array[Vector3] = [
		Vector3(-790.0, hatch_floor + 4.0, 430.0),
		Vector3(-760.0, level - 12.0, 520.0),
		Vector3(-640.0, level - 16.0, 700.0),
		Vector3(-480.0, level - 16.0, 880.0),
		Vector3(-300.0, level - 16.0, 1050.0),
		Vector3(-120.0, level - 16.0, 1190.0),
		Vector3(60.0, level - 14.0, 1230.0),
		Vector3(200.0, level - 6.0, 1215.0),
		Vector3(275.0, level + 5.0, 1140.0),
	]
	_chain(arm, [4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.8, 5.0] as Array[float])

	# --- The smugglers' way: village cavern to a ramp in the quarry floor. --------------------
	var quarry_floor := base - RegionTerrain.QUARRY_FLOOR
	var ramp_start := Vector2(960.0, -30.0)
	RegionTerrain.add_hole(ramp_start, quarry_ramp, 5.0)
	var smugglers: Array[Vector3] = [
		Vector3(330.0, level + 5.0, 1110.0),
		Vector3(420.0, level - 10.0, 1040.0),
		Vector3(520.0, level - 16.0, 880.0),
		Vector3(640.0, level - 16.0, 640.0),
		Vector3(760.0, level - 16.0, 400.0),
		Vector3(860.0, level - 16.0, 170.0),
		Vector3(925.0, level - 14.0, 40.0),
		Vector3(960.0, level - 12.0, -30.0),
		Vector3(quarry_ramp.x, quarry_floor + 0.8, quarry_ramp.y),
	]
	_chain(smugglers, [5.0, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 4.5, 5.5] as Array[float])


# --- Describing the caves ----------------------------------------------------------

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


## All the cave chunks (by index of 48 m cube) that have any cave in them.
static func chunk_keys() -> Array[Vector3i]:
	var seen := {}
	for prim in _prims:
		if prim["t"] == 0:
			# Walk along the tunnel, marking the cubes round each point.
			var a: Vector3 = prim["a"]
			var b: Vector3 = prim["b"]
			var reach := maxf(float(prim["ra"]), float(prim["rb"])) + 4.0
			var steps := maxi(1, int(a.distance_to(b) / 12.0))
			for s in steps + 1:
				_mark(seen, a.lerp(b, float(s) / steps), reach)
		else:
			var lo: Vector3 = prim["lo"]
			var hi: Vector3 = prim["hi"]
			_mark_box(seen, lo, hi)
	var keys: Array[Vector3i] = []
	for key in seen:
		keys.append(key)
	return keys


static func _mark(seen: Dictionary, p: Vector3, reach: float) -> void:
	_mark_box(seen, p - Vector3.ONE * reach, p + Vector3.ONE * reach)


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


## Negative inside the cave's open air, positive in rock.
static func sdf(p: Vector3, prims: Array) -> float:
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
	return d + _noise.get_noise_3dv(p) * ROUGHNESS
