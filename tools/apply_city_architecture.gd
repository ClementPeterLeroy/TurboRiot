extends SceneTree
## Synchronize the eight local entrance placements and existing link colliders.
func _initialize() -> void:run.call_deferred()
func run() -> void:
	const PATH := "res://scenes/environment/city_square/environment.tscn"
	var scene := load(PATH).instantiate() as Node3D
	assert("--refresh-collision" in OS.get_cmdline_user_args() or not scene.has_meta("architecture_revision"),"Architecture placement already applied")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/city_square/manifest.json"))
	for house in manifest.houses:
		if manifest.entrance_setbacks_x.has(house.name):
			var node := scene.get_node("Architecture/"+house.name) as Node3D
			node.position=Vector3(house.position[0],house.position[1],house.position[2])
	for mesh in scene.get_node("ArchitecturalLinks").get_children():
		var shape := scene.get_node(str(mesh.name)+"Collision").get_child(0) as CollisionShape3D
		shape.shape=mesh.mesh.create_trimesh_shape()
		shape.transform=mesh.transform
	scene.set_meta("architecture_revision",1)
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,PATH)==OK)
	scene.free()
	quit()
