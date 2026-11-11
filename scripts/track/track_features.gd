@tool
extends Node3D
const PAD := preload("res://scenes/boost_pad.tscn")
const RAMP := preload("res://scenes/ramp.tscn")
@export var track: TrackBuilder
@export var ramp_enabled := true
@export var boost_fractions := PackedFloat32Array([0.55, 0.81]):
	set(value):
		boost_fractions = value
		_schedule()
@export_range(0.0, 1.0) var ramp_fraction: float = 0.56:
	set(value):
		ramp_fraction = value
		_schedule()
@export var ramp_side_offset: float = -10.5:
	set(value):
		ramp_side_offset = value
		_schedule()
var _queued := false

func _ready() -> void:
	track.geometry_rebuilt.connect(_schedule)
	build()

func _schedule() -> void:
	if is_inside_tree() and not _queued:
		_queued = true
		build.call_deferred()

func build() -> void:
	_queued = false
	var previous := get_node_or_null("Generated")
	if previous:
		remove_child(previous)
		previous.queue_free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	var length := track.curve.get_baked_length()
	for fraction in boost_fractions:
		var pad := PAD.instantiate() as BoostPad
		generated.add_child(pad)
		var offset := length * clampf(fraction, 0.0, 1.0)
		pad.global_transform = track.global_transform * Transform3D(Basis.looking_at(track.sample_forward(offset)),
			track.sample_center(offset) + Vector3.UP * 0.02)
	if not ramp_enabled: return
	var ramp := RAMP.instantiate() as KartRamp
	ramp.name = "RunoffJump"
	generated.add_child(ramp)
	var offset := length * ramp_fraction
	var position_on_track := track.sample_center(offset) + track.sample_forward(offset).cross(Vector3.UP) * ramp_side_offset
	position_on_track.y = -0.08
	ramp.global_transform = track.global_transform * Transform3D(Basis.looking_at(track.sample_forward(offset)), position_on_track)
