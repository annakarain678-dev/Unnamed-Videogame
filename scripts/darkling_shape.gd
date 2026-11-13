class_name DarklingShape
extends Node3D
## How a darkling looks: a hooded, ghostly shape with a round head over a body that tapers
## into a wisp of a tail, a faint violet rim and two pale eyes. Visible only in spirit view.

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;

global uniform float spirit_view;
uniform vec4 body_color : source_color = vec4(0.03, 0.02, 0.06, 1.0);
uniform vec4 rim_color : source_color = vec4(0.45, 0.30, 0.85, 1.0);
uniform float opacity = 0.85;
uniform float fade = 1.0;
uniform float wobble = 0.06;

void vertex() {
	// A slow, smoky ripple across the surface.
	float t = TIME * 1.7;
	VERTEX += NORMAL * sin(VERTEX.y * 7.0 + t) * cos(VERTEX.x * 5.0 + t * 1.3) * wobble;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(body_color.rgb, rim_color.rgb, rim);
	ALPHA = mix(opacity, 1.0, rim) * spirit_view * fade;
}
"""

var _materials: Array[ShaderMaterial] = []


func _init() -> void:
	var head := SphereMesh.new()
	head.radius = 0.38
	head.height = 0.8
	_add_piece(head, Vector3(0.0, 0.35, 0.0), _make_material(Color(0.03, 0.02, 0.06), Color(0.45, 0.30, 0.85), 0.85))

	var body := CylinderMesh.new()
	body.top_radius = 0.34
	body.bottom_radius = 0.03
	body.height = 1.5
	body.radial_segments = 12
	body.rings = 6
	_add_piece(body, Vector3(0.0, -0.45, 0.0), _make_material(Color(0.03, 0.02, 0.06), Color(0.35, 0.22, 0.70), 0.7))

	# Two faint, pale eyes.
	var eye_material := _make_material(Color(0.75, 0.65, 1.0), Color(0.9, 0.85, 1.0), 1.0)
	eye_material.set_shader_parameter("wobble", 0.0)
	for side in [-1.0, 1.0]:
		var eye := SphereMesh.new()
		eye.radius = 0.05
		eye.height = 0.07
		_add_piece(eye, Vector3(0.13 * side, 0.42, -0.33), eye_material)


## 1 = fully visible, 0 = gone.
func set_fade(value: float) -> void:
	for material in _materials:
		material.set_shader_parameter("fade", value)


func _make_material(body_color: Color, rim_color: Color, opacity: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("body_color", body_color)
	material.set_shader_parameter("rim_color", rim_color)
	material.set_shader_parameter("opacity", opacity)
	_materials.append(material)
	return material


func _add_piece(mesh: PrimitiveMesh, at: Vector3, material: ShaderMaterial) -> void:
	mesh.material = material
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(piece)
