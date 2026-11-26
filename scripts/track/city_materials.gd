@tool
extends Node3D
## Shared visual materials only; native collision is saved separately.
const STONE := preload("res://assets/gameplay/city_stone.svg")
const ROOF := preload("res://assets/gameplay/city_roof.svg")
const WOOD := preload("res://assets/gameplay/city_timber.svg")
var _shared := {}
func _ready() -> void:
	_apply(self)

func _apply(node: Node, inherited_palette := 0) -> void:
	var palette: int=int(node.get_meta("city_palette",inherited_palette))
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var original := node.get_active_material(i) as StandardMaterial3D
			if not original: continue
			var texture: Texture2D
			if str(original.resource_name).begins_with("City_Roof"): texture=ROOF
			elif node.name == &"PavedStreets" or "StairTreads" in str(node.name): texture=STONE
			elif node.name == &"TimberDecks": texture=WOOD
			var tint := palette>0 and original.resource_name in ["City_Plaster","City_Roof"]
			if original.get_meta("city_palette_bound",-1)==palette:continue
			if texture or tint:
				# Editor re-entry/reparenting must not clone our own overrides again.
				if texture and original.albedo_texture==texture and not tint:continue
				var key := str(original.get_instance_id())+str(palette)+(texture.resource_path if texture else "")
				if not _shared.has(key):
					var paint := original.duplicate() as StandardMaterial3D
					if texture == ROOF or texture == WOOD: paint.albedo_color=Color.WHITE
					if str(original.resource_name).begins_with("City_RoofShade"):
						var shades := [Color.WHITE,Color(.84,.82,.79),Color(1,.94,.85)]
						paint.albedo_color=shades[int(str(original.resource_name).right(1))%shades.size()]
					if tint:
						var colors := [Color.WHITE,Color("d99d76"),Color("b96d4d"),Color("e6b080")] if original.resource_name=="City_Roof" else [Color.WHITE,Color("f2dec5"),Color("e8c5a2"),Color("f6e8cc")]
						paint.albedo_color*=colors[palette%colors.size()]
					paint.albedo_texture=texture
					paint.texture_repeat=true
					paint.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					paint.set_meta("city_palette_bound",palette)
					_shared[key]=paint
				node.set_surface_override_material(i,_shared[key])
	for child in node.get_children(): _apply(child,palette)
