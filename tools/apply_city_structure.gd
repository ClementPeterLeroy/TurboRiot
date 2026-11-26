extends SceneTree
## Patch the saved native assembly. Do not rebuild unaffected modules/instances.
const DIR := "res://assets/environment/city_square/"
const SCENES := "res://scenes/environment/city_square/"
func _initialize() -> void:run.call_deferred()

func collision(root_node: Node3D, mesh: MeshInstance3D, name: String, surface: SurfaceConfig) -> void:
	var body := root_node.get_node_or_null(name) as StaticBody3D
	if not body:
		body=StaticBody3D.new()
		body.name=name
		root_node.add_child(body)
		body.owner=root_node
	else:
		for child in body.get_children():body.remove_child(child);child.free()
	body.set_meta("surface",surface)
	var shape := CollisionShape3D.new()
	shape.shape=mesh.mesh.create_trimesh_shape()
	shape.transform=mesh.transform
	body.add_child(shape)
	shape.owner=root_node

func run() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"manifest.json"))
	var scene := load(SCENES+"environment.tscn").instantiate() as Node3D
	if scene.has_node("ArchitecturalLinks"):
		push_error("Structural assembly already applied; use refresh_city_collision.gd after source edits.")
		scene.free()
		quit(1)
		return
	var asphalt := load("res://resources/surfaces/asphalt.tres") as SurfaceConfig
	var grass := load("res://resources/surfaces/grass.tres") as SurfaceConfig
	for pair in [["PavedStreets",asphalt],["TimberDecks",asphalt],["TownLand",asphalt],["GardenGrass",grass]]:
		var mesh := scene.find_child(pair[0],true,false) as MeshInstance3D
		assert(mesh!=null)
		collision(scene,mesh,pair[0]+"Collision",pair[1])
	var island := scene.get_node_or_null("HarbourIslandCollision")
	if island:scene.remove_child(island);island.free()
	var architecture := scene.get_node("Architecture")
	var names := {}
	for lot in manifest.houses:names[lot.name]=lot
	for child in architecture.get_children():
		if not names.has(str(child.name)):architecture.remove_child(child);child.free()
	for lot in manifest.houses:
		var instance := architecture.get_node_or_null(NodePath(lot.name)) as Node3D
		if not instance:
			instance=load(SCENES+manifest.assets[lot.model]+".tscn").instantiate() as Node3D
			instance.name=lot.name
			architecture.add_child(instance)
			instance.owner=scene
		instance.position=Vector3(lot.position[0],lot.position[1],lot.position[2])
		instance.rotation.y=lot.yaw
		if lot.has("palette"):instance.set_meta("city_palette",lot.palette)
		if lot.get("foundation_extension",0)>.05:
			var depth: float=lot.foundation_extension
			var body := StaticBody3D.new()
			body.name="FoundationExtension"
			instance.add_child(body)
			body.owner=scene
			body.position.y=-.9-depth*.5
			var box := BoxMesh.new()
			box.size=Vector3(lot.size[0],depth,lot.size[1])
			var visible := MeshInstance3D.new()
			visible.mesh=box
			visible.material_override=RiotGeometry.material(Color("aba387"))
			body.add_child(visible)
			visible.owner=scene
			var shape := CollisionShape3D.new()
			var solid := BoxShape3D.new()
			solid.size=box.size
			shape.shape=solid
			body.add_child(shape)
			shape.owner=scene
	var links := load(DIR+"architectural_links.glb").instantiate() as Node3D
	links.name="ArchitecturalLinks"
	scene.add_child(links)
	links.owner=scene
	for child in links.find_children("*","MeshInstance3D",true,false):
		collision(scene,child,str(child.name)+"Collision",asphalt)
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	ResourceSaver.save(packed,SCENES+"environment.tscn")
	print("CITY_STRUCTURAL_ASSEMBLY houses=",architecture.get_child_count()," links=",links.get_child_count())
	scene.free()
	quit()
