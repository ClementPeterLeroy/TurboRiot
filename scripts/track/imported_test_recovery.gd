extends Node3D
## Sandbox-only safety envelope. Recompute from the current imported road each
## time the test scene starts; preserve the owner's authored kart/safe spawn.
@export var road: MeshInstance3D
@export var kart: KartController
@export_range(1.0, 100.0) var horizontal_margin := 12.0
@export_range(1.0, 100.0) var fall_clearance := 10.0

func _ready() -> void:
	if not is_instance_valid(road) or road.mesh == null or not is_instance_valid(kart):
		push_error("Imported test recovery requires the road mesh and test kart.")
		return
	var bounds: AABB = road.global_transform * road.get_aabb()
	var recovery := kart.get_node("Recovery") as KartRecovery
	# Existing KartRecovery uses world-origin symmetric X/Z bounds. Enclose the
	# transformed road without changing that shared contract for other circuits.
	recovery.recovery_half_extents = Vector2(
		maxf(absf(bounds.position.x), absf(bounds.end.x)),
		maxf(absf(bounds.position.z), absf(bounds.end.z))) + Vector2.ONE * horizontal_margin
	recovery.fall_height = bounds.position.y - fall_clearance
