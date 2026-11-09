class_name RaceManager
extends Node
## Each physical kart owns its own race model, validation and recovery cursor.
const KART_SCENE := preload("res://scenes/kart.tscn")
const PROFILES := [preload("res://resources/ai/casual.tres"), preload("res://resources/ai/standard.tres"), preload("res://resources/ai/challenging.tres")]
const NAMES := ["Rivet", "Comet", "Moxie", "Volt", "Dash", "Echo", "Blaze", "Pip", "Nova", "Bolt", "Jinx"]
const COLOURS := [Color("ef4444"), Color("3b82f6"), Color("facc15"), Color("22c55e"), Color("a855f7"), Color("22d3ee"), Color("f97316")]
@export var track: TrackBuilder
@export var kart: KartController
@export_range(1, 20) var lap_count := 3
@export_range(0, 11) var opponent_count := 6
@export_enum("Casual", "Standard", "Challenging") var difficulty := 1
@export var driver_profile_override: AIDriverProfile
@export var ai_only := false
@export_range(3.0, 12.0) var grid_row_spacing := 5.5
@export_range(2.0, 6.0) var grid_lane_spacing := 4.2
@export_range(0.0, 3.0) var grid_stagger := 2.0
@export var finish_grace_seconds := 60.0
@export var race_timeout_seconds := 480.0
@export_range(0.0, 1.0) var minimum_interval_travel_ratio := 0.55
@export var maximum_sweep_distance := 8.0
var session := RaceSession.new() # Original player-facing API is preserved.
var competitors: Array[CompetitorState] = []
var gates: Array[CheckpointGate] = []
var racing_line := RacingLine.new()
var phase := RaceSession.State.READY
var race_complete := false
var debug_visible := false
var debug_ai_index := 0
var _previous_position := Vector3.ZERO
var _interval_travel := 0.0
var _start_spawn := Transform3D.IDENTITY
var _ranking: Array[CompetitorState] = []
var _pending: Array[CompetitorState] = []
var _finish_count := 0
var _clock := 0.0
var _first_finish := -1.0
var _batch := false
var _tick_delta := 0.0
var _debug_root: Node3D
var _debug_targets: ImmediateMesh
var _debug_timer := 0.0

func _ready() -> void:
	assert(track and kart)
	process_physics_priority = 10 # Validate after every kart moves.
	for argument in OS.get_cmdline_user_args():
		if argument == "--ai-only": ai_only = true
		if argument.begins_with("--opponents="): opponent_count = clampi(argument.get_slice("=", 1).to_int(), 0, 11)
		if argument.begins_with("--difficulty="):
			var selected := ["casual", "standard", "challenging"].find(argument.get_slice("=", 1).to_lower())
			if selected >= 0: difficulty = selected
	track.geometry_rebuilt.connect(_on_track_rebuilt)
	_on_track_rebuilt()

func _on_track_rebuilt() -> void:
	gates.clear()
	for gate: CheckpointGate in track.get_node("Generated/Checkpoints").get_children(): gates.append(gate)
	racing_line.build(track)
	if competitors.is_empty(): _create_field()
	for record in competitors:
		record.session.checkpoint_count = gates.size()
		record.session.lap_count = lap_count
		record.grid = grid_transform(record.id)
		if record.kart.input_provider is AIInput: record.kart.input_provider.line = racing_line
	_start_spawn = competitors[0].grid
	if is_instance_valid(_debug_root):
		_debug_root.free()
		_debug_root = null
	return_to_ready()
	if debug_visible: set_debug_visible(true)

func grid_transform(index: int) -> Transform3D:
	if opponent_count == 0 and index == 0: return track.spawn_transform()
	var row := index / 2
	var column := index % 2
	var offset := fposmod(-4.0 - row * grid_row_spacing - column * grid_stagger, racing_line.length)
	var forward := track.sample_forward(offset)
	var side := (-0.5 if column == 0 else 0.5) * grid_lane_spacing
	return track.global_transform * Transform3D(Basis.looking_at(forward), track.sample_center(offset) + forward.cross(Vector3.UP) * side + Vector3.UP * 0.65)

func _create_field() -> void:
	var container := Node3D.new()
	container.name = "Opponents"
	add_child(container)
	container.top_level = true
	container.global_transform = Transform3D.IDENTITY
	for index in opponent_count + 1:
		var record := CompetitorState.new()
		record.id = index
		record.is_player = index == 0
		record.display_name = ("You (AI)" if ai_only else "You") if index == 0 else NAMES[index - 1]
		record.session = session if index == 0 else RaceSession.new()
		record.kart = kart if index == 0 else KART_SCENE.instantiate() as KartController
		record.grid = grid_transform(index)
		record.session.checkpoint_count = gates.size()
		record.session.lap_count = lap_count
		competitors.append(record)
		if index > 0 or ai_only:
			var old_input := record.kart.get_node("PlayerInput")
			record.kart.remove_child(old_input)
			old_input.free()
			var driver := AIInput.new()
			driver.name = "AIInput"
			driver.kart = record.kart
			driver.line = racing_line
			driver.driver_id = index
			driver.profile = driver_profile_override if driver_profile_override else PROFILES[difficulty]
			driver.recovery_requested.connect(_on_ai_recovery.bind(record))
			record.kart.input_provider = driver
			record.kart.add_child(driver)
		if index > 0:
			record.kart.name = "Kart" + record.display_name
			record.kart.transform = record.grid
			container.add_child(record.kart)
			for mesh_name in ["Chassis", "Nose"]:
				var mesh := record.kart.get_node("Visual/" + mesh_name) as MeshInstance3D
				var paint := mesh.material_override.duplicate() as StandardMaterial3D
				paint.albedo_color = COLOURS[index % COLOURS.size()]
				mesh.material_override = paint
			var label := Label3D.new()
			label.name = "DriverName"
			label.text = record.display_name
			label.position.y = 1.65
			label.font_size = 28
			label.pixel_size = 0.006
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			record.kart.get_node("Visual").add_child(label)
		record.session.state_changed.connect(_on_competitor_state.bind(record))
		record.kart.reset_performed.connect(_on_kart_reset.bind(record))
	var physical_karts: Array[KartController] = []
	for record in competitors: physical_karts.append(record.kart)
	for record in competitors:
		if record.kart.input_provider is AIInput: record.kart.input_provider.traffic = physical_karts
	_ranking.assign(competitors)

func start_race() -> void:
	if session.state == RaceSession.State.READY: _reset_field(true)

func restart_race() -> void:
	_reset_field(true)

func return_to_ready() -> void:
	_reset_field(false)

func _reset_field(countdown: bool) -> void:
	phase = RaceSession.State.COUNTDOWN if countdown else RaceSession.State.READY
	race_complete = false
	_clock = 0
	_first_finish = -1
	_finish_count = 0
	_pending.clear()
	_tick_delta = 0
	for record in competitors:
		record.finish_order = 0
		record.finish_timestamp = 0
		record.dnf = false
		record.recoveries = 0
		record.kart.collision_layer = 2
		record.kart.collision_mask = 3
		record.kart.safe_spawn = record.grid
		record.kart.reset_to_spawn()
		record.session.reset(countdown)
		_update_driver_gates(record)
	_update_ranking()

func _restore_start() -> void:
	for record in competitors:
		record.kart.safe_spawn = record.grid
		record.kart.reset_to_spawn()

func _physics_process(delta: float) -> void:
	var was_racing := phase == RaceSession.State.RACING
	session.advance(delta)
	if phase == RaceSession.State.COUNTDOWN:
		for record in competitors:
			if not record.is_player: record.session.countdown_remaining = session.countdown_remaining
	if was_racing:
		_clock += delta
		_tick_delta = delta
		_batch = true
		for record in competitors:
			if not record.is_player: record.session.advance(delta)
			_process_record(record, record.previous_position, record.kart.global_position)
			record.previous_position = record.kart.global_position
		_batch = false
		_flush_finishes()
		if (_first_finish >= 0 and _clock >= _first_finish + finish_grace_seconds) or _clock >= race_timeout_seconds:
			for record in competitors:
				if record.session.state == RaceSession.State.RACING: mark_dnf(record)
		var all_done := true
		for record in competitors: all_done = all_done and record.session.state == RaceSession.State.FINISHED
		if all_done:
			race_complete = true
			phase = RaceSession.State.FINISHED
		_update_ranking()
	_sync_player_aliases()
	if debug_visible:
		_debug_timer -= delta
		if _debug_timer <= 0:
			_refresh_ai_debug()
			_debug_timer = 0.2

func process_movement(from: Vector3, to: Vector3) -> void:
	_process_record(competitors[0], from, to)
	_sync_player_aliases()
	_update_ranking()

func process_competitor_movement(record: CompetitorState, from: Vector3, to: Vector3) -> void:
	_process_record(record, from, to)
	_update_ranking()

func _process_record(record: CompetitorState, from: Vector3, to: Vector3) -> void:
	var model := record.session
	if model.state != RaceSession.State.RACING: return
	var distance := Vector2(to.x - from.x, to.z - from.z).length()
	if distance > maximum_sweep_distance: return # No teleport-derived travel/gates/ranking.
	var length := racing_line.length
	var start := gates[model.latest_checkpoint].route_offset
	var expected := gates[model.next_checkpoint % gates.size()]
	var interval := fposmod(expected.route_offset - start, length)
	var projection := racing_line.project(to, record.projection_hint)
	record.projection_hint = int(projection.z)
	record.offset = projection.x
	var progress := fposmod(projection.x - start, length)
	var legal := racing_line.legal(to, projection)
	if legal and (progress <= interval + 3 or progress > length - 6): record.interval_travel += distance
	record.segment_progress = minf(clampf(progress / interval, 0, 0.999), clampf(record.interval_travel / interval, 0, 0.999)) if legal and progress <= interval + 3 else 0.0
	var crossing := expected.crossing_fraction(from, to)
	if crossing >= 0 and record.interval_travel >= interval * minimum_interval_travel_ratio:
		record.crossing_fraction = crossing
		if model.cross_checkpoint(expected.gate_index):
			record.kart.safe_spawn = expected.recovery_transform()
			record.interval_travel = 0
			record.segment_progress = 0
	_update_driver_gates(record)

func _update_driver_gates(record: CompetitorState) -> void:
	if record.kart.input_provider is AIInput:
		record.kart.input_provider.validated_offset = gates[record.session.latest_checkpoint].route_offset
		record.kart.input_provider.expected_offset = gates[record.session.next_checkpoint % gates.size()].route_offset

func _on_competitor_state(state: RaceSession.State, record: CompetitorState) -> void:
	if record.is_player and state == RaceSession.State.RACING and phase == RaceSession.State.COUNTDOWN:
		phase = RaceSession.State.RACING
		for other in competitors:
			if not other.is_player and other.session.state == RaceSession.State.COUNTDOWN: other.session.advance(other.session.countdown_remaining)
	record.kart.driving_enabled = state == RaceSession.State.RACING and not record.dnf
	if not record.kart.driving_enabled:
		record.kart.velocity = Vector3.ZERO
		record.kart.signed_speed = 0
	if state == RaceSession.State.FINISHED:
		# Finishers are nonblocking result ghosts, restored on restart.
		record.kart.collision_layer = 0
		record.kart.collision_mask = 1
		if not record.dnf and record.finish_order == 0:
			record.finish_timestamp = record.session.final_time - (_tick_delta * (1.0 - record.crossing_fraction) if _batch else 0.0)
			if _batch: _pending.append(record)
			else: _register_finish(record)
	_on_kart_reset(record)

func _register_finish(record: CompetitorState) -> void:
	if record.finish_order > 0: return
	_finish_count += 1
	record.finish_order = _finish_count
	if _first_finish < 0: _first_finish = _clock

func _flush_finishes() -> void:
	if _pending.is_empty(): return
	_pending.sort_custom(func(a: CompetitorState, b: CompetitorState) -> bool:
		return a.finish_timestamp < b.finish_timestamp if a.finish_timestamp != b.finish_timestamp else a.id < b.id)
	for record in _pending: _register_finish(record)
	_pending.clear()

func mark_dnf(record: CompetitorState) -> void:
	record.dnf = true
	record.session._set_state(RaceSession.State.FINISHED)
	record.session.final_time = 0

func _on_kart_reset(record: CompetitorState) -> void:
	record.previous_position = record.kart.global_position
	record.interval_travel = 0
	record.segment_progress = 0
	record.projection_hint = -1
	if record.is_player: _sync_player_aliases()

func _resample_position() -> void:
	_on_kart_reset(competitors[0])

func _sync_player_aliases() -> void:
	_previous_position = competitors[0].previous_position
	_interval_travel = competitors[0].interval_travel

func _on_ai_recovery(_reason: String, record: CompetitorState) -> void:
	if record.session.state == RaceSession.State.RACING and record.kart.get_node("Recovery").recover(): record.recoveries += 1

func _update_ranking() -> void:
	if _ranking.size() != competitors.size(): _ranking.assign(competitors)
	_ranking.sort_custom(_rank_before)

func _rank_before(a: CompetitorState, b: CompetitorState) -> bool:
	if a.finish_order > 0 or b.finish_order > 0:
		if a.finish_order == 0: return false
		if b.finish_order == 0: return true
		return a.finish_order < b.finish_order
	if a.dnf != b.dnf: return not a.dnf
	var difference := a.progress_units(gates.size()) - b.progress_units(gates.size())
	return difference > 0 if absf(difference) > 0.00001 else a.id < b.id

func standings() -> Array[CompetitorState]:
	return _ranking

func player_position() -> int:
	return _ranking.find(competitors[0]) + 1

func set_debug_visible(value: bool) -> void:
	debug_visible = value
	for gate in gates: gate.set_debug_visible(value)
	if value and not is_instance_valid(_debug_root): _create_ai_debug()
	if is_instance_valid(_debug_root): _debug_root.visible = value
	for record in competitors:
		var label := record.kart.get_node_or_null("Visual/AIDebug")
		if label: label.visible = value
	if value: _refresh_ai_debug()

func _create_ai_debug() -> void:
	_debug_root = Node3D.new()
	_debug_root.name = "AIDebug"
	add_child(_debug_root)
	_debug_root.top_level = true
	var mesh := ImmediateMesh.new()
	var paint := RiotGeometry.material(Color("ffe46b"))
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, paint)
	for i in racing_line.points.size():
		mesh.surface_add_vertex(racing_line.points[i] + Vector3.UP * 0.12)
		mesh.surface_add_vertex(racing_line.points[(i + 1) % racing_line.points.size()] + Vector3.UP * 0.12)
		if i % 5 == 0:
			mesh.surface_add_vertex(racing_line.points[i] + Vector3(-0.3, 0.13, 0))
			mesh.surface_add_vertex(racing_line.points[i] + Vector3(0.3, 0.13, 0))
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	_debug_root.add_child(visual)
	_debug_targets = ImmediateMesh.new()
	var targets := MeshInstance3D.new()
	targets.mesh = _debug_targets
	targets.material_override = paint
	_debug_root.add_child(targets)
	for record in competitors:
		if not record.kart.input_provider is AIInput or record.kart.has_node("Visual/AIDebug"): continue
		var label := Label3D.new()
		label.name = "AIDebug"
		label.position.y = 2.9
		label.font_size = 20
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		record.kart.get_node("Visual").add_child(label)

func _refresh_ai_debug() -> void:
	if not is_instance_valid(_debug_root): return
	_debug_targets.clear_surfaces()
	if competitors.size() == 1 and not ai_only: return
	_debug_targets.surface_begin(Mesh.PRIMITIVE_LINES)
	for record in competitors:
		if not record.kart.input_provider is AIInput: continue
		var driver := record.kart.input_provider as AIInput
		_debug_targets.surface_add_vertex(record.kart.global_position + Vector3.UP)
		_debug_targets.surface_add_vertex(driver.target_point + Vector3.UP * 0.2)
		record.kart.get_node("Visual/AIDebug").text = "%s | %.1f / %.1f m/s\nsteer %.2f brake %.2f drift %s\n%s | lap %d gate %d" % [record.display_name, record.kart.velocity.length(), driver.target_speed,
			driver.get_command().steering, driver.get_command().brake, record.kart.drift.active,
			driver.recovery_state, record.session.current_lap(), record.session.next_checkpoint % gates.size()]
	_debug_targets.surface_end()

func ai_debug_summary() -> String:
	var drivers: Array[CompetitorState] = []
	for record in competitors:
		if record.kart.input_provider is AIInput: drivers.append(record)
	if drivers.is_empty(): return ""
	var record := drivers[debug_ai_index % drivers.size()]
	var driver := record.kart.input_provider as AIInput
	return "\nAI %s (%s) | F8 next\nSpeed %.1f / Target %.1f m/s\nSteer %.2f Brake %.2f Drift %s\n%s | lap %d gate %d | recoveries %d" % [record.display_name, driver.profile.display_name,
		record.kart.velocity.length(), driver.target_speed, driver.get_command().steering, driver.get_command().brake,
		record.kart.drift.active, driver.recovery_state, record.session.current_lap(), record.session.next_checkpoint % gates.size(), record.recoveries]
