class_name Atmosphere
extends Node
## Controls how the world looks, blending smoothly between three moods:
##
## - Normal: the everyday world, as bodies see it. Follows the day-night cycle:
##   the sun crosses the sky by day, the moon by night.
## - Spirit view: what the wisp sees. Always night: darker navy tones, flattened contrast,
##   faded color, drifting dust, and the wisp's home star alone in the sky. The wisp is the
##   brightest thing around, and darklings become visible.
## - Underwater: blue haze that thickens with depth, plus a gentle ripple over the view.
##
## It also sets the global shader value "spirit_view" (0 to 1), which spirit-only things
## like darklings use to fade in and out.

## Set by whoever builds the world.
var environment: Environment
var sea_level := 0.0

## The time of day. Keeps running whether you're the wisp or in a body.
var cycle := DayNightCycle.new()

## How quickly the view shifts when entering or leaving a body (higher = faster).
@export var spirit_fade_speed := 3.0
## How quickly the underwater look fades in or out at the surface.
@export var water_fade_speed := 10.0

const NORMAL_FOG_DENSITY := 0.0012
const NORMAL_FOG_SKY_AFFECT := 0.3
const NORMAL_GLOW := 0.9
## At night, the everyday world's colors are a little less vivid (but still not spirit-view grey).
const NIGHT_SATURATION := 0.78
const GROUND_BOTTOM := Color(0.25, 0.32, 0.38)

# --- Spirit view look ---
const SPIRIT_FOG := Color(0.07, 0.10, 0.24)
const SPIRIT_FOG_DENSITY := 0.012
const SPIRIT_SKY_TOP := Color(0.03, 0.05, 0.14)
const SPIRIT_SKY_HORIZON := Color(0.12, 0.16, 0.32)
const SPIRIT_LIGHT := Color(0.55, 0.65, 1.0)
const SPIRIT_LIGHT_ENERGY := 0.3
const SPIRIT_AMBIENT := Color(0.16, 0.22, 0.45)
const SPIRIT_BRIGHTNESS := 0.85
const SPIRIT_CONTRAST := 0.8
const SPIRIT_SATURATION := 0.5
const SPIRIT_GLOW := 1.6
## Spirit view color grade: darks become deep navy, lights become pale blue-white.
const SPIRIT_GRADE_DARK := Color(0.02, 0.03, 0.10)
const SPIRIT_GRADE_LIGHT := Color(0.80, 0.88, 1.0)

# --- Underwater look ---
const WATER_COLOR := Color(0.06, 0.30, 0.40)
const SHALLOW_WATER_DENSITY := 0.04
const DEEP_WATER_DENSITY := 0.09
const DEEP_DEPTH := 10.0

const RIPPLE_SHADER := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.06, 0.30, 0.40, 1.0);
uniform float amount = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float wobble = 0.0015 * amount;
	uv.x += sin(uv.y * 38.0 + TIME * 2.1) * wobble;
	uv.y += cos(uv.x * 27.0 + TIME * 1.7) * wobble;
	vec3 scene = texture(screen_texture, uv).rgb;
	// The fog does most of the coloring (and leaves the wisp's light alone);
	// this only adds a light wash of blue on top of the ripple.
	COLOR = vec4(mix(scene, tint.rgb, 0.1 * amount), 1.0);
}
"""

## 0 = normal world, 1 = full spirit view.
var spirit_amount := 1.0
## 0 = above water, 1 = fully underwater.
var water_amount := 0.0

var _spirit_goal := 1.0
var _heart_amount := 0.0
var _sky_material: ShaderMaterial
var _sun: DirectionalLight3D
var _moon: DirectionalLight3D
var _spirit_light: DirectionalLight3D
var _grade: Gradient
var _graded_amount := -1.0
var _ripple: ColorRect
var _ripple_material: ShaderMaterial
var _dust: SpiritDust
var _star: HomeStar
var _clock: Label


func _ready() -> void:
	add_to_group("atmosphere")
	# The sky: colors, sun, moon and stars, all drawn by sky.gdshader.
	_sky_material = ShaderMaterial.new()
	_sky_material.shader = load("res://scripts/sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = _sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	environment.adjustment_enabled = true
	environment.ambient_light_color = SPIRIT_AMBIENT

	# A color grade: each color channel is remapped along this gradient.
	# Plain black-to-white changes nothing; navy-to-pale-blue tints the whole world.
	_grade = Gradient.new()
	var grade_texture := GradientTexture1D.new()
	grade_texture.gradient = _grade
	environment.adjustment_color_correction = grade_texture

	_build_lights()
	_build_ripple_overlay()
	_build_clock()
	_dust = SpiritDust.new()
	add_child(_dust)
	_star = HomeStar.new()
	add_child(_star)
	_apply()


## True while the player is the wisp (spirit view), false while in a body.
func set_spirit(active: bool) -> void:
	_spirit_goal = 1.0 if active else 0.0


## Inside a possessed heart: keep spirit view's darkness, but drop its color wash.
func set_in_heart(inside: bool) -> void:
	_heart_amount = 1.0 if inside else 0.0
	_graded_amount = -1.0  # Rebuild the color grade.


func _process(delta: float) -> void:
	cycle.advance(delta)
	spirit_amount = _approach(spirit_amount, _spirit_goal, spirit_fade_speed, delta)

	var camera := get_viewport().get_camera_3d()
	var depth := sea_level - camera.global_position.y if camera else 0.0
	water_amount = _approach(water_amount, 1.0 if depth > 0.0 else 0.0, water_fade_speed, delta)

	_apply(depth)
	if camera:
		_dust.follow(camera.global_position, spirit_amount)
		# Your home star shines in the spirit sky, and among the other stars at night.
		var night: float = cycle.sample()["stars"]
		_star.follow(camera.global_position, maxf(spirit_amount, night))
	_clock.text = cycle.clock_text()


func _apply(depth := 0.0) -> void:
	var s := spirit_amount
	var w := water_amount
	var now := cycle.sample()

	# Fog: time of day -> spirit, then -> underwater on top.
	var water_density := lerpf(SHALLOW_WATER_DENSITY, DEEP_WATER_DENSITY, clampf(depth / DEEP_DEPTH, 0.0, 1.0))
	var water_color := WATER_COLOR.lerp(SPIRIT_FOG, s * 0.5)
	environment.fog_light_color = (now["fog"] as Color).lerp(SPIRIT_FOG, s).lerp(water_color, w)
	environment.fog_density = lerpf(lerpf(NORMAL_FOG_DENSITY, SPIRIT_FOG_DENSITY, s), water_density, w)
	environment.fog_sky_affect = lerpf(lerpf(NORMAL_FOG_SKY_AFFECT, 0.6, s), 1.0, w)

	# Sun and moon follow the clock; in spirit view they fade out and the spirit light takes over.
	_sun.rotation_degrees = cycle.sun_rotation()
	_sun.light_color = now["sun_color"]
	_sun.light_energy = now["sun_energy"] * (1.0 - s)
	_sun.visible = _sun.light_energy > 0.001
	_sun.shadow_enabled = s < 0.5
	_moon.rotation_degrees = cycle.moon_rotation()

	# Sky: in spirit view the sun, moon and ordinary stars all vanish (only the home star remains).
	_sky_material.set_shader_parameter("sky_top", (now["sky_top"] as Color).lerp(SPIRIT_SKY_TOP, s))
	_sky_material.set_shader_parameter("sky_horizon", (now["sky_horizon"] as Color).lerp(SPIRIT_SKY_HORIZON, s))
	_sky_material.set_shader_parameter("ground_bottom", GROUND_BOTTOM.lerp(SPIRIT_SKY_TOP, s))
	# A light shines along its -Z axis, so the direction toward the sun or moon is its +Z axis.
	_sky_material.set_shader_parameter("sun_direction", _sun.global_basis.z)
	_sky_material.set_shader_parameter("sun_color", now["sun_color"])
	_sky_material.set_shader_parameter("sun_amount", smoothstep(-0.1, 0.05, cycle.sun_height()) * (1.0 - s))
	_sky_material.set_shader_parameter("moon_direction", _moon.global_basis.z)
	_sky_material.set_shader_parameter("moon_amount", float(now["moon_amount"]) * (1.0 - s))
	_sky_material.set_shader_parameter("star_amount", float(now["stars"]) * (1.0 - s))
	_moon.light_color = now["moon_color"]
	_moon.light_energy = now["moon_energy"] * (1.0 - s)
	_moon.visible = _moon.light_energy > 0.001
	_spirit_light.light_energy = SPIRIT_LIGHT_ENERGY * s
	_spirit_light.visible = s > 0.001
	_spirit_light.shadow_enabled = s >= 0.5

	# Ambient light leans navy, and values flatten out (less difference between light and dark).
	environment.ambient_light_sky_contribution = lerpf(1.0, 0.3, s)
	environment.adjustment_brightness = lerpf(1.0, SPIRIT_BRIGHTNESS, s)
	environment.adjustment_contrast = lerpf(1.0, SPIRIT_CONTRAST, s)
	# (Inside a possessed heart, the spirit color wash is dropped so its colors show true.)
	var wash := s * (1.0 - _heart_amount)
	var everyday_saturation := lerpf(1.0, NIGHT_SATURATION, now["night"])
	environment.adjustment_saturation = lerpf(everyday_saturation, SPIRIT_SATURATION, wash)
	environment.glow_intensity = lerpf(NORMAL_GLOW, SPIRIT_GLOW, s)
	if wash != _graded_amount:  # Only rebuild the grade while it's changing.
		_graded_amount = wash
		_grade.set_color(0, Color.BLACK.lerp(SPIRIT_GRADE_DARK, wash))
		_grade.set_color(1, Color.WHITE.lerp(SPIRIT_GRADE_LIGHT, wash))

	RenderingServer.global_shader_parameter_set("spirit_view", s)

	_ripple.visible = w > 0.0
	_ripple_material.set_shader_parameter("amount", w)


func _build_lights() -> void:
	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 150.0
	add_child(_sun)

	# The moon gives a little cool light. (The sky shader draws the moon itself.)
	_moon = DirectionalLight3D.new()
	_moon.name = "Moon"
	_moon.shadow_enabled = false
	add_child(_moon)

	# Spirit view's own soft, fixed light. It lights the world but doesn't appear in the sky.
	_spirit_light = DirectionalLight3D.new()
	_spirit_light.name = "SpiritLight"
	_spirit_light.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	_spirit_light.light_color = SPIRIT_LIGHT
	_spirit_light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	_spirit_light.directional_shadow_max_distance = 150.0
	add_child(_spirit_light)


func _build_clock() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_clock = Label.new()
	_clock.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.75))
	_clock.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	_clock.add_theme_constant_override("shadow_offset_x", 1)
	_clock.add_theme_constant_override("shadow_offset_y", 1)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock.offset_left = -260.0
	_clock.offset_right = -16.0
	_clock.offset_top = 44.0
	layer.add_child(_clock)


func _build_ripple_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0  # Above the 3D world, below on-screen text.
	add_child(layer)

	var shader := Shader.new()
	shader.code = RIPPLE_SHADER
	_ripple_material = ShaderMaterial.new()
	_ripple_material.shader = shader
	_ripple_material.set_shader_parameter("tint", WATER_COLOR)

	_ripple = ColorRect.new()
	_ripple.material = _ripple_material
	_ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ripple.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ripple.visible = false
	layer.add_child(_ripple)


## Moves `value` smoothly toward `goal`, snapping when it's close enough.
static func _approach(value: float, goal: float, speed: float, delta: float) -> float:
	value = lerpf(value, goal, 1.0 - exp(-speed * delta))
	return goal if absf(value - goal) < 0.002 else value
