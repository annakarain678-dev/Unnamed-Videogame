class_name DarkFlame
extends GPUParticles3D
## Black fire licking up around something possessed by a darkling.
## Visible only in the wisp's spirit view.

## How tall and wide the fire is (roughly a person's size by default).
@export var height := 1.8
@export var radius := 0.42

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

global uniform float spirit_view;
uniform vec4 core_color : source_color = vec4(0.0, 0.0, 0.02, 1.0);
uniform vec4 edge_color : source_color = vec4(0.38, 0.16, 0.65, 1.0);

void vertex() {
	// Always face the camera (billboard), keeping each flame's size.
	mat4 facing = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]),
		normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * facing * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	// A soft teardrop: wide at the bottom, pointed at the top.
	vec2 p = UV * 2.0 - 1.0;
	// Narrow tongue at the top, wide at the base, with a slow flicker sideways.
	p.x += sin(TIME * 9.0 + UV.y * 6.0 + MODEL_MATRIX[3].x * 5.0) * 0.12 * (1.0 - UV.y);
	p.x /= mix(0.2, 1.0, clamp(UV.y, 0.0, 1.0));
	float d = length(p);
	float shape = 1.0 - smoothstep(0.15, 1.0, d);
	// Mostly black, with only a thin violet edge.
	ALBEDO = mix(core_color.rgb, edge_color.rgb, smoothstep(0.65, 1.0, d) * 0.8);
	ALPHA = shape * COLOR.a * spirit_view;
}
"""


func _init() -> void:
	amount = 150
	lifetime = 0.9
	preprocess = 1.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _ready() -> void:
	position.y = height * 0.45
	visibility_aabb = AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3.0, height + 3.0, 3.0))

	var motion := ParticleProcessMaterial.new()
	# Flames start on a hollow ring hugging the body, from feet to head.
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	motion.emission_ring_axis = Vector3.UP
	motion.emission_ring_height = height
	motion.emission_ring_radius = radius
	motion.emission_ring_inner_radius = radius * 0.6
	motion.direction = Vector3.UP
	motion.spread = 12.0
	motion.initial_velocity_min = 0.6
	motion.initial_velocity_max = 1.3
	motion.gravity = Vector3.ZERO
	motion.scale_min = 0.7
	motion.scale_max = 1.2
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	var shrink_texture := CurveTexture.new()
	shrink_texture.curve = shrink
	motion.scale_curve = shrink_texture
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.25, Color(1, 1, 1, 1))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	motion.color_ramp = fade_texture
	process_material = motion

	var shader := Shader.new()
	shader.code = SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	var flame := QuadMesh.new()
	flame.size = Vector2(0.42, 0.8)
	flame.material = material
	draw_pass_1 = flame
