class_name CircuitMap
extends Control
## The same actual Curve3D feeds selection cards and the live HUD.
var route: Curve3D
var track: TrackBuilder
var race: RaceManager
var bounds := Rect2()
var samples := PackedVector2Array()
var _line := PackedVector2Array()
var _map_scale := 0.0
var _map_origin := Vector2.ZERO
var _background := StyleBoxFlat.new()
var _markers: MarkerLayer

class MarkerLayer extends Control:
	var map: CircuitMap
	func _draw() -> void: map._draw_markers(self)

func configure(curve: Curve3D) -> void:
	route = curve
	samples.clear()
	if not route: return
	# A minimap needs screen-space detail, not the physics curve's 15 cm bake.
	# Two-metre samples retain subpixel corner accuracy at HUD/card sizes.
	var length := route.get_baked_length()
	var count := maxi(4, ceili(length / 2.0))
	for index in range(count + 1):
		var point := route.sample_baked(length * index / count, true)
		samples.append(Vector2(point.x, point.z))
	if samples.is_empty(): return
	bounds = Rect2(samples[0], Vector2.ZERO)
	for point in samples: bounds = bounds.expand(point)
	bounds = bounds.grow(12)
	_update_projection()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.bg_color = Color(0.02, 0.05, 0.08, 0.82)
	_background.set_corner_radius_all(8)
	_markers = MarkerLayer.new()
	_markers.map = self
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_markers)
	_markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_update_projection)
	_update_projection()

func _update_projection() -> void:
	_map_scale = minf(size.x / maxf(bounds.size.x, 1), size.y / maxf(bounds.size.y, 1))
	_map_origin = size * 0.5 - bounds.get_center() * _map_scale
	_line.resize(samples.size())
	for index in samples.size(): _line[index] = project(samples[index])
	queue_redraw() # Static route changes only after configuration or resizing.

func project(point: Vector2) -> Vector2:
	return point * _map_scale + _map_origin

func _process(_delta: float) -> void:
	if is_instance_valid(race) and is_instance_valid(_markers) and is_visible_in_tree(): _markers.queue_redraw()

func _draw() -> void:
	if _line.size() < 2: return
	draw_style_box(_background, Rect2(Vector2.ZERO, size))
	draw_polyline(_line, Color("101b29"), 9, true)
	draw_polyline(_line, Color("93d6df"), 4, true)
	draw_circle(_line[0], 5, Color("ffda58"))

func _draw_markers(canvas: Control) -> void:
	if not is_instance_valid(race) or not is_instance_valid(track): return
	for record in race.competitors:
		var position_on_track := track.to_local(record.kart.get_global_transform_interpolated().origin)
		canvas.draw_circle(project(Vector2(position_on_track.x, position_on_track.z)), 4 if record.is_player else 2.5,
			Color("ffda58") if record.is_player else Color("fafafa"))
