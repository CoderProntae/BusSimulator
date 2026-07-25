extends Node
class_name PassengerSystem
# ============================================================
#  PassengerSystem — boarding / alighting economy.
#  When the bus is stopped near a bus stop with doors open,
#  waiting passengers board (up to capacity). At a DIFFERENT
#  stop the onboard passengers are dropped off for coins
#  (10-50 each), then the bus is empty again.
# ============================================================

const BOARD_RADIUS := 7.0
const BUS_CAPACITY := 30

var bus : Node3D = null
var _last_pickup : Node = null

func _physics_process(_delta : float) -> void:
	if bus == null:
		bus = get_tree().get_first_node_in_group("bus")
		if bus == null:
			return
	# Only board/alight when the doors are actually open.
	if bus.has_method("are_doors_open") and not bus.are_doors_open():
		return
	for stop in get_tree().get_nodes_in_group("bus_stop"):
		if bus.global_position.distance_to(stop.global_position) > BOARD_RADIUS:
			continue
		# Deliver first: if we carry passengers and this is a stop
		# we did NOT board at, drop them off for coins.
		if GameState.passengers > 0 and stop != _last_pickup:
			var earn : int = GameState.passengers * randi_range(10, 50)
			GameState.add_money(earn)
			GameState.passengers = 0
			GameState.passengers_changed.emit(0)
			GameState.toast.emit("Delivered! +%d coins" % earn)
			_last_pickup = null
			break
		# Otherwise board waiting passengers (only at a new stop).
		elif stop.waiting > 0 and GameState.passengers < BUS_CAPACITY and stop != _last_pickup:
			var board : int = mini(stop.waiting, BUS_CAPACITY - GameState.passengers)
			GameState.passengers += board
			stop.waiting -= board
			stop.update_visual()
			_last_pickup = stop
			GameState.passengers_changed.emit(GameState.passengers)
			GameState.toast.emit("Boarded %d passenger(s)" % board)
			break
