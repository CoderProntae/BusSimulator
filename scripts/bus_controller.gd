extends VehicleBody3D
class_name BusController
# ============================================================
#  BusController — drives the bus using the Godot 4 vehicle
#  physics (VehicleBody3D + 4x VehicleWheel3D). Tuned for a
#  HEAVY, SLOW, realistic bus feel: gentle acceleration, long
#  braking, wide turning radius, speed capped at 80 km/h.
#  Reads control input from the GameState singleton (touch
#  HUD) with keyboard fallback for desktop testing.
# ============================================================

# --- Tunable handling constants (heavy bus feel) ---
const MAX_ENGINE_FORCE := 3000.0   # N per driven (rear) wheel -> slow accel
const MAX_BRAKE_FORCE  := 90.0     # firm but long stopping distance
const MAX_STEER_ANGLE  := 0.38     # radians (~22 deg) -> wide turning radius
const STEER_LERP       := 2.2      # how quickly steering reaches the target
const SPEED_CAP_KMH    := 80.0     # hard speed limit
const REVERSE_FORCE    := 0.55     # fraction of engine force used in reverse

# --- Door animation ---
const DOOR_CLOSED_X := 1.25
const DOOR_OPEN_X   := 1.70
const DOOR_TIME     := 0.6

@onready var _door_panel : CSGBox3D = $Doors/DoorPanel
@onready var _horn : AudioStreamPlayer3D = $HornSpeaker
@onready var _wheel_fl : VehicleWheel3D = $WheelFL
@onready var _wheel_fr : VehicleWheel3D = $WheelFR
@onready var _wheel_rl : VehicleWheel3D = $WheelRL
@onready var _wheel_rr : VehicleWheel3D = $WheelRR

var _steer_current : float = 0.0
var _doors_open : bool = false
var _door_tween : Tween = null
var _horn_stream : AudioStream = null

func _ready() -> void:
	# The bus is found by other systems via this group.
	add_to_group("bus")
	# Load the programmatically generated horn beep at runtime
	# (avoids committing a binary .import for the audio asset).
	_horn_stream = load("res://assets/audio/horn.wav")
	if _horn_stream != null:
		_horn.stream = _horn_stream
	# Hook up momentary HUD actions coming through GameState.
	GameState.horn_pressed.connect(_on_horn_pressed)
	GameState.door_toggle_requested.connect(_on_door_toggle)

# Continuous control + vehicle physics each fixed step.
func _physics_process(delta : float) -> void:
	# ---- Gather input (touch HUD first, keyboard fallback) ----
	var throttle : float = GameState.throttle_input
	if throttle <= 0.0:
		throttle = Input.get_action_strength("ui_up")
	var brake : float = GameState.brake_input
	if brake <= 0.0:
		brake = Input.get_action_strength("brake")
	var steer_target : float = GameState.steer_input
	if steer_target == 0.0:
		steer_target = Input.get_axis("ui_left", "ui_right")

	# ---- Speed in km/h ----
	var speed_kmh : float = linear_velocity.length() * 3.6
	GameState.speed_kmh = speed_kmh
	GameState.speed_changed.emit(speed_kmh)

	# ---- Engine force (capped + needs fuel) ----
	var engine : float = 0.0
	if GameState.fuel > 0.0 and speed_kmh < SPEED_CAP_KMH:
		engine = throttle * MAX_ENGINE_FORCE
	# Reverse when the brake is held while nearly stopped.
	if brake > 0.0 and speed_kmh < 1.5:
		engine = -REVERSE_FORCE * MAX_ENGINE_FORCE
	# Drive force goes to the rear wheels only (RWD bus).
	_wheel_rl.engine_force = engine
	_wheel_rr.engine_force = engine

	# ---- Steering (front wheels, smoothed for a heavy feel) ----
	_steer_current = move_toward(_steer_current, steer_target * MAX_STEER_ANGLE, STEER_LERP * delta)
	_wheel_fl.steering = _steer_current
	_wheel_fr.steering = _steer_current

	# ---- Brakes applied to all four wheels ----
	var b : float = brake * MAX_BRAKE_FORCE
	_wheel_fl.brake = b
	_wheel_fr.brake = b
	_wheel_rl.brake = b
	_wheel_rr.brake = b

# Public accessor so the passenger system knows if boarding is allowed.
func are_doors_open() -> bool:
	return _doors_open

# --- Horn: play the generated beep if it is not already playing. ---
func _on_horn_pressed() -> void:
	if _horn != null and _horn.stream != null and not _horn.playing:
		_horn.play()

# --- Doors: slide the CSG panel open/closed with a tween. ---
func _on_door_toggle() -> void:
	_doors_open = !_doors_open
	if _door_tween != null:
		_door_tween.kill()
	_door_tween = create_tween()
	var target_x : float = DOOR_OPEN_X if _doors_open else DOOR_CLOSED_X
	_door_tween.tween_property(_door_panel, "position:x", target_x, DOOR_TIME)
	GameState.toast.emit("Doors " + ("opened" if _doors_open else "closed"))
