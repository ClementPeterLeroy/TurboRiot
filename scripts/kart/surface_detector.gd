@tool
class_name SurfaceDetector
extends RefCounted
## Physical ground query plus metadata-tagged region query. Regions give grass
## a distinct surface without creating another step above the existing sand.
const ASPHALT := preload("res://resources/surfaces/asphalt.tres")
var current: SurfaceConfig = ASPHALT
var effective := Vector4.ONE
var normal := Vector3.UP
var ground_distance: float = INF
var has_ground := false
var _candidate: SurfaceConfig
var _candidate_time: float = 0.0
var _boost_override := 0.0

static func tag_collision(root: Node, surface: SurfaceConfig) -> void:
	if root is StaticBody3D or root is Area3D:
		root.set_meta("surface", surface)
	for child in root.get_children():
		tag_collision(child, surface)

func reset() -> void:
	clear_boost_override()
	current = ASPHALT
	effective = Vector4.ONE
	normal = Vector3.UP
	ground_distance = INF
	has_ground = false
	_candidate = null
	_candidate_time = 0.0

func clear_boost_override() -> void:
	_boost_override = 0

func handling_multipliers(boost: BoostController, delta: float, smoothing: float) -> Vector4:
	# Detection, labels and the underlying blend stay live. Only mushroom's
	# own timer neutralizes reduced acceleration/cap/grip; resistance is retained.
	if boost.mushroom_remaining > 0:
		_boost_override = 1
	else:
		_boost_override *= exp(-smoothing * delta)
		if _boost_override < 0.0001: _boost_override = 0
	return Vector4(lerpf(effective.x, maxf(1, effective.x), _boost_override),
		lerpf(effective.y, maxf(1, effective.y), _boost_override),
		lerpf(effective.z, maxf(1, effective.z), _boost_override), effective.w)

func blend(surface: SurfaceConfig, delta: float, smoothing: float, debounce: float) -> void:
	if surface != _candidate:
		_candidate = surface
		_candidate_time = 0.0
	_candidate_time += delta
	if _candidate_time >= debounce:
		current = surface
	effective = effective.lerp(current.multipliers(), 1.0 - exp(-smoothing * delta))

func update(kart: CharacterBody3D, config: KartConfig, delta: float) -> void:
	var start := kart.global_position + Vector3.UP * 0.6
	var end := kart.global_position - Vector3.UP * config.surface_probe_distance
	var query := PhysicsRayQueryParameters3D.create(start, end, 1, [kart.get_rid()])
	var hit := kart.get_world_3d().direct_space_state.intersect_ray(query)
	has_ground = not hit.is_empty()
	if not has_ground:
		ground_distance = INF
		return # Air retains last surface; no surface change without support below.
	normal = hit.normal
	ground_distance = kart.global_position.y - hit.position.y
	var surface := hit.collider.get_meta("surface", ASPHALT) as SurfaceConfig
	if not surface:
		surface = ASPHALT
	query.collision_mask = 8 # Surface regions; not physical walls or kart bodies.
	query.collide_with_bodies = false
	query.collide_with_areas = true
	query.hit_from_inside = true
	var region := kart.get_world_3d().direct_space_state.intersect_ray(query)
	if not region.is_empty():
		var overlay := region.collider.get_meta("surface", null) as SurfaceConfig
		if overlay and (overlay.identifier == &"boost_pad" or surface.identifier == &"sand"):
			surface = overlay
	blend(surface, delta, config.surface_smoothing, config.surface_debounce)
