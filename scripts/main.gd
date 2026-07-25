extends Node3D
class_name Main
# ============================================================
#  Main — wires the gameplay systems together. The HUD writes
#  control input into GameState; this script connects the
#  momentary HUD actions to the bus / camera and gives the
#  passenger & fuel systems a direct reference to the bus.
# ============================================================

@onready var _bus : Node3D = $Bus
@onready var _camera : Node3D = $CameraRig/Camera3D
@onready var _passengers : Node = $PassengerSystem
@onready var _fuel : Node = $FuelSystem

func _ready() -> void:
	# Give the systems a direct bus reference (they also fall
	# back to the "bus" group, so this is just convenience).
	_passengers.bus = _bus
	_fuel.bus = _bus
	# Ensure the camera can find the bus immediately.
	_bus.add_to_group("bus")
