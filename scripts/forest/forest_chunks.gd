class_name ForestChunks
extends Node3D
## Streams the world in around a target (the wisp). The land is a quadtree of square "leaves": small and
## detailed near the target, huge and simple far away. Leaves are worked out on background threads
## (see ForestBuilder) and turned into nodes here, a couple per frame, so flying never stutters.

const LEVELS := 7                  # levels 0..6; the top one is 8 km across, covering the whole world
const SPLIT_K := 2.2               # bigger = more detail further out
const WORLD_EDGE := 3500.0         # nothing is generated further from the center than this
const MAX_TASKS := 3               # background builds at once
const MAX_LEAVES := 800            # leaves kept in memory (hidden ones are recycled)
const INSTANCES_PER_FRAME := 2
const SHADOW_MAX_LEVEL := 2        # only leaves this fine cast shadows

var target: Node3D
var kit: ForestMeshes

var _built := {}                   # Vector3i -> Leaf
var _pending := {}                 # Vector3i -> true, while a thread is working on it
var _results: Array = []
var _mutex := Mutex.new()
var _timer := 0.0
var _visible_count := 0
var _wanted_count := 0


class Leaf:
	var node: Node3D
	var level := 0
	var size := 0.0
	var shown := true
	var last_used := 0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_refresh(true)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.15
		_refresh(false)
	_collect_results()


## Number of leaves on screen, wanted leaves, and builds in progress (for the debug readout).
func stats() -> String:
	return "leaves %d/%d  building %d  cached %d" % [_visible_count, _wanted_count, _pending.size(), _built.size()]


## True once everything close to the target has been built.
func is_settled() -> bool:
	return _pending.is_empty() and _results.is_empty()


## Builds the coarse, far-away terrain right now, so there are no holes at the start.
func prebuild_blocking() -> void:
	_refresh(true)
	_collect_results(true)
	_refresh(false)


func _refresh(blocking: bool) -> void:
	if target == null:
		return
	var camera := get_viewport().get_camera_3d()
	var focus := target.global_position
	if camera:
		focus = camera.global_position
	var ground := ForestTerrain.height(focus.x, focus.z)
	var altitude := maxf(focus.y - ground, 0.0)

	var wanted: Array[Vector3i] = []
	_collect_wanted(LEVELS - 1, 0, 0, focus, altitude, wanted)
	_wanted_count = wanted.size()

	# Decide what is on screen: each wanted leaf, or the nearest finished leaf standing in for it.
	var show := {}
	var to_build: Array[Vector3i] = []
	for key in wanted:
		if _built.has(key):
			show[key] = false
		else:
			to_build.append(key)
			_fallback(key, show)
	var now := Time.get_ticks_msec()
	for key in _built:
		var leaf: Leaf = _built[key]
		var wanted_now := show.has(key)
		var is_fallback: bool = show.get(key, false)
		if wanted_now:
			leaf.last_used = now
			if not leaf.shown:
				leaf.node.visible = true
				leaf.shown = true
			# A stand-in sits a little low, so the real, finer leaves beside it show on top.
			leaf.node.position.y = -leaf.size / ForestBuilder.GRID * 0.8 if is_fallback else 0.0
		elif leaf.shown:
			leaf.node.visible = false
			leaf.shown = false
	_visible_count = show.size()

	# Build the nearest missing leaves first.
	to_build.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return _distance_to(a, focus, altitude) < _distance_to(b, focus, altitude))
	for key in to_build:
		if _pending.has(key):
			continue
		if blocking and key.x >= 2:
			# At the start, build the far terrain right away so there are no holes.
			_pending[key] = true
			_push_result(ForestBuilder.build(key.x, key.y, key.z))
		elif _pending.size() < MAX_TASKS:
			_pending[key] = true
			WorkerThreadPool.add_task(_build_in_thread.bind(key))
	_recycle(now)


func _build_in_thread(key: Vector3i) -> void:
	_push_result(ForestBuilder.build(key.x, key.y, key.z))


func _push_result(result: Dictionary) -> void:
	_mutex.lock()
	_results.append(result)
	_mutex.unlock()


func _collect_results(everything := false) -> void:
	var made := 0
	while made < INSTANCES_PER_FRAME or everything:
		_mutex.lock()
		var result: Dictionary = _results.pop_front() if not _results.is_empty() else {}
		_mutex.unlock()
		if result.is_empty():
			return
		_instantiate(result)
		made += 1


func _collect_wanted(level: int, ix: int, iz: int, focus: Vector3, altitude: float, out: Array[Vector3i]) -> void:
	var size := ForestBuilder.leaf_size(level)
	var origin := ForestBuilder.leaf_origin(level, ix, iz)
	# Skip squares that lie wholly outside the world.
	var nearest_x := clampf(0.0, origin.x, origin.x + size)
	var nearest_z := clampf(0.0, origin.y, origin.y + size)
	if sqrt(nearest_x * nearest_x + nearest_z * nearest_z) > WORLD_EDGE:
		return
	var dx := maxf(maxf(origin.x - focus.x, focus.x - (origin.x + size)), 0.0)
	var dz := maxf(maxf(origin.y - focus.z, focus.z - (origin.y + size)), 0.0)
	var distance := sqrt(dx * dx + dz * dz + altitude * altitude)
	if level > 0 and distance < size * SPLIT_K:
		for cz in 2:
			for cx in 2:
				_collect_wanted(level - 1, ix * 2 + cx, iz * 2 + cz, focus, altitude, out)
	else:
		out.append(Vector3i(level, ix, iz))


func _distance_to(key: Vector3i, focus: Vector3, altitude: float) -> float:
	var size := ForestBuilder.leaf_size(key.x)
	var origin := ForestBuilder.leaf_origin(key.x, key.y, key.z)
	var dx := maxf(maxf(origin.x - focus.x, focus.x - (origin.x + size)), 0.0)
	var dz := maxf(maxf(origin.y - focus.z, focus.z - (origin.y + size)), 0.0)
	return sqrt(dx * dx + dz * dz + altitude * altitude)


## While a leaf isn't ready, keep showing a finished leaf from a coarser level over the same ground.
func _fallback(key: Vector3i, show: Dictionary) -> void:
	var level := key.x
	var ix := key.y
	var iz := key.z
	while level < LEVELS - 1:
		level += 1
		ix = ix >> 1
		iz = iz >> 1
		var parent := Vector3i(level, ix, iz)
		if _built.has(parent):
			if not show.has(parent):
				show[parent] = true
			return


func _recycle(now: int) -> void:
	if _built.size() <= MAX_LEAVES:
		return
	var old: Array = []
	for key in _built:
		var leaf: Leaf = _built[key]
		if not leaf.shown and now - leaf.last_used > 4000:
			old.append(key)
	old.sort_custom(func(a: Vector3i, b: Vector3i) -> bool: return _built[a].last_used < _built[b].last_used)
	var excess := _built.size() - MAX_LEAVES
	for k in mini(excess, old.size()):
		var key: Vector3i = old[k]
		(_built[key] as Leaf).node.queue_free()
		_built.erase(key)


## Turns a finished ForestBuilder result into real nodes.
func _instantiate(result: Dictionary) -> void:
	var key: Vector3i = result["key"]
	_pending.erase(key)
	if _built.has(key):
		return
	var level: int = result["level"]
	var size: float = result["size"]

	var root := Node3D.new()
	root.name = "Leaf_%d_%d_%d" % [key.x, key.y, key.z]
	root.position = Vector3(result["x0"], 0.0, result["z0"])
	root.visible = false
	var casts_shadows := level <= SHADOW_MAX_LEVEL

	# Terrain.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = result["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = result["normals"]
	arrays[Mesh.ARRAY_COLOR] = result["colors"]
	arrays[Mesh.ARRAY_INDEX] = result["indices"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, kit.terrain_material)
	var ground := MeshInstance3D.new()
	ground.mesh = mesh
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ground)

	# Ground collision, and a solid trunk for each tree, near the wisp only.
	var body: StaticBody3D = null
	if result.has("faces"):
		body = StaticBody3D.new()
		body.collision_layer = Layers.WORLD
		body.collision_mask = 0
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(result["faces"])
		shape.backface_collision = true
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		root.add_child(body)
		var trunks: PackedFloat32Array = result["trunks"]
		var count := trunks.size() / 5
		for t in count:
			var radius := trunks[t * 5 + 2]
			var tall := trunks[t * 5 + 3]
			var cylinder := CylinderShape3D.new()
			cylinder.radius = radius
			cylinder.height = tall
			var trunk := CollisionShape3D.new()
			trunk.shape = cylinder
			trunk.position = Vector3(trunks[t * 5], trunks[t * 5 + 4] + tall * 0.5, trunks[t * 5 + 1])
			body.add_child(trunk)

	# Trees, bushes, grass and rocks: one MultiMesh per kind.
	for batch in result["batches"]:
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = kit.meshes[batch["mesh"]]
		multimesh.instance_count = batch["count"]
		multimesh.buffer = batch["data"]
		multimesh.custom_aabb = AABB(Vector3(-20.0, -60.0, -20.0), Vector3(size + 40.0, 1400.0, size + 40.0))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		var is_ground_cover: bool = batch["mesh"] in ["grass", "fern", "bush"]
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if (casts_shadows and not is_ground_cover) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(instance)

	add_child(root)
	var leaf := Leaf.new()
	leaf.node = root
	leaf.level = level
	leaf.size = size
	leaf.shown = false
	leaf.last_used = Time.get_ticks_msec()
	_built[key] = leaf
