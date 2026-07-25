extends Node3D
class_name BusStop
# ============================================================
#  BusStop — a roadside shelter with waiting passengers drawn
#  as capsule shapes. The PassengerSystem reads `waiting`
#  and `global_position`; boarding decrements `waiting` and
#  hides the corresponding capsules. Added to group "bus_stop".
# ============================================================

@export var stop_name : String = "Bus Stop"
@export var waiting : int = 3
const MAX_VISUAL := 6

func _ready() -> void:
	add_to_group("bus_stop")
	update_visual()

# Show exactly `waiting` capsule passengers (max MAX_VISUAL).
func update_visual() -> void:
	for i in range(MAX_VISUAL):
		var cap : MeshInstance3D = get_node_or_null("Passengers/Cap_%d" % i)
		if cap != null:
			cap.visible = i < waiting
