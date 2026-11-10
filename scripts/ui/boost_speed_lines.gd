class_name BoostSpeedLines
extends Control
## Screen-space feedback only. No camera/body transform writes or random flicker.
@export var kart: KartController
@export_range(8, 48) var streak_count := 28
@export var fade_rate := 9.0
var opacity := 0.0
var burst_remaining := 0.0
var normalized_focus := Vector2(0.5, 0.68)
var _serial := 0
var _clock := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	process_priority = 30 # Sample after the chase camera's render update.
	if kart: kart.reset_performed.connect(reset_feedback)

func reset_feedback() -> void:
	opacity = 0
	burst_remaining = 0
	_serial = kart.boost.feedback_serial if kart else 0
	queue_redraw()

func advance_feedback(boost: BoostController, driving: bool, delta: float) -> void:
	if not driving:
		opacity = 0
		burst_remaining = 0
		_serial = boost.feedback_serial
		return
	_clock += delta
	var active := boost.active() and boost.feedback_remaining > 0
	if active and boost.feedback_serial != _serial:
		burst_remaining = 0.24
	_serial = boost.feedback_serial
	burst_remaining = maxf(0, burst_remaining - delta)
	var strength := clampf((boost.strength - 1) / 0.5, 0.2, 1.2)
	var target := strength * (0.23 + 0.55 * burst_remaining / 0.24) if active else 0.0
	opacity = lerpf(opacity, target, 1 - exp(-(24.0 if target > opacity else fade_rate) * delta))
	if opacity < 0.001: opacity = 0

func _process(delta: float) -> void:
	if not is_instance_valid(kart): return
	advance_feedback(kart.boost, kart.driving_enabled, delta)
	var camera := get_viewport().get_camera_3d()
	if camera:
		var focus := kart.get_global_transform_interpolated().origin + Vector3.UP * 0.65
		if not camera.is_position_behind(focus):
			var screen := get_global_transform_with_canvas().affine_inverse() * camera.unproject_position(focus)
			normalized_focus = (screen / size.max(Vector2.ONE)).clamp(Vector2(0.1, 0.1), Vector2(0.9, 0.9))
	queue_redraw()

func streak_geometry(view_size: Vector2, focus: Vector2) -> Array[PackedVector2Array]:
	var geometry: Array[PackedVector2Array] = []
	var centre := focus * view_size
	for index in streak_count:
		var angle := TAU * (index + 0.21) / streak_count
		var direction := Vector2(cos(angle), sin(angle))
		var x_distance := (view_size.x - centre.x if direction.x > 0 else -centre.x) / direction.x if absf(direction.x) > 0.0001 else INF
		var y_distance := (view_size.y - centre.y if direction.y > 0 else -centre.y) / direction.y if absf(direction.y) > 0.0001 else INF
		var edge := minf(x_distance, y_distance)
		var wave := fposmod(_clock * 1.8 + index * 0.618, 1)
		var inner := centre + direction * edge * lerpf(0.66, 0.82, wave)
		var outer := centre + direction * edge * 1.05
		var width := minf(view_size.x, view_size.y) * 0.0015
		var side := direction.orthogonal() * width
		geometry.append(PackedVector2Array([inner, outer - side, outer + side]))
	return geometry

func _draw() -> void:
	if opacity == 0 or size.x <= 0 or size.y <= 0: return
	for streak in streak_geometry(size, normalized_focus):
		draw_colored_polygon(streak, Color(0.76, 0.94, 1, opacity * 0.34))
		draw_line(streak[0], (streak[1] + streak[2]) / 2, Color(1, 1, 1, opacity * 0.3), 1, true)
