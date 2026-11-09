class_name PresentationDiagnostics
extends Node
## Optional render-frame capture. Mode switches never touch driving physics.
const LABELS := ["A Normal", "B Static visuals", "C Fixed camera orientation", "D Minimal rendering"]
var mode := 0
var latest: Dictionary = {}
var capture_path := ""
var _file: FileAccess
var _elapsed := 0.0
var _frames := 0
var _physics_frames := 0
var rendered_fps := 0.0
var physics_fps := 0.0
var _flush_elapsed := 0.0
@onready var kart: KartController = get_parent().get_node("Kart")
@onready var camera: Camera3D = get_parent().get_node("ChaseCamera")

func _ready() -> void:
	process_priority = 100 # Sample after visuals, camera and HUD.

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F4:
		set_mode((mode + 1) % LABELS.size())
	elif event.keycode == KEY_F6:
		if _file: stop_capture()
		else: start_capture()
	elif event.keycode == KEY_F7:
		Engine.max_fps = 60 if Engine.max_fps == 0 else (120 if Engine.max_fps == 60 else 0)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	else:
		return
	get_viewport().set_input_as_handled()
	get_parent().get_node("HUD").debug_visible = true

func set_mode(value: int) -> void:
	mode = clampi(value, 0, 3)
	kart.get_node("Visual").cosmetics_enabled = mode == 0 or mode == 2
	camera.set_diagnostic_mode(1 if mode == 2 else (2 if mode == 3 else 0))

func start_capture() -> void:
	stop_capture()
	capture_path = "user://presentation_%s_%d.csv" % [Time.get_datetime_string_from_system().replace(":", "-"), Time.get_ticks_msec()]
	_file = FileAccess.open(capture_path, FileAccess.WRITE)
	if _file:
		_file.store_csv_line(PackedStringArray(["time_us", "mode", "physics_tick", "physics_fps", "render_fps", "grounded", "body_position", "body_rotation", "visual_local_transform", "visual_global_transform", "render_body_transform", "render_visual_transform", "camera_position", "camera_rotation", "camera_relative_position", "relative_pitch_deg", "helmet_screen_y", "nose_screen_y"]))
		print("Presentation capture: ", ProjectSettings.globalize_path(capture_path))

func stop_capture() -> void:
	if _file:
		_file.flush()
		_file.close()
		_file = null

func _exit_tree() -> void:
	stop_capture()

func _physics_process(_delta: float) -> void:
	_physics_frames += 1

func _process(delta: float) -> void:
	_elapsed += delta
	_frames += 1
	if _elapsed >= 0.5:
		rendered_fps = _frames / _elapsed
		physics_fps = _physics_frames / _elapsed
		_elapsed = 0
		_frames = 0
		_physics_frames = 0
	if not _file and not get_parent().get_node("HUD").debug_visible:
		return
	latest = sample()
	if _file:
		_file.store_csv_line(PackedStringArray([str(Time.get_ticks_usec()), LABELS[mode], str(Engine.get_physics_frames()), str(physics_fps), str(rendered_fps), str(kart.is_on_floor()), str(kart.global_position), str(kart.global_rotation), str(latest.visual_local), str(latest.visual_global), str(latest.render_body), str(latest.render_visual), str(camera.global_position), str(camera.global_rotation), str(latest.relative_position), str(latest.relative_pitch), str(latest.helmet_y), str(latest.nose_y)]))
		_flush_elapsed += delta
		if _flush_elapsed >= 1:
			_file.flush()
			_flush_elapsed = 0

func sample() -> Dictionary:
	var visual := kart.get_node("Visual") as Node3D
	# Use exactly the pose sampled by the camera this render frame, rather
	# than mixing its smooth frame with the body's latest discrete physics tick.
	var pose: Transform3D = camera.render_target_transform
	var render_visual := pose * visual.transform
	var relative := camera.global_position - pose.origin
	var relative_basis := pose.basis.inverse() * camera.global_basis
	return {"visual_local": visual.transform, "visual_global": visual.global_transform,
		"render_body": pose, "render_visual": render_visual,
		"relative_position": relative, "relative_pitch": rad_to_deg(relative_basis.get_euler().x),
		"helmet_y": camera.unproject_position(render_visual * Vector3(0, 0.8, 0.1)).y,
		"nose_y": camera.unproject_position(render_visual * Vector3(0, 0.2, -0.65)).y}
