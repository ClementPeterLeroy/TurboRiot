@tool
class_name LootBox
extends Area3D
var system: Node
var available := true
var remaining := 0.0
var respawn_seconds := 5.0
var phase := 0.0
var _inside := {}
var _visual: Node3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.65, 2, 1.65)
	collision.shape = shape
	add_child(collision)
	_visual = Node3D.new()
	add_child(_visual)
	PowerupModels.build(_visual, "loot")
	body_exited.connect(func(body: Node3D) -> void: _inside.erase(body.get_instance_id()))

func _process(delta: float) -> void:
	phase += delta
	_visual.rotation.y = phase * 0.6
	_visual.position.y = sin(phase * 2) * 0.12

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not system: return
	remaining = maxf(0, remaining - delta)
	if not available and remaining == 0:
		available = true
		_visual.visible = true
	if available:
		for body in get_overlapping_bodies():
			if body is KartController: try_collect(body)

func try_collect(kart: KartController) -> bool:
	if not available or not system or not kart.driving_enabled or _inside.has(kart.get_instance_id()): return false
	_inside[kart.get_instance_id()] = true
	var inventory := kart.get_node("Inventory") as KartInventory
	if inventory.held: return false
	if not inventory.pickup(ItemCatalog.choose(system.rng)): return false
	available = false
	remaining = respawn_seconds
	_visual.visible = false
	system.feedback(global_position, 0)
	return true

func reset_box() -> void:
	available = true
	remaining = 0
	_inside.clear()
	if _visual: _visual.visible = true
