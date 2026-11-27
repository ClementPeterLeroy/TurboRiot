extends SceneTree
## Synchronize local lots and three changed source exports. No global rebuild.
const PATH := "res://scenes/environment/city_square/environment.tscn"
const SCENES := "res://scenes/environment/city_square/"
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var scene := load(PATH).instantiate() as Node3D
	if "--refresh-surfaces" in OS.get_cmdline_user_args():
		refresh_surfaces(scene)
		write_scene(scene)
		return
	assert(not scene.has_meta("transition_revision"),"Local transitions already synchronized")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/city_square/manifest.json"))
	var changes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/v061_city_transitions_changes.json"))
	var changed := {}
	for item in changes.added:changed[item.name]=true
	for item in changes.moved:changed[item.name]=true
	var architecture := scene.get_node("Architecture")
	for lot in manifest.houses:
		if not changed.has(lot.name):continue
		var house := architecture.get_node_or_null(NodePath(lot.name)) as Node3D
		if not house:
			house=load(SCENES+manifest.assets[lot.model]+".tscn").instantiate() as Node3D
			house.name=lot.name
			architecture.add_child(house)
			house.owner=scene
		house.position=Vector3(lot.position[0],lot.position[1],lot.position[2])
		house.rotation.y=lot.yaw
		if lot.has("scale"):house.scale=Vector3(lot.scale[0],lot.scale[1],lot.scale[2])
		if lot.has("palette"):house.set_meta("city_palette",lot.palette)
		var previous := house.get_node_or_null("FoundationExtension")
		if previous:house.remove_child(previous);previous.free()
		if lot.foundation_extension>.05:
			var body := StaticBody3D.new()
			body.name="FoundationExtension"
			house.add_child(body)
			body.owner=scene
			body.position.y=-.9-lot.foundation_extension*.5
			var box := BoxMesh.new()
			# Lot width already includes instance scale; local mesh must not
			# multiply that fit a second time.
			box.size=Vector3(manifest.house_sizes[lot.model][0],lot.foundation_extension,lot.size[1])
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
	for name in changes.removed_link_groups:
		var body := scene.get_node(name+"Collision")
		scene.remove_child(body)
		body.free()
	refresh_surfaces(scene)
	scene.set_meta("transition_revision",1)
	print("CITY_LOCAL_TRANSITIONS houses=",architecture.get_child_count()," unchanged connectors=",scene.get_node("ArchitecturalLinks").get_child_count())
	write_scene(scene)

func refresh_surfaces(scene: Node3D) -> void:
	for name in ["PavedStreets","GardenGrass"]:
		var mesh := scene.find_child(name,true,false) as MeshInstance3D
		var shape := scene.get_node(name+"Collision").get_child(0) as CollisionShape3D
		var triangles := mesh.mesh.get_faces()
		var clean := PackedVector3Array()
		var removed := 0
		for i in range(0,triangles.size(),3):
			var center := (triangles[i]+triangles[i+1]+triangles[i+2])/3
			var local := center.x>=-146 and center.x<=-75 and center.z>=80 and center.z<=144
			if local and (triangles[i+1]-triangles[i]).cross(triangles[i+2]-triangles[i]).length_squared()<1e-12:
				removed+=1
				continue # Compression can collapse clipping dust into a segment.
			clean.append_array(triangles.slice(i,i+3))
		var solid := ConcavePolygonShape3D.new()
		solid.set_faces(clean)
		shape.shape=solid
		shape.transform=mesh.transform
		shape.set_meta("local_degenerate_triangles_removed",removed)
		print("CITY_LOCAL_COLLISION ",name," zero-area faces removed=",removed)

func write_scene(scene: Node3D) -> void:
	var packed := PackedScene.new()
	assert(packed.pack(scene)==OK)
	assert(ResourceSaver.save(packed,PATH)==OK)
	scene.free()
	quit()
