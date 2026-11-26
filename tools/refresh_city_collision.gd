extends SceneTree
## Refresh only existing collision shapes after editing a City source mesh.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	const PATH := "res://scenes/environment/city_square/environment.tscn"
	var scene := load(PATH).instantiate() as Node3D
	for name in ["PavedStreets","TimberDecks","TownLand","GardenGrass"]:
		var mesh := scene.find_child(name,true,false) as MeshInstance3D
		var shape := scene.get_node(name+"Collision").get_child(0) as CollisionShape3D
		shape.shape=mesh.mesh.create_trimesh_shape()
		shape.transform=mesh.transform
	var links := scene.get_node_or_null("ArchitecturalLinks")
	if links:
		for mesh in links.find_children("*","MeshInstance3D",true,false):
			var shape := scene.get_node(str(mesh.name)+"Collision").get_child(0) as CollisionShape3D
			shape.shape=mesh.mesh.create_trimesh_shape()
			shape.transform=mesh.transform
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,PATH)==OK)
	scene.free()
	quit()
