@tool
extends Node3D
## Shared visual materials only; native collision is saved separately.
const STONE := preload("res://assets/gameplay/city_stone.svg")
const ROOF := preload("res://assets/gameplay/city_roof.svg")
const WOOD := preload("res://assets/gameplay/city_timber.svg")
var _shared := {}
func _ready() -> void:
	_apply(self)

func _apply(node: Node) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var original := node.get_active_material(i) as StandardMaterial3D
			if not original: continue
			var texture: Texture2D
			if original.resource_name == "City_Roof": texture=ROOF
			elif node.name == &"PavedStreets" or "StairTreads" in str(node.name): texture=STONE
			elif node.name == &"TimberDecks": texture=WOOD
			if texture:
				# Editor re-entry/reparenting must not clone our own overrides again.
				if original.albedo_texture==texture:continue
				var key := str(original.get_instance_id())+texture.resource_path
				if not _shared.has(key):
					var paint := original.duplicate() as StandardMaterial3D
					if texture == ROOF or texture == WOOD: paint.albedo_color=Color.WHITE
					paint.albedo_texture=texture
					paint.texture_repeat=true
					paint.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					_shared[key]=paint
				node.set_surface_override_material(i,_shared[key])
	for child in node.get_children(): _apply(child)
