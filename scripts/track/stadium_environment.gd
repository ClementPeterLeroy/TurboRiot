@tool
extends Node3D
## Presentation binding only. Driving geometry, collisions and state are owned
## by the original track. Rebuilds hide its superseded temporary visual assets.
@export var road_material: Material
@export var ground_material: Material

func _ready() -> void:
	var track := get_parent() as TrackBuilder
	if track == null:
		return # This environment can also be inspected as a standalone scene.
	if not track.geometry_rebuilt.is_connected(_apply_presentation):
		track.geometry_rebuilt.connect(_apply_presentation)
	_apply_presentation.call_deferred()
	_configure_details(self)

func _apply_presentation() -> void:
	var generated := get_parent().get_node_or_null("Generated")
	if generated == null:
		return
	var road := generated.get_node_or_null("Asphalt") as MeshInstance3D
	if road:
		road.material_override = road_material
	var grass := get_parent().get_node_or_null("Ground/Grass") as MeshInstance3D
	if grass:
		grass.material_override = ground_material
	for child in generated.get_children():
		if child is VisualInstance3D and (str(child.name).begins_with("BarrierVisuals") or str(child.name).begins_with("StartPost") or child.name == &"StartBanner"):
			child.visible = false
		if child is Label3D and child.text == "TURBO RIOT  /  START":
			child.visible = false

func _configure_details(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			if str(child.name).begins_with("Crowd"):
				child.visibility_range_end = 145.0
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if str(child.name).begins_with("FenceGrid"):
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_configure_details(child)
