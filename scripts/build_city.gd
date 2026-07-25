extends Node3D
class_name CityBuilder
# ============================================================
#  CityBuilder — procedurally places the static city scenery
#  (sidewalks + 18 muted PBR buildings) as CSG nodes so the
#  World scene file stays small and easy to read. All materials
#  are StandardMaterial3D with PBR values (roughness 0.7).
# ============================================================

const BUILDING_COLORS := [
	Color(0.55, 0.58, 0.62), Color(0.62, 0.55, 0.50),
	Color(0.50, 0.58, 0.55), Color(0.60, 0.52, 0.60),
	Color(0.52, 0.56, 0.64), Color(0.66, 0.60, 0.50)
]

func _ready() -> void:
	_build_sidewalks()
	_build_buildings()

# Build a StandardMaterial3D with the given albedo (PBR).
func _mat(color : Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	m.metallic = 0.0
	return m

# Raised sidewalks alongside the main cross roads.
func _build_sidewalks() -> void:
	var walk_mat : StandardMaterial3D = _mat(Color(0.75, 0.75, 0.72))
	for sx : float in [-7.5, 7.5]:
		var w := CSGBox3D.new()
		w.size = Vector3(3.0, 0.4, 500.0)
		w.position = Vector3(sx, 0.2, 0.0)
		w.material = walk_mat
		add_child(w)
	for sz : float in [-7.5, 7.5]:
		var w := CSGBox3D.new()
		w.size = Vector3(500.0, 0.4, 3.0)
		w.position = Vector3(0.0, 0.2, sz)
		w.material = walk_mat
		add_child(w)

# 18 muted buildings placed in the city blocks between roads.
func _build_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var roads := [-80.0, 0.0, 80.0]
	var positions : Array = []
	# Block centers between consecutive road lines.
	for i in range(roads.size() - 1):
		for j in range(roads.size() - 1):
			var cx : float = (float(roads[i]) + float(roads[i + 1])) / 2.0
			var cz : float = (float(roads[j]) + float(roads[j + 1])) / 2.0
			positions.append(Vector3(cx - 18.0, 0.0, cz - 18.0))
			positions.append(Vector3(cx + 18.0, 0.0, cz + 18.0))
	# Shuffle for variety.
	for n in range(positions.size()):
		var a : int = rng.randi_range(0, positions.size() - 1)
		var b : int = rng.randi_range(0, positions.size() - 1)
		var tmp = positions[a]; positions[a] = positions[b]; positions[b] = tmp
	var count : int = mini(positions.size(), 18)
	for n in range(count):
		var p : Vector3 = positions[n]
		var h : float = rng.randf_range(8.0, 34.0)
		var bw : float = rng.randf_range(8.0, 14.0)
		var bd : float = rng.randf_range(8.0, 14.0)
		var b := CSGBox3D.new()
		b.size = Vector3(bw, h, bd)
		b.position = Vector3(p.x, h / 2.0, p.z)
		var col : Color = BUILDING_COLORS[rng.randi_range(0, BUILDING_COLORS.size() - 1)]
		b.material = _mat(col)
		add_child(b)
