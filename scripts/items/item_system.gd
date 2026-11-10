@tool
class_name ItemSystem
extends Node3D
const ROW := preload("res://scenes/items/loot_box_row.tscn")
const ROW_CONFIGS: Array[LootRowConfig] = [preload("res://resources/items/row_upper.tres"), preload("res://resources/items/row_lower.tres"), preload("res://resources/items/row_central.tres")]
@export var track: TrackBuilder
@export var race: RaceManager
@export var enabled := true
@export var row_configurations: Array[LootRowConfig] = ROW_CONFIGS
@export var rebuild: bool:
	set(_value):
		if is_inside_tree() and enabled: rebuild_rows.call_deferred()
@export_range(1, 64) var maximum_actors := 32
var rows: Array[LootBoxRow] = []
var actors: Array[ItemActor] = []
var rng := RandomNumberGenerator.new()
var activations := 0
var _voices: Array[AudioStreamPlayer3D] = []
var _sounds: Array[AudioStreamWAV] = []
var _voice := 0
var _fx: Array[Dictionary] = []
var _feedback_delay := 0.0

func _exit_tree() -> void:
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_sounds.clear()

func _ready() -> void:
	process_physics_priority = 20
	rng.randomize()
	if not enabled: return
	track.geometry_rebuilt.connect(rebuild_rows)
	rebuild_rows()
	if Engine.is_editor_hint(): return
	race.race_reset.connect(reset_items)
	for record in race.competitors:
		if record.kart.input_provider is AIInput: record.kart.input_provider.item_system = self
	# Headless simulations have no listener or rendered feedback. Avoid queuing
	# audio playbacks faster than the real-time mixer can drain them.
	if DisplayServer.get_name() == "headless": return
	for i in 8:
		var voice := AudioStreamPlayer3D.new()
		voice.max_distance = 45
		voice.volume_db = -15
		add_child(voice)
		_voices.append(voice)
	for kind in 4: _sounds.append(_tone(kind))
	var contacts := race.get_node_or_null("KartContacts")
	if contacts: contacts.impact.connect(func(at: Vector3, _strength: float) -> void: feedback(at, 3))

func rebuild_rows() -> void:
	for row in rows:
		remove_child(row)
		row.queue_free()
	rows.clear()
	for config in row_configurations:
		var row := ROW.instantiate() as LootBoxRow
		row.configuration = config
		row.system = self if not Engine.is_editor_hint() else null
		row.name = "LootRow%d" % (rows.size() + 1)
		var anchor := Vector3((config.map_anchor.x - 500) * 0.18, 0.04, (config.map_anchor.y - 500) * 0.18)
		row.track_offset = track.curve.get_closest_offset(anchor)
		add_child(row)
		row.global_transform = track.global_transform * Transform3D(Basis.looking_at(track.sample_forward(row.track_offset)), track.sample_center(row.track_offset))
		rows.append(row)

func reset_items() -> void:
	for actor in actors:
		if is_instance_valid(actor): actor.expire()
	actors.clear()
	for row in rows:
		for box in row.boxes: box.reset_box()
	for record in race.competitors: record.kart.get_node("Inventory").clear()
	for effect in _fx:
		if is_instance_valid(effect.node): effect.node.queue_free()
	_fx.clear()
	for voice in _voices: voice.stop()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not enabled: return
	_feedback_delay = maxf(0, _feedback_delay - delta)
	for index in range(actors.size() - 1, -1, -1):
		if not is_instance_valid(actors[index]) or actors[index].spent: actors.remove_at(index)
	for record in race.competitors:
		var inventory := record.kart.get_node("Inventory") as KartInventory
		if inventory.request(record.kart.current_command.use_item, delta): activate(record.kart, inventory)
	for index in range(_fx.size() - 1, -1, -1):
		var effect: Dictionary = _fx[index]
		effect.time -= delta
		effect.node.scale += Vector3.ONE * delta * 3
		effect.node.transparency = 1 - maxf(0, effect.time / 0.35)
		if effect.time <= 0:
			effect.node.queue_free()
			_fx.remove_at(index)

func activate(kart: KartController, inventory: KartInventory) -> bool:
	if not inventory.held or not kart.driving_enabled: return false
	var item := inventory.held
	if item.identifier == &"5A":
		if not kart.activate_item_boost(&"mushroom", item.boost_strength, item.boost_duration): return false
	else:
		if actors.size() >= maximum_actors: return false
		var actor := ItemActor.new()
		actor.definition = item
		actor.source = kart
		actor.system = self
		actor.direction = -kart.global_basis.z
		actor.target = target_ahead(kart, item.target_range) if item.identifier == &"5B" else null
		var spawn := kart.global_position + actor.direction * (-2.0 if item.identifier == &"5D" else 1.8)
		spawn.y += 0.15
		var obstruction := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(kart.global_position, spawn, 1))
		if not obstruction.is_empty(): spawn = obstruction.position - (spawn - kart.global_position).normalized() * 0.3
		add_child(actor)
		actor.global_position = spawn
		actor.reset_physics_interpolation()
		actors.append(actor)
	inventory.consume()
	activations += 1
	feedback(kart.global_position, 1)
	return true

func target_ahead(kart: KartController, distance: float, alignment := 0.55) -> KartController:
	var best: KartController
	var nearest := distance
	for record in race.competitors:
		var other := record.kart
		if other == kart or not other.driving_enabled: continue
		var difference := other.global_position - kart.global_position
		difference.y = 0
		if difference.length() < 0.1 or difference.length() >= nearest or difference.normalized().dot(-kart.global_basis.z) < alignment: continue
		var ray := PhysicsRayQueryParameters3D.create(kart.global_position, other.global_position, 1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		nearest = difference.length()
		best = other
	return best

func collection_lane(kart: KartController, offset: float, lateral: float) -> float:
	var result := lateral
	var nearest := 26.0
	for row in rows:
		var distance := fposmod(row.track_offset - offset, race.racing_line.length)
		if distance < 2 or distance > nearest: continue
		var best := INF
		for box in row.boxes:
			if not box.available: continue
			var cost := absf(box.position.x - lateral)
			if cost < best:
				best = cost
				result = box.position.x
		if best < INF: nearest = distance
	return result if nearest < 26 else 0.0

func ai_should_use(driver: AIInput) -> bool:
	var inventory := driver.kart.get_node("Inventory") as KartInventory
	if not inventory.held: return false
	match inventory.held.identifier:
		&"5A": return driver.kart.signed_speed > 7 and driver.target_speed > 16 and not driver.kart.boost.active() and driver.line.curvatures[driver.line.index_at(driver.current_offset)] < 0.02
		&"5B": return target_ahead(driver.kart, 40) != null
		&"5C": return target_ahead(driver.kart, 28, 0.98) != null
		&"5D": return driver.kart.signed_speed > 8
	return false

func feedback(at: Vector3, kind: int) -> void:
	if Engine.is_editor_hint() or _feedback_delay > 0 or _voices.is_empty(): return
	_feedback_delay = 0.035
	var voice := _voices[_voice % _voices.size()]
	_voice += 1
	voice.global_position = at
	voice.stream = _sounds[kind]
	voice.play()
	if _fx.size() < 12:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.4
		ring.outer_radius = 0.48
		ring.rings = 12
		ring.ring_segments = 6
		var colours := [Color("61eeff"), Color("ffe770"), Color("ff706a"), Color("fff1bf")]
		var node := PowerupModels.mesh_node(self, ring, colours[kind], to_local(at + Vector3.DOWN * 0.15))
		_fx.append({"node": node, "time": 0.35})

func _tone(kind: int) -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(4410 * 2)
	for i in 4410:
		var t := float(i) / 22050
		var frequency: float = [660, 440, 180, 270][kind] * (1 + t * (3 if kind < 2 else -2))
		var value := sin(TAU * frequency * t) * (1 - float(i) / 4410) * 0.3
		samples.encode_s16(i * 2, roundi(value * 32767))
	sound.data = samples
	return sound
