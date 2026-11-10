extends SceneTree
## Original model gallery plus native source-track row and race captures.
func _initialize() -> void: _run.call_deferred()

func _save(label: String) -> void:
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/items_%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var gallery := Node3D.new()
	root.add_child(gallery)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202e49")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	gallery.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	gallery.add_child(sun)
	var camera := Camera3D.new()
	gallery.add_child(camera)
	camera.position = Vector3(0, 2.8, -8)
	camera.look_at(Vector3(0, 0.4, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.8
	camera.current = true
	var names := ["mushroom", "red_shell", "green_shell", "banana", "loot"]
	for index in names.size():
		var model := Node3D.new()
		gallery.add_child(model)
		model.position.x = (2 - index) * 1.8
		model.rotation.y = -0.22
		PowerupModels.build(model, names[index])
		var label := Label3D.new()
		label.text = ["5A  MUSHROOM", "5B  RED SHELL", "5C  GREEN SHELL", "5D  BANANA", "LOOT BOX"][index]
		label.position = Vector3(model.position.x, -0.25, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 28
		label.pixel_size = 0.006
		gallery.add_child(label)
	await _save("models")
	gallery.queue_free()
	await process_frame
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	var race := main.get_node("RaceManager") as RaceManager
	race.ai_only = true
	root.add_child(main)
	var chase := main.get_node("ChaseCamera") as Camera3D
	chase.set_process(false)
	main.get_node("HUD").visible = false
	var overhead := Camera3D.new()
	main.add_child(overhead)
	overhead.projection = Camera3D.PROJECTION_ORTHOGONAL
	overhead.size = 240
	overhead.position = Vector3(0, 200, 0.01)
	overhead.look_at(Vector3.ZERO, Vector3.FORWARD)
	overhead.current = true
	var markers: Array[Label3D] = []
	for row: LootBoxRow in main.get_node("Items").rows:
		var marker := Label3D.new()
		marker.text = row.name + "  (4)"
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 42
		marker.pixel_size = 0.08
		marker.position = row.global_position + Vector3.UP * 4
		main.add_child(marker)
		markers.append(marker)
	await _save("rows")
	for marker in markers: marker.queue_free()
	await process_frame
	var first: LootBoxRow = main.get_node("Items").rows[0]
	overhead.projection = Camera3D.PROJECTION_PERSPECTIVE
	overhead.position = first.global_position + first.global_basis.z * 10 + Vector3.UP * 5
	overhead.look_at(first.global_position + Vector3.UP)
	await _save("row_close")
	overhead.queue_free()
	chase.current = true
	chase.set_process(true)
	main.get_node("HUD").visible = true
	race.start_race()
	for i in 470: await physics_frame
	var inventory := race.kart.get_node("Inventory") as KartInventory
	inventory.clear()
	inventory.pickup(ItemCatalog.ITEMS[1])
	await _save("racing_hud")
	main.queue_free()
	await process_frame
	quit()
