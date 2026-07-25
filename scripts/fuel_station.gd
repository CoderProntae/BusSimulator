extends Node3D
class_name FuelStation
# ============================================================
#  FuelStation — tiny helper that registers a fuel-station
#  subtree (a box + sign built in World.tscn) into the
#  "fuel_station" group so the FuelSystem can find it.
# ============================================================

func _ready() -> void:
	add_to_group("fuel_station")
