extends SceneTree
## Native renderer inspection only. No source reference textures are loaded.
func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	main.get_node("Items").enabled = false # Isolate pre-item regression fixture.
	root.add_child(main)
	root.size = Vector2i(1000, 1000)
	main.get_node("HUD").visible = false
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 184
	camera.position = Vector3(0, 230, 0.01)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	root.get_texture().get_image().save_png("res://artifacts/corrective_layout.png")
	var race := main.get_node("RaceManager") as RaceManager
	for gate in race.gates:
		var accepted := 0
		for ratio in [-0.85, 0.0, 0.85]:
			var x: float = ratio * (gate.left_extent if ratio < 0 else gate.right_extent)
			if gate.crossing_fraction(gate.to_global(Vector3(x, 0.6, 2)), gate.to_global(Vector3(x, 0.6, -2))) >= 0:
				accepted += 1
		print("Gate ", gate.gate_index, " limits ", gate.left_extent, "/", gate.right_extent, " coverage ", accepted, "/3")
	print("Saved corrective layout")
	quit()
