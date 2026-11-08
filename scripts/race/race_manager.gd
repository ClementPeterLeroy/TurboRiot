class_name RaceManager
extends Node
## Orchestrates the model, physical gates and kart. No driving/camera math.
@export var track: TrackBuilder
@export var kart: KartController
@export_range(1, 20) var lap_count: int = 3

var session := RaceSession.new()
var gates: Array[CheckpointGate] = []
var _previous_position := Vector3.ZERO
var _start_spawn := Transform3D.IDENTITY
var debug_visible := false

func _ready() -> void:
	assert(track != null and kart != null)
	session.state_changed.connect(_on_state_changed)
	kart.reset_performed.connect(_resample_position)
	track.geometry_rebuilt.connect(_on_track_rebuilt)
	_on_track_rebuilt()

func _on_track_rebuilt() -> void:
	gates.clear()
	for gate: CheckpointGate in track.get_node("Generated/Checkpoints").get_children():
		gates.append(gate)
	session.checkpoint_count = gates.size()
	session.lap_count = lap_count
	_start_spawn = track.spawn_transform()
	return_to_ready()

func start_race() -> void:
	session.start()
	_resample_position()

func restart_race() -> void:
	_restore_start()
	session.reset(true)

func return_to_ready() -> void:
	_restore_start()
	session.reset()

func _restore_start() -> void:
	kart.safe_spawn = _start_spawn
	kart.reset_to_spawn()

func _physics_process(delta: float) -> void:
	var was_racing := session.state == RaceSession.State.RACING
	session.advance(delta)
	if was_racing:
		process_movement(_previous_position, kart.global_position)
	_previous_position = kart.global_position

func process_movement(from: Vector3, to: Vector3) -> void:
	if session.state != RaceSession.State.RACING:
		return
	var crossings: Array[Dictionary] = []
	for gate in gates:
		var fraction := gate.crossing_fraction(from, to)
		if fraction >= 0.0:
			crossings.append({"gate": gate, "fraction": fraction})
	crossings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.fraction < b.fraction)
	for crossing in crossings:
		var gate: CheckpointGate = crossing.gate
		if session.cross_checkpoint(gate.gate_index):
			kart.safe_spawn = gate.recovery_transform()

func set_debug_visible(value: bool) -> void:
	debug_visible = value
	for gate in gates:
		gate.set_debug_visible(value)

func _on_state_changed(state: RaceSession.State) -> void:
	kart.driving_enabled = state == RaceSession.State.RACING
	if not kart.driving_enabled:
		kart.velocity = Vector3.ZERO
		kart.signed_speed = 0.0
	_resample_position()

func _resample_position() -> void:
	# Teleports/recoveries never become swept checkpoint crossings.
	_previous_position = kart.global_position
