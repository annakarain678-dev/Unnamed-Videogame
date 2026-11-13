class_name SpiritDust
extends GPUParticles3D
## Faint specks of light drifting in the air, seen only in spirit view.
## The cloud stays centered on the camera; the specks themselves stay put in the world as you move.

@export var area_size := 14.0
@export var speck_color := Color(0.75, 0.82, 1.0)

var _material: StandardMaterial3D


func _init() -> void:
	amount = 500
	lifetime = 7.0
	preprocess = 7.0
	local_coords = false
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visibility_aabb = AABB(Vector3.ONE * -area_size, Vector3.ONE * area_size * 2.0)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var motion := ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3.ONE * area_size
	motion.direction = Vector3.UP
	motion.spread = 180.0
	motion.initial_velocity_min = 0.03
	motion.initial_velocity_max = 0.18
	motion.gravity = Vector3.ZERO
	motion.scale_min = 0.5
	motion.scale_max = 1.4
	# Fade each speck in and out over its life so none pop.
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.3, Color(1, 1, 1, 1))
	fade.add_point(0.7, Color(1, 1, 1, 1))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	motion.color_ramp = fade_texture
	process_material = motion

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_material.vertex_color_use_as_albedo = true
	_material.disable_fog = true
	_material.albedo_color = Color(speck_color, 0.0)
	# Soft round specks rather than squares, and none right in front of the lens.
	_material.albedo_texture = _soft_dot()
	_material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	_material.distance_fade_min_distance = 0.6
	_material.distance_fade_max_distance = 2.5

	var speck := QuadMesh.new()
	speck.size = Vector2(0.06, 0.06)
	speck.material = _material
	draw_pass_1 = speck


## A small white dot that fades out toward its edge.
static func _soft_dot() -> GradientTexture2D:
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1, 1, 1, 1))
	falloff.set_color(1, Color(1, 1, 1, 0))
	var dot := GradientTexture2D.new()
	dot.gradient = falloff
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 32
	dot.height = 32
	return dot


## Keeps the dust around the camera and fades it with the spirit view (0 to 1).
func follow(camera_position: Vector3, spirit_amount: float) -> void:
	global_position = camera_position
	_material.albedo_color.a = 0.7 * spirit_amount
	visible = spirit_amount > 0.01
