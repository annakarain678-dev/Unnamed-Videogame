class_name RegionTerrain
extends RefCounted
## The first region as a grey-box: the shape of the land and where every place sits. Plain functions of
## (x, z), like ForestTerrain, so the mesh, the map, the markers and the water all agree.
##
## North is -Z. The basin is mostly round (about 2.9 km across) with a wandering rim of cliffs.
## Caves are not in here: they are separate meshes under the ground (see RegionCaves), and the
## terrain only gets round holes where a cave opens to the surface.

const SEED := 4242
const BASE := 50.0
const RIM_RADIUS := 1000.0
const RIM_WANDER := 80.0
const RIM_WIDTH := 240.0
const RIM_HEIGHT := 190.0
## Terrain is built out to about this far from the center.
const EDGE := 1360.0

# --- Where things are (x, z) -----------------------------------------------------
const TOWN := Vector2(0.0, 0.0)
## A flat-topped mesa with flowers on top: you have to fly up to get them.
const MESA := Vector2(85.0, -365.0)
const MESA_TOP := 55.0
const MESA_BASE := 85.0
const MESA_HEIGHT := 75.0
const FORK := Vector2(130.0, -455.0)
const DARKLING := Vector2(-230.0, -700.0)
const BANDIT := Vector2(620.0, 40.0)
const RUINS := Vector2(-480.0, 330.0)
const RUINS_RADIUS := 150.0
const RUINS_HEIGHT := 45.0
## x, z, radius. A deep lake.
const LAKE := Vector3(-150.0, 560.0, 62.0)
const LAKE_DEPTH := 24.0
const VILLAGE := Vector2(200.0, 660.0)
const VILLAGE_RADIUS := 150.0
const VILLAGE_HEIGHT := 60.0
const QUARRY_FLOOR := 8.0

## The roads and trails, as lists of points (x, z).
const ROAD_NORTH: Array[Vector2] = [
	Vector2(0.0, -110.0), Vector2(-10.0, -210.0), Vector2(-7.0, -330.0), Vector2(28.0, -420.0), Vector2(130.0, -455.0),
]
const ROAD_DARKLING: Array[Vector2] = [
	Vector2(130.0, -455.0), Vector2(-40.0, -560.0), Vector2(-230.0, -700.0),
]
const ROAD_BANDIT: Array[Vector2] = [
	Vector2(130.0, -455.0), Vector2(350.0, -336.0), Vector2(560.0, -175.0), Vector2(620.0, 40.0),
]
const ROAD_RUINS: Array[Vector2] = [
	Vector2(-420.0, 300.0), Vector2(-330.0, 390.0), Vector2(-240.0, 480.0), Vector2(-190.0, 530.0),
]

static var _ready_flag := false
static var _broad: FastNoiseLite
static var _hills: FastNoiseLite
static var _detail: FastNoiseLite
static var _rim_warp: FastNoiseLite
static var _crag: FastNoiseLite
static var _patch: FastNoiseLite
static var _holes: Array = []
static var _paths: Array = []


## Call once, on the main thread, before anything asks for a height.
static func setup() -> void:
	if _ready_flag:
		return
	_broad = _make(1.0 / 900.0, 3, 1)
	_hills = _make(1.0 / 260.0, 2, 2)
	_detail = _make(1.0 / 40.0, 2, 3)
	_rim_warp = _make(0.01, 2, 4)
	_crag = _make(1.0 / 55.0, 3, 5)
	_patch = _make(1.0 / 170.0, 2, 6)
	_paths = [ROAD_NORTH, ROAD_DARKLING, ROAD_BANDIT, ROAD_RUINS]
	_ready_flag = true


static func _make(frequency: float, octaves: int, seed_offset: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = SEED + seed_offset
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM if octaves > 1 else FastNoiseLite.FRACTAL_NONE
	noise.fractal_octaves = octaves
	return noise


## Called by RegionCaves: a rectangle of ground (grid-aligned) that is built by the cave mesh instead, so
## a cave can open to the sky with no seam, lid or hole.
static func add_hole(rect: Rect2) -> void:
	_holes.append(rect)


static func is_hole(x: float, z: float) -> bool:
	var p := Vector2(x, z)
	for hole in _holes:
		if (hole as Rect2).has_point(p):
			return true
	return false


## The surface of the lake (and of the pool the underwater cave comes up in).
static func lake_level() -> float:
	return BASE - 0.7


static func _blend(h: float, d: float, inner: float, outer: float, target: float) -> float:
	return lerpf(h, target, 1.0 - smoothstep(inner, outer, d))


static func rim_radius(x: float, z: float) -> float:
	var angle := atan2(z, x)
	return RIM_RADIUS + _rim_warp.get_noise_2d(cos(angle) * 300.0, sin(angle) * 300.0) * RIM_WANDER


## Height of the ground in meters.
static func height(x: float, z: float) -> float:
	var h := BASE + _broad.get_noise_2d(x, z) * 10.0 + _hills.get_noise_2d(x, z) * 5.0 + _detail.get_noise_2d(x, z) * 0.7

	# The town sits on a level clearing; so does the ground round the lake.
	h = _blend(h, Vector2(x, z).length(), 110.0, 210.0, BASE)
	h = _blend(h, Vector2(x - LAKE.x, z - LAKE.y).length(), LAKE.z + 20.0, LAKE.z + 90.0, BASE)

	# The darklings' dead-wood clearing: level, a little sunken.
	h = _blend(h, Vector2(x - DARKLING.x, z - DARKLING.y).length(), 70.0, 140.0, BASE - 3.0)

	# The bandit quarry: a level floor sunk below the land, walled in on the east and the sides.
	var qx := x - BANDIT.x
	var qz := z - BANDIT.y
	var qd := sqrt(qx * qx + qz * qz)
	h = _blend(h, qd, 55.0, 95.0, BASE - QUARRY_FLOOR)
	if qd > 1.0:
		var closed := smoothstep(-0.55, 0.25, qx / qd)
		var ring := smoothstep(58.0, 72.0, qd) * (1.0 - smoothstep(95.0, 150.0, qd))
		h += 34.0 * closed * ring

	# The ancient ruins' hill, with a broad flat top.
	var rd := Vector2(x - RUINS.x, z - RUINS.y).length() / RUINS_RADIUS
	h += RUINS_HEIGHT * (1.0 - smoothstep(0.45, 1.0, rd))

	# The mesa of the flowers: sheer sides, a flat top.
	var md := Vector2(x - MESA.x, z - MESA.y).length()
	h += MESA_HEIGHT * (1.0 - smoothstep(MESA_TOP, MESA_BASE, md))

	# The hollow hill over the Qoi-Kash village.
	var vd := Vector2(x - VILLAGE.x, z - VILLAGE.y).length() / VILLAGE_RADIUS
	if vd < 1.0:
		h += VILLAGE_HEIGHT * pow(1.0 - vd * vd, 2.0)

	# The deep lake: flat water-level ground rim, then a bowl with steep sides and a deep floor.
	var ld := Vector2(x - LAKE.x, z - LAKE.y).length()
	if ld < LAKE.z * 1.35:
		var bowl: float
		if ld < LAKE.z:
			bowl = lake_level() - LAKE_DEPTH * (1.0 - pow(ld / LAKE.z, 2.0))
		else:
			bowl = lerpf(lake_level(), h, smoothstep(LAKE.z, LAKE.z * 1.35, ld))
		h = minf(h, bowl)

	# The wandering rim: cliffs that close the basin in.
	var r := sqrt(x * x + z * z)
	var edge := rim_radius(x, z)
	if r > edge - 40.0:
		var t := clampf((r - edge) / RIM_WIDTH, 0.0, 1.0)
		h += RIM_HEIGHT * smoothstep(0.0, 1.0, t) + _crag.get_noise_2d(x, z) * 16.0 * smoothstep(0.0, 0.2, t)
	return h


## Is this spot over water (the lake, the underwater cave's tunnel, or the pool it comes up in)?
## Water exists wherever this is true and you are below the lake level.
static func in_water(x: float, z: float) -> bool:
	var lx := x - LAKE.x
	var lz := z - LAKE.y
	if lx * lx + lz * lz < LAKE.z * LAKE.z * 1.1:
		return true
	return RegionCaves.in_flooded_zone(x, z)


## 0..1: how much a road or trail runs here (used to paint the ground).
static func path_factor(x: float, z: float) -> float:
	var best := 1e9
	var p := Vector2(x, z)
	for path in _paths:
		for i in path.size() - 1:
			var a: Vector2 = path[i]
			var b: Vector2 = path[i + 1]
			var ab := b - a
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return 1.0 - smoothstep(2.0, 6.5, best)


## Where the north forest belt is centred (between the town and the road fork).
const FOREST_AT := Vector2(-10.0, -250.0)


## How thickly trees grow here (0 = none, 1 = thick), before slope is considered.
static func forest_density(x: float, z: float, h: float) -> float:
	var r := sqrt(x * x + z * z)
	var d := 0.28 + 0.4 * _patch.get_noise_2d(x, z)
	d += 0.7 * (1.0 - smoothstep(90.0, 240.0, Vector2(x - FOREST_AT.x, z - FOREST_AT.y).length()))
	d += 0.9 * smoothstep(rim_radius(x, z) - 320.0, rim_radius(x, z) - 40.0, r)
	# Open ground for the places people go.
	d *= smoothstep(190.0, 270.0, r)
	d *= smoothstep(LAKE.z + 12.0, LAKE.z + 70.0, Vector2(x - LAKE.x, z - LAKE.y).length())
	d *= smoothstep(120.0, 180.0, Vector2(x - BANDIT.x, z - BANDIT.y).length())
	d *= smoothstep(RUINS_RADIUS * 0.5, RUINS_RADIUS * 0.95, Vector2(x - RUINS.x, z - RUINS.y).length())
	d *= smoothstep(MESA_BASE + 5.0, MESA_BASE + 35.0, Vector2(x - MESA.x, z - MESA.y).length())
	d *= smoothstep(30.0, 70.0, Vector2(x - FORK.x, z - FORK.y).length())
	d *= 1.0 - path_factor(x, z)
	d *= 1.0 - smoothstep(130.0, 175.0, h)
	for hole in _holes:
		if (hole as Rect2).grow(14.0).has_point(Vector2(x, z)):
			return 0.0
	return clampf(d, 0.0, 1.0)


## 0..1: how dead the land is (round the darklings' ring).
static func dead_amount(x: float, z: float) -> float:
	return 1.0 - smoothstep(100.0, 190.0, Vector2(x - DARKLING.x, z - DARKLING.y).length())


## How steep the ground is: 0 = flat, 1 = a vertical wall.
static func slope(x: float, z: float) -> float:
	var e := 3.0
	var dx := (height(x + e, z) - height(x - e, z)) / (2.0 * e)
	var dz := (height(x, z + e) - height(x, z - e)) / (2.0 * e)
	return 1.0 - 1.0 / sqrt(1.0 + dx * dx + dz * dz)
