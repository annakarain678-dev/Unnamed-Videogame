class_name ForestTerrain
extends RefCounted
## The shape of the land: plain functions of (x, z), so the terrain mesh, the trees, the map and the
## wisp's "don't fall through the ground" check all agree. Nothing is stored; it is all noise.
##
## The world is an uneven basin about 4 to 5 km across (it is not a perfect circle):
##  - a rolling floor of hills and ravines, with a few flat clearings left open for buildings;
##  - a wandering rim of stepped cliffs and then mountains, far above anything can fly.

const SEED := 7121
## Terrain is generated out to about this far from the center (meters).
const WORLD_RADIUS := 2900.0
## The rim starts to climb here, as terraces of cliffs separated by flat shelves.
const RIM_START := 1900.0
const RIM_WIDTH := 900.0
const TERRACES := 3
const TERRACE_RISE := 125.0
## How far the rim wanders in and out, so the basin isn't a circle.
const RIM_WANDER := 520.0

## Above this height the forest thins out into bare rock.
const TREE_LINE_LOW := 150.0
const TREE_LINE_HIGH := 235.0

## Flat clearings, as Vector3(x, z, radius) — note the z is stored in .y. The first is the main
## one, around the starting point. The others are spare sites for villages and camps.
const CLEARINGS: Array[Vector3] = [
	Vector3(0.0, 0.0, 170.0),
	Vector3(-980.0, 620.0, 80.0),
	Vector3(1050.0, -520.0, 70.0),
	Vector3(-380.0, -1250.0, 85.0),
	Vector3(1150.0, 1000.0, 65.0),
]

static var _ready_flag := false
static var _broad: FastNoiseLite
static var _ridge: FastNoiseLite
static var _hills: FastNoiseLite
static var _gully: FastNoiseLite
static var _detail: FastNoiseLite
static var _micro: FastNoiseLite
static var _rim_warp: FastNoiseLite
static var _crag: FastNoiseLite
static var _peaks: FastNoiseLite
static var _patch: FastNoiseLite
static var _glade: FastNoiseLite
static var _rocks: FastNoiseLite
static var _clearing_heights := PackedFloat32Array()


## Call once, on the main thread, before anything asks for a height.
static func setup() -> void:
	if _ready_flag:
		return
	_broad = _make(1.0 / 1900.0, 3, 1)
	_ridge = _make(1.0 / 1100.0, 3, 2, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, FastNoiseLite.FRACTAL_RIDGED)
	_hills = _make(1.0 / 520.0, 3, 3)
	_gully = _make(1.0 / 300.0, 2, 4)
	_detail = _make(1.0 / 85.0, 2, 5)
	_micro = _make(1.0 / 17.0, 2, 6)
	_rim_warp = _make(1.0 / 1500.0, 3, 7)
	_crag = _make(1.0 / 110.0, 3, 8)
	_peaks = _make(1.0 / 650.0, 4, 9, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, FastNoiseLite.FRACTAL_RIDGED)
	_patch = _make(1.0 / 520.0, 2, 10)
	_glade = _make(1.0 / 380.0, 2, 11)
	_rocks = _make(1.0 / 85.0, 2, 12)
	_clearing_heights.resize(CLEARINGS.size())
	for i in CLEARINGS.size():
		var c := CLEARINGS[i]
		_clearing_heights[i] = _floor_height(c.x, c.y)
	_ready_flag = true


static func _make(
	frequency: float, octaves: int, seed_offset: int,
	type := FastNoiseLite.TYPE_SIMPLEX_SMOOTH, fractal := FastNoiseLite.FRACTAL_FBM
) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = SEED + seed_offset
	noise.noise_type = type
	noise.frequency = frequency
	noise.fractal_type = fractal if octaves > 1 else FastNoiseLite.FRACTAL_NONE
	noise.fractal_octaves = octaves
	return noise


## The ground before the rim and the clearings are added.
static func _floor_height(x: float, z: float) -> float:
	var broad := _broad.get_noise_2d(x, z)
	var ridge := clampf(_ridge.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
	var hills := _hills.get_noise_2d(x, z)
	# Narrow V-shaped ravines wherever this noise crosses zero.
	var gully := _gully.get_noise_2d(x, z)
	var ravine := pow(1.0 - minf(absf(gully) * 2.6, 1.0), 3.0)
	return (
		58.0 + broad * 24.0 + ridge * 18.0 + hills * 11.0 - ravine * 9.0
		+ _detail.get_noise_2d(x, z) * 2.2 + _micro.get_noise_2d(x, z) * 0.35
	)


static func _rim_height(x: float, z: float, r: float) -> float:
	var warp := _rim_warp.get_noise_2d(x, z) * RIM_WANDER
	var t := (r + warp - RIM_START) / RIM_WIDTH
	if t <= 0.0:
		return 0.0
	# Terraces: long shelves, then a short steep climb (a cliff) up to the next one.
	var a := clampf(t, 0.0, 1.0) * TERRACES
	var step := floorf(a)
	var f := a - step
	var climb := smoothstep(0.7, 0.92, f)
	var h := (step + climb) * TERRACE_RISE + f * 8.0
	h += _crag.get_noise_2d(x, z) * 14.0 * smoothstep(0.0, 0.12, t)
	# Beyond the last cliff, jagged mountains.
	if t > 0.9:
		var peaks := clampf(_peaks.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
		h += peaks * 190.0 * smoothstep(0.9, 1.25, t)
	return h


## Height of the ground in meters above sea level (there is no sea here).
static func height(x: float, z: float) -> float:
	var h := _floor_height(x, z)
	var r := sqrt(x * x + z * z)
	if r > RIM_START - RIM_WANDER * 1.6:
		h += _rim_height(x, z, r)
	for i in CLEARINGS.size():
		var c := CLEARINGS[i]
		var dx := x - c.x
		var dz := z - c.y
		var d := sqrt(dx * dx + dz * dz)
		if d < c.z * 2.3:
			var w := 1.0 - smoothstep(c.z, c.z * 2.2, d)
			h = lerpf(h, _clearing_heights[i] + _micro.get_noise_2d(x, z) * 0.35, w)
	return h


## How steep the ground is: 0 = flat, 1 = a vertical wall. (1 minus the normal's up component.)
static func slope(x: float, z: float) -> float:
	var e := 3.0
	var dx := (height(x + e, z) - height(x - e, z)) / (2.0 * e)
	var dz := (height(x, z + e) - height(x, z - e)) / (2.0 * e)
	return 1.0 - 1.0 / sqrt(1.0 + dx * dx + dz * dz)


## Distance to the nearest clearing's flat part, as a fraction of its radius (1 = at the edge).
static func clearing_factor(x: float, z: float) -> float:
	var best := 99.0
	for c in CLEARINGS:
		var dx := x - c.x
		var dz := z - c.y
		best = minf(best, sqrt(dx * dx + dz * dz) / c.z)
	return best


## How densely the forest grows here (0 = bare, 1 = thick), ignoring slope.
static func forest_density(x: float, z: float, h: float) -> float:
	var d := 0.80 + 0.22 * _patch.get_noise_2d(x, z)
	d *= smoothstep(-0.56, -0.40, _glade.get_noise_2d(x, z))
	d *= smoothstep(1.06, 1.9, clearing_factor(x, z))
	d *= 1.0 - smoothstep(TREE_LINE_LOW, TREE_LINE_HIGH, h)
	return clampf(d, 0.0, 1.0)


## Same, but a little shy of steep ground. This is what trees use.
static func tree_density(x: float, z: float, h: float) -> float:
	var d := forest_density(x, z, h)
	if d <= 0.0:
		return 0.0
	return d * (1.0 - smoothstep(0.12, 0.28, slope(x, z)))


## Where loose rocks like to sit (0 to 1).
static func rock_noise(x: float, z: float) -> float:
	return _rocks.get_noise_2d(x, z) * 0.5 + 0.5


## A cheap, repeatable random number from a cell, 0 up to (not including) 1.
static func rnd(i: int, j: int, salt: int) -> float:
	var h := (i * 73856093) ^ (j * 19349663) ^ (salt * 83492791)
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / 16777216.0
