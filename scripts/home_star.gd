class_name HomeStar
extends MeshInstance3D
## The wisp's home star. In spirit view it's the only star in the sky; on ordinary nights it
## shines among the others.
## It grows a little with each chapter, as the wisp learns and grows.
## (Where it sits in the sky, and whether it moves, are still to be decided.)

## 0 at the start of the game, rising toward 1 by the end. Each chapter adds a little.
@export_range(0.0, 1.0) var growth := 0.0
## Direction from the viewer to the star.
@export var direction := Vector3(0.45, 0.32, -0.83)

## Far enough to look like part of the sky.
const DISTANCE := 900.0
const BASE_SIZE := 45.0

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled, cull_disabled;

uniform vec4 star_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);
uniform float brightness = 3.0;
// 0 = hidden (daytime, in a body), 1 = fully shining (spirit view, or night).
uniform float visibility = 1.0;

void vertex() {
	// Always face the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]) * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	// A bright core, a soft glow, and faint four-pointed rays, gently twinkling.
	float core = exp(-d * d * 120.0) * 2.0;
	float glow = exp(-d * 7.0) * 0.5;
	float rays = (exp(-abs(p.x) * 60.0) + exp(-abs(p.y) * 60.0)) * exp(-d * 4.0) * 0.6;
	float twinkle = 0.85 + 0.15 * sin(TIME * 2.3) * sin(TIME * 3.7);
	float light = (core + glow + rays) * twinkle;
	ALBEDO = star_color.rgb * light * brightness * visibility;
}
"""


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var shader := Shader.new()
	shader.code = SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	quad.material = _material
	mesh = quad
	extra_cull_margin = 16384.0


var _material: ShaderMaterial


## Keeps the star fixed in the sky, however far the viewer travels.
## `amount` (0 to 1) is how visible it is: it shines in spirit view and at night.
func follow(camera_position: Vector3, amount: float) -> void:
	global_position = camera_position + direction.normalized() * DISTANCE
	scale = Vector3.ONE * BASE_SIZE * (1.0 + growth * 4.0)
	visible = amount > 0.01
	_material.set_shader_parameter("visibility", amount)
