class_name DayNightCycle
extends RefCounted
## The time of day, and how the everyday world looks at that time.
## The sun crosses the sky by day and the moon by night, like Minecraft.

## Real minutes for one whole day and night (24 game hours).
## 10 minutes = 5 minutes of daylight (6 am to 6 pm) and 5 minutes of night.
var day_length_minutes := 10.0
## The current hour, 0 to 24 (e.g. 13.5 = 1:30 pm).
var hour := 8.0
var day := 1

## Which way the sun travels across the sky (degrees around the vertical).
const SUN_PATH_YAW := -35.0

const DAY_SKY_TOP := Color(0.13, 0.35, 0.80)
const DAY_SKY_HORIZON := Color(0.78, 0.82, 0.82)
const DAY_FOG := Color(0.80, 0.78, 0.68)
const DAY_SUN := Color(1.0, 0.94, 0.80)

const DUSK_SKY_TOP := Color(0.26, 0.28, 0.52)
const DUSK_SKY_HORIZON := Color(1.0, 0.56, 0.28)
const DUSK_FOG := Color(0.80, 0.55, 0.40)
const DUSK_SUN := Color(1.0, 0.52, 0.24)

const NIGHT_SKY_TOP := Color(0.01, 0.015, 0.05)
const NIGHT_SKY_HORIZON := Color(0.05, 0.07, 0.14)
const NIGHT_FOG := Color(0.04, 0.05, 0.10)
const MOON := Color(0.65, 0.75, 1.0)

const SUN_ENERGY := 1.2
const MOON_ENERGY := 0.18


func advance(delta: float) -> void:
	hour += delta * 24.0 / (day_length_minutes * 60.0)
	if hour >= 24.0:
		hour -= 24.0
		day += 1


## How high the sun is: 1 at noon, 0 at 6 am and 6 pm, -1 at midnight.
func sun_height() -> float:
	return sin((hour - 6.0) / 12.0 * PI)


## The sun's rotation (degrees): rising at 6 am, overhead at noon, setting at 6 pm.
func sun_rotation() -> Vector3:
	return Vector3(-(hour - 6.0) / 12.0 * 180.0, SUN_PATH_YAW, 0.0)


## The moon sits opposite the sun.
func moon_rotation() -> Vector3:
	return sun_rotation() + Vector3(180.0, 0.0, 0.0)


## Colors and light levels for right now.
func sample() -> Dictionary:
	var h := sun_height()
	var daylight := smoothstep(-0.15, 0.3, h)
	# Strongest right at sunrise and sunset.
	var dusk := clampf(1.0 - absf(h) / 0.3, 0.0, 1.0) * 0.8

	return {
		"sky_top": NIGHT_SKY_TOP.lerp(DAY_SKY_TOP, daylight).lerp(DUSK_SKY_TOP, dusk * 0.5),
		"sky_horizon": NIGHT_SKY_HORIZON.lerp(DAY_SKY_HORIZON, daylight).lerp(DUSK_SKY_HORIZON, dusk),
		"fog": NIGHT_FOG.lerp(DAY_FOG, daylight).lerp(DUSK_FOG, dusk),
		"sun_color": DAY_SUN.lerp(DUSK_SUN, dusk),
		"sun_energy": SUN_ENERGY * smoothstep(-0.02, 0.15, h),
		# Clouds: white by day, golden or rosy at sunrise and sunset, near black at night.
		"cloud_light": Color(0.14, 0.16, 0.26).lerp(Color(1.0, 0.97, 0.90), daylight).lerp(DUSK_SUN.lightened(0.15), dusk * 0.85),
		"cloud_dark": Color(0.03, 0.04, 0.09).lerp(Color(0.50, 0.55, 0.66), daylight).lerp(Color(0.52, 0.32, 0.36), dusk * 0.7),
		# Mist: the forest haze thickens at dawn and dusk.
		"mist": 0.65 + 2.2 * dusk,
		"moon_color": MOON,
		"moon_energy": MOON_ENERGY * smoothstep(-0.02, 0.15, -h),
		# How much of the moon disc shows (it fades in as it rises clear of the horizon glow).
		"moon_amount": smoothstep(-0.25, 0.05, -h),
		# Stars come out as the sun goes down.
		"stars": smoothstep(0.05, -0.2, h),
		# 0 by day, 1 by night: night colors are a little less vivid.
		"night": smoothstep(0.1, -0.15, h),
	}


## e.g. "Day 1 · 8:05 am"
func clock_text() -> String:
	var whole := int(hour)
	var minutes := int((hour - whole) * 60.0)
	var suffix := "am" if whole < 12 else "pm"
	var twelve := whole % 12
	if twelve == 0:
		twelve = 12
	return "Day %d  ·  %d:%02d %s" % [day, twelve, minutes, suffix]
