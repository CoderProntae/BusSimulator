extends Node3D
class_name TrafficAI
# ============================================================
#  TrafficAI — very simple looping traffic. A colored "car"
#  (box body on cylinder wheels) drives straight along a
#  direction and wraps back to its start after travelling a
#  set distance, giving the illusion of continuous traffic
#  circulating the city grid.
# ============================================================

@export var travel_direction : Vector3 = Vector3(0, 0, 1)
@export var speed : float = 9.0
@export var loop_distance : float = 200.0

var _start : Vector3 = Vector3.ZERO

func _ready() -> void:
	_start = global_position
	travel_direction = travel_direction.normalized()

func _physics_process(delta : float) -> void:
	global_position += travel_direction * speed * delta
	if global_position.distance_to(_start) > loop_distance:
		global_position = _start
	look_at(global_position + travel_direction, Vector3.UP)
