extends SceneTree
## Actual seven-AI race screenshots; no synthetic finishing events.
func _initialize() -> void:
	_run.call_deferred()

func _save(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/competitors_%s.png" % label)

func _run() -> void:
	var main := load("res://scenes/main.tscn").instantiate() as Node3D
	var race := main.get_node("RaceManager") as RaceManager
	race.ai_only = true
	race.lap_count = 1
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	for i in 45: await physics_frame
	await _save("ready")
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	var preview := Camera3D.new()
	main.add_child(preview)
	preview.projection = Camera3D.PROJECTION_ORTHOGONAL
	preview.size = 35
	preview.position = race.competitors[3].grid.origin + Vector3(24, 32, -24)
	preview.look_at(race.competitors[3].grid.origin, Vector3.UP)
	preview.current = true
	main.get_node("HUD").visible = false
	await _save("grid")
	preview.queue_free()
	camera.current = true
	camera.set_process(true)
	main.get_node("HUD").visible = true
	race.start_race()
	for i in 270: await physics_frame
	await _save("racing")
	main.get_node("HUD").debug_visible = true
	race.set_debug_visible(true)
	for i in 15: await physics_frame
	await _save("debug")
	main.get_node("HUD").debug_visible = false
	race.set_debug_visible(false)
	for i in 6000:
		if race.race_complete: break
		await physics_frame
	await _save("results")
	var success := race.race_complete
	for record in race.competitors: success = success and record.finish_order > 0 and not record.dnf
	print("Rendered seven-kart one-lap race complete=", success)
	quit(0 if success else 1)
