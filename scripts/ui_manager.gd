extends CanvasLayer
class_name UIManager
# ============================================================
#  UIManager (HUD) — builds the touch interface and keeps the
#  on-screen readouts in sync with GameState. Large, semi-
#  transparent, thumb-friendly buttons laid out for mobile
#  landscape (1280x720). Keyboard fallback is handled by the
#  bus controller, so this HUD only writes GameState.
# ============================================================

var _money_label : Label
var _fuel_bar : ProgressBar
var _fuel_fill : StyleBoxFlat
var _passenger_label : Label
var _route_label : Label
var _speed_label : Label
var _toast_label : Label
var _toast_timer : Timer

func _ready() -> void:
	_build_hud()
	# Keep readouts in sync with the shared game state.
	GameState.money_changed.connect(_on_money_changed)
	GameState.fuel_changed.connect(_on_fuel_changed)
	GameState.passengers_changed.connect(_on_passengers_changed)
	GameState.speed_changed.connect(_on_speed_changed)
	GameState.toast.connect(_on_toast)
	# Push the initial values.
	_on_money_changed(GameState.money)
	_on_fuel_changed(GameState.fuel)
	_on_passengers_changed(GameState.passengers)
	_on_speed_changed(GameState.speed_kmh)

# ----------------------------------------------------------
#  HUD construction
# ----------------------------------------------------------
func _build_hud() -> void:
	var root := Control.new()
	root.name = "TouchUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ---------- TOP BAR ----------
	var top := HBoxContainer.new()
	top.name = "TopBar"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 10
	top.offset_left = 12
	top.offset_right = -12
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	# Money (top-left)
	var money_box := HBoxContainer.new()
	var coin := _make_swatch(Color(1.0, 0.84, 0.0), 30)
	_money_label = Label.new()
	_money_label.text = "500"
	_money_label.add_theme_font_size_override("font_size", 32)
	_money_label.add_theme_color_override("font_color", Color.WHITE)
	money_box.add_child(coin)
	money_box.add_child(_money_label)
	top.add_child(money_box)

	top.add_child(_spacer(true))

	# Route + passengers (top-center)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	_route_label = Label.new()
	_route_label.text = GameState.current_route
	_route_label.add_theme_font_size_override("font_size", 22)
	_route_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_passenger_label = Label.new()
	_passenger_label.text = "Passengers: 0"
	_passenger_label.add_theme_font_size_override("font_size", 22)
	_passenger_label.add_theme_color_override("font_color", Color.WHITE)
	center.add_child(_route_label)
	center.add_child(_passenger_label)
	top.add_child(center)

	top.add_child(_spacer(true))

	# Fuel (top-right)
	var fuel_box := VBoxContainer.new()
	var fuel_title := Label.new()
	fuel_title.text = "FUEL"
	fuel_title.add_theme_font_size_override("font_size", 16)
	fuel_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_fuel_bar = ProgressBar.new()
	_fuel_bar.custom_minimum_size = Vector2(220, 26)
	_fuel_bar.max_value = 100.0
	_fuel_bar.value = GameState.fuel
	_fuel_bar.show_percentage = false
	_fuel_fill = StyleBoxFlat.new()
	_fuel_fill.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	_fuel_bar.add_theme_stylebox_override("fill", _fuel_fill)
	fuel_box.add_child(fuel_title)
	fuel_box.add_child(_fuel_bar)
	top.add_child(fuel_box)

	# ---------- BOTTOM BAR ----------
	var bottom := HBoxContainer.new()
	bottom.name = "BottomBar"
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_bottom = -10
	bottom.offset_left = 12
	bottom.offset_right = -12
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)

	# Steering (bottom-left)
	var steer := HBoxContainer.new()
	var btn_left := _make_button("◀", Vector2(120, 120))
	var btn_right := _make_button("▶", Vector2(120, 120))
	btn_left.button_down.connect(func(): GameState.steer_input = -1.0)
	btn_left.button_up.connect(func(): _release_steer(-1.0))
	btn_right.button_down.connect(func(): GameState.steer_input = 1.0)
	btn_right.button_up.connect(func(): _release_steer(1.0))
	steer.add_child(btn_left)
	steer.add_child(btn_right)
	bottom.add_child(steer)

	bottom.add_child(_spacer(true))

	# Center: speed readout + action buttons
	var center_col := VBoxContainer.new()
	center_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_speed_label = Label.new()
	_speed_label.text = "0 km/h"
	_speed_label.add_theme_font_size_override("font_size", 34)
	_speed_label.add_theme_color_override("font_color", Color.YELLOW)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_col.add_child(_speed_label)
	var actions := HBoxContainer.new()
	var b_horn := _make_button("HORN", Vector2(110, 70))
	var b_door := _make_button("DOOR", Vector2(110, 70))
	var b_cam  := _make_button("CAM", Vector2(110, 70))
	var b_fuel := _make_button("FUEL", Vector2(110, 70))
	b_horn.pressed.connect(func(): GameState.horn_pressed.emit())
	b_door.pressed.connect(func(): GameState.door_toggle_requested.emit())
	b_cam.pressed.connect(func(): GameState.camera_cycle_requested.emit())
	b_fuel.pressed.connect(func(): GameState.refuel_requested.emit())
	actions.add_child(b_horn)
	actions.add_child(b_door)
	actions.add_child(b_cam)
	actions.add_child(b_fuel)
	center_col.add_child(actions)
	bottom.add_child(center_col)

	bottom.add_child(_spacer(true))

	# Pedals (bottom-right)
	var pedals := VBoxContainer.new()
	var btn_gas := _make_button("GAS", Vector2(150, 110))
	var btn_brake := _make_button("BRAKE", Vector2(150, 110))
	btn_gas.button_down.connect(func(): GameState.throttle_input = 1.0)
	btn_gas.button_up.connect(func(): GameState.throttle_input = 0.0)
	btn_brake.button_down.connect(func(): GameState.brake_input = 1.0)
	btn_brake.button_up.connect(func(): GameState.brake_input = 0.0)
	pedals.add_child(btn_gas)
	pedals.add_child(btn_brake)
	bottom.add_child(pedals)

	# ---------- Toast message ----------
	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.add_theme_color_override("font_color", Color.WHITE)
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.offset_top = 70
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_toast_label)
	_toast_timer = Timer.new()
	_toast_timer.wait_time = 2.2
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(func(): _toast_label.text = "")
	root.add_child(_toast_timer)

# ----------------------------------------------------------
#  Small UI helpers
# ----------------------------------------------------------
# Build a large, rounded, semi-transparent button.
func _make_button(text : String, size : Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 30)
	b.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.2, 0.35, 0.45)
	style.border_color = Color(0.6, 0.8, 1.0, 0.7)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	b.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.2, 0.4, 0.7, 0.6)
	b.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate()
	pressed.bg_color = Color(0.3, 0.6, 1.0, 0.75)
	b.add_theme_stylebox_override("pressed", pressed)
	return b

# A small colored circle (used as the coin icon).
func _make_swatch(color : Color, size : int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = size / 2
	sb.corner_radius_top_right = size / 2
	sb.corner_radius_bottom_left = size / 2
	sb.corner_radius_bottom_right = size / 2
	c.add_theme_stylebox_override("panel", sb)
	return c

# An empty expanding control used to space HUD clusters apart.
func _spacer(expand : bool) -> Control:
	var c := Control.new()
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

# Only reset steering if this button was the active direction.
func _release_steer(dir : float) -> void:
	if GameState.steer_input == dir:
		GameState.steer_input = 0.0

# ----------------------------------------------------------
#  Readout updates
# ----------------------------------------------------------
func _on_money_changed(v : int) -> void:
	if _money_label != null:
		_money_label.text = str(v)

func _on_fuel_changed(v : float) -> void:
	if _fuel_bar != null:
		_fuel_bar.value = v
	if _fuel_fill != null:
		# Green when full, red when empty.
		_fuel_fill.bg_color = Color(1.0 - v / 100.0, v / 100.0, 0.2, 1.0)

func _on_passengers_changed(v : int) -> void:
	if _passenger_label != null:
		_passenger_label.text = "Passengers: %d" % v

func _on_speed_changed(v : float) -> void:
	if _speed_label != null:
		_speed_label.text = "%d km/h" % int(v)

func _on_toast(message : String) -> void:
	if _toast_label != null:
		_toast_label.text = message
		_toast_timer.start()
