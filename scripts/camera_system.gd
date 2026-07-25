extends Camera3D
class_name CameraSystem
# ============================================================
#  CameraSystem — three camera modes for the bus simulator:
#    CHASE    : smooth third-person follow behind the bus
#    INTERIOR : driver-seat view looking forward
#    TOP      : orthographic bird's-eye view
#  Switched with the HUD "camera" button. A raycast keeps the
#  chase camera from clipping through buildings.
# ============================================================

enum CameraMode { CHASE, INTERIOR, TOP }
const MODE_COUNT := 3

const CHASE_DISTANCE := 13.0    # how far behind the bus
const CHASE_HEIGHT  := 4.5      # how high above the bus
const CHASE_LERP    := 4.0      # follow smoothing
const TOP_HEIGHT    := 70.0     # orthographic height
const TOP_ORTHO_SIZE := 45.0    # orthographic half-extent

var mode : int = CameraMode.CHASE
var _bus : Node3D = null

func _ready() -> void:
	GameState.camera_cycle_requested.connect(_on_cycle_camera)
	_apply_projection()

# Cycle to the next camera mode and update the projection.
func _on_cycle_camera() -> void:
	mode = (mode + 1) % MODE_COUNT
	_apply_projection()

func _apply_projection() -> void:
	if mode == CameraMode.TOP:
		projection = Camera3D.PROJECTION_ORTHOGONAL
		size = TOP_ORTHO_SIZE
	else:
		projection = Camera3D.PROJECTION_PERSPECTIVE

func _physics_process(delta : float) -> void:
	if _bus == null:
		_bus = get_tree().get_first_node_in_group("bus")
		if _bus == null:
			return
	match mode:
		CameraMode.CHASE:    _update_chase(delta)
		CameraMode.INTERIOR: _update_interior()
		CameraMode.TOP:      _update_top()

# Third-person chase cam with clipping avoidance.
func _update_chase(delta : float) -> void:
	var bus_t : Transform3D = _bus.global_transform
	# "Behind" the bus is +Z in its local space (bus forward is -Z).
	var anchor : Vector3 = _bus.global_position + Vector3(0, CHASE_HEIGHT, 0)
	var desired : Vector3 = bus_t * Vector3(0.0, CHASE_HEIGHT, CHASE_DISTANCE)
	desired = _avoid_clip(anchor, desired)
	global_position = global_position.lerp(desired, 1.0 - exp(-CHASE_LERP * delta))
	look_at(_bus.global_position + Vector3(0, 1.5, 0), Vector3.UP)

# Driver-seat interior cam.
func _update_interior() -> void:
	var anchor : Node3D = _bus.get_node_or_null("InteriorAnchor")
	if anchor == null:
		global_position = _bus.global_position + Vector3(0.6, 1.6, -1.5)
		look_at(global_position + _bus.global_basis * Vector3(0, 0, -5), Vector3.UP)
	else:
		global_position = anchor.global_position
		look_at(anchor.global_position + anchor.global_basis * Vector3(0, 0, -5), Vector3.UP)

# Bird's-eye orthographic cam.
func _update_top() -> void:
	global_position = Vector3(_bus.global_position.x, TOP_HEIGHT, _bus.global_position.z)
	look_at(_bus.global_position, Vector3(0, 0, -1))

# Pull the camera in if a building is between the bus and the cam.
func _avoid_clip(from : Vector3, to : Vector3) -> Vector3:
	var space_state = get_world_3d().direct_space_state
	if space_state == null:
		return to
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	# Never let the bus itself block the chase camera.
	var body := _bus as CollisionObject3D
	if body != null:
		query.exclude = [body.get_rid()]
	var result : Dictionary = space_state.intersect_ray(query)
	if not result.is_empty():
		var dist : float = from.distance_to(to)
		var hit_t : float = from.distance_to(result["position"]) / dist
		return from.lerp(to, clampf(hit_t - 0.05, 0.1, 0.95))
	return to
