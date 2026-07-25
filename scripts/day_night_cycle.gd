extends DirectionalLight3D
class_name DayNightCycle
# ============================================================
#  DayNightCycle — slowly rotates the sun and modulates its
#  energy so the city moves from day to night over ~5 minutes.
#  Attached to the "Sun" DirectionalLight3D in World.tscn.
# ============================================================

const CYCLE_SECONDS := 300.0   # full day/night loop (5 minutes)
const START_ANGLE   := 0.785   # initial 45 degrees (per spec)

var _elapsed : float = 0.0

func _process(delta : float) -> void:
	_elapsed += delta
	var t : float = (_elapsed / CYCLE_SECONDS) * TAU
	# Rotate the sun around the X axis (rises east, sets west).
	rotation = Vector3(START_ANGLE + t, 0.0, 0.0)
	# Brightness: full at "noon", near-zero at "night".
	var daylight : float = clampf(sin(START_ANGLE + t), 0.0, 1.0)
	light_energy = 0.15 + 1.05 * daylight
