class_name CircuitOutline
extends Control
## Immutable sampled snapshots are shared across cards/menu visits. Geometry is
## projected only on resize/configuration; there is no per-frame preview work.
static var _cache: Dictionary = {}
var snapshot: Dictionary = {}
var accent := Color("40d5e5")
var projected := PackedVector2Array()
var elevated: Array[PackedVector2Array] = []
var branch_snapshots: Array[Dictionary] = []
var branch_lines: Array[PackedVector2Array] = []

func configure_branches(curves: Array[Curve3D]) -> void:
	branch_snapshots.clear()
	for curve in curves: branch_snapshots.append(snapshot_for(curve))
	_project()

static func snapshot_for(curve: Curve3D) -> Dictionary:
	if not curve: return {}
	var id := curve.get_instance_id()
	if _cache.has(id): return _cache[id]
	var points := PackedVector2Array()
	var heights := PackedFloat32Array()
	var length := curve.get_baked_length()
	var count := maxi(4, ceili(length / 2))
	var minimum := INF
	for i in range(count + 1):
		var p := curve.sample_baked(length * i / count, true)
		points.append(Vector2(p.x, p.z))
		heights.append(p.y)
		minimum = minf(minimum, p.y)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for p in points: bounds = bounds.expand(p)
	var data := {"curve": curve, "points": points, "heights": heights, "minimum": minimum, "bounds": bounds}
	_cache[id] = data
	curve.changed.connect(func() -> void: _cache.erase(id), CONNECT_ONE_SHOT)
	return data

func configure(curve: Curve3D, color: Color) -> void:
	snapshot = snapshot_for(curve)
	accent = color
	_project()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_project)
	_project()

func _project() -> void:
	projected.clear()
	elevated.clear()
	branch_lines.clear()
	if snapshot.is_empty(): return
	var bounds: Rect2 = snapshot.bounds
	var area := (size - Vector2.ONE * 48).max(Vector2.ONE)
	var scale_factor := minf(area.x / maxf(bounds.size.x, 1), area.y / maxf(bounds.size.y, 1))
	var origin := size / 2 - bounds.get_center() * scale_factor
	for data in branch_snapshots:
		var line := PackedVector2Array()
		for p in data.points: line.append(p*scale_factor+origin)
		branch_lines.append(line)
	var raised := PackedVector2Array()
	for i in snapshot.points.size():
		var p: Vector2 = snapshot.points[i] * scale_factor + origin
		projected.append(p)
		if snapshot.heights[i] > snapshot.minimum + 2:
			raised.append(p)
		elif not raised.is_empty():
			if raised.size() > 1: elevated.append(raised)
			raised = PackedVector2Array()
	if raised.size() > 1: elevated.append(raised)
	queue_redraw()

func _draw() -> void:
	if projected.size() < 2: return
	draw_polyline(projected, Color("07121f"), 13, true)
	draw_polyline(projected, accent, 5, true)
	for line in branch_lines:
		draw_polyline(line, Color("07121f"), 13, true)
		draw_polyline(line, accent, 5, true)
	# Redraw higher road last with a dark clearance band at the crossing.
	for segment in elevated:
		draw_polyline(segment, Color("07121f"), 13, true)
		draw_polyline(segment, accent, 5, true)
	draw_circle(projected[0], 7, Color("07121f"))
	draw_circle(projected[0], 4, Color("ffdc56"))
