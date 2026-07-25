extends Node
class_name GameState
# ============================================================
#  GameState — global singleton (autoload) that holds all
#  shared gameplay data and the control-input bridge between
#  the touch HUD and the 3D gameplay systems. The HUD writes
#  continuous inputs here; the bus, camera and systems read
#  them. Momentary actions are dispatched through signals.
# ============================================================

# --- Economy / status (read & written by systems + HUD) ---
var money : int = 500                 # starting coins
var fuel : float = 100.0              # fuel tank, percent 0..100
var passengers : int = 0              # onboard passenger count
var speed_kmh : float = 0.0          # current speed readout
var current_route : String = "City Loop"

# --- Continuous control inputs (set by the touch HUD) ---
var steer_input : float = 0.0        # -1 = left, +1 = right
var throttle_input : float = 0.0     # 0..1 gas pedal
var brake_input : float = 0.0        # 0..1 brake pedal

# --- Momentary action signals (fired by HUD buttons) ---
signal horn_pressed
signal door_toggle_requested
signal camera_cycle_requested
signal refuel_requested

# --- State-change signals (for the HUD readouts) ---
signal money_changed(value : int)
signal fuel_changed(value : float)
signal passengers_changed(value : int)
signal speed_changed(value : float)
signal toast(message : String)

# Add coins earned from delivering passengers.
func add_money(amount : int) -> void:
	#print("add_money ", amount)  # debug
	money += amount
	money_changed.emit(money)

# Spend coins if affordable. Returns true on success.
func spend_money(amount : int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false

# Clamp + publish fuel level changes.
func set_fuel(value : float) -> void:
	fuel = clampf(value, 0.0, 100.0)
	fuel_changed.emit(fuel)
