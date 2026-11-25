extends SceneTree
const DIR := "res://assets/environment/city_square/"
const SCENES := "res://scenes/environment/city_square/"
var root_node := Node3D.new()
var asphalt := preload("res://resources/surfaces/asphalt.tres")
var grass := preload("res://resources/surfaces/grass.tres")

func _initialize() -> void: run.call_deferred()
func model(path: String, name: String, parent: Node) -> Node3D:
	var node := load(path).instantiate() as Node3D
	node.name=name
	parent.add_child(node)
	node.owner=root_node
	return node

func add_collision(source: Node, parent: Node, surface: SurfaceConfig) -> void:
	if source is MeshInstance3D:
		var body := StaticBody3D.new()
		body.name=str(source.name)+"Collision"
		parent.add_child(body)
		body.owner=root_node
		body.set_meta("surface",surface)
		var shape := CollisionShape3D.new()
		shape.shape=source.mesh.create_trimesh_shape()
		body.add_child(shape)
		shape.owner=root_node
		# Imported Blender scene transforms are identity at this site root.
		shape.transform=source.transform
	for child in source.get_children(): add_collision(child,parent,surface)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(SCENES)
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DIR+"manifest.json"))
	var survey: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/tracks/city_square/survey.json"))
	# Build six independent module wrappers with one simple structural mass.
	for i in 6:
		var name: String=manifest.assets[i]
		var module := Node3D.new()
		module.name=name
		var instance := load(DIR+name+".glb").instantiate() as Node3D
		module.add_child(instance)
		instance.owner=module
		var body := StaticBody3D.new()
		module.add_child(body)
		body.owner=module
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		var size: Array=manifest.house_sizes[i]
		box.size=Vector3(size[0],size[2]-.3,size[1])
		shape.shape=box
		shape.position.y=(size[2]-.3)/2-.8
		body.add_child(shape)
		shape.owner=module
		var packed := PackedScene.new()
		packed.pack(module)
		ResourceSaver.save(packed,SCENES+name+".tscn")
		module.free()
	root_node.name="CityEnvironment"
	root_node.set_script(load("res://scripts/track/city_materials.gd"))
	var roads := model(DIR+"driving_surfaces.glb","Roads",root_node)
	add_collision(roads,root_node,asphalt)
	model(DIR+"stairs_and_dock_structure.glb","StairsAndDockStructure",root_node)
	var terrain := model(DIR+"coast_and_terrain.glb","Terrain",root_node)
	for name in ["TownLand","GardenGrass","HarbourIsland"]:
		var mesh := terrain.find_child(name,true,false)
		assert(mesh!=null,name)
		add_collision(mesh,root_node,grass if name!="TownLand" else asphalt)
	model(DIR+"fountain.glb","Fountain",root_node)
	var fountain_body := StaticBody3D.new()
	fountain_body.name="FountainCollision"
	root_node.add_child(fountain_body)
	fountain_body.owner=root_node
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius=6
	cylinder.height=3.2
	shape.shape=cylinder
	shape.position=Vector3(survey.fountain[0],12,survey.fountain[2])
	fountain_body.add_child(shape)
	shape.owner=root_node
	var houses := Node3D.new()
	houses.name="Architecture"
	root_node.add_child(houses)
	houses.owner=root_node
	for lot in manifest.houses:
		var name: String=manifest.assets[lot.model]
		var instance := model(SCENES+name+".tscn",lot.name,houses)
		instance.position=Vector3(lot.position[0],lot.position[1],lot.position[2])
		instance.rotation.y=lot.yaw
	var packed := PackedScene.new()
	packed.pack(root_node)
	ResourceSaver.save(packed,SCENES+"environment.tscn")
	root_node.free()
	print("CITY_ASSEMBLED houses=",manifest.houses.size())
	quit()
