extends Node
class_name FuelSystem
# ============================================================
#  FuelSystem — fuel drains while driving; refuel at fuel
#  stations for coins. Listens to GameState.refuel_requested
#  (the HUD fuel button).
# ============================================================

const REFUEL_RADIUS  := 9.0
const FUEL_PER_KM    := 0.04   # how fast the tank drains (tunable)
const PRICE_PER_UNIT := 1      # coins per 1% of fuel

var bus : Node3D = null
var _near_station : Node = null

func _ready() -> void:
	GameState.refuel_requested.connect(_on_refuel_requested)

func _physics_process(delta : float) -> void:
	if bus == null:
		bus = get_tree().get_first_node_in_group("bus")
		if bus == null:
			return
	# Drain fuel proportional to distance travelled.
	var spd : float = GameState.speed_kmh
	if spd > 0.5:
		var km : float = spd * delta / 3600.0   # km/h * h
		GameState.set_fuel(GameState.fuel - km * FUEL_PER_KM * 100.0)
	# Track the nearest fuel station in range.
	_near_station = null
	for node in get_tree().get_nodes_in_group("fuel_station"):
		var st := node as Node3D
		if st == null:
			continue
		if bus.global_position.distance_to(st.global_position) < REFUEL_RADIUS:
			_near_station = st
			break

func _on_refuel_requested() -> void:
	if _near_station == null:
		GameState.toast.emit("Drive to a fuel station to refuel")
		return
	if GameState.fuel >= 99.0:
		GameState.toast.emit("Tank is already full")
		return
	var need : float = 100.0 - GameState.fuel
	var cost : int = ceili(need * float(PRICE_PER_UNIT))
	if GameState.spend_money(cost):
		GameState.set_fuel(100.0)
		GameState.toast.emit("Refueled for %d coins" % cost)
	else:
		GameState.toast.emit("Not enough coins to refuel")
