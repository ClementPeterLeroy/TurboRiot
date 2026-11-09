extends SceneTree
## Rendered UI/scenery inspection. Results are a synthetic checkpoint run,
## not a human driving record. Requires an actual display/graphics driver.
var main: Node3D
var output_prefix: String = "runoff" if "--runoff" in OS.get_cmdline_user_args() else "race"

func _initialize() -> void:
	_start.call_deferred()

func _save(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/%s_%s.png" % [output_prefix, label])

func _start() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var race := main.get_node("RaceManager") as RaceManager
	race.set_physics_process(false)
	await create_timer(0.5).timeout
	await _save("ready")
	race.start_race()
	await _save("countdown")
	race.session.advance(3)
	await _save("go")
	race.session.advance(5)
	await _save("driving")
	for lap in 3:
		for index in range(1, race.gates.size()):
			race.session.advance(3.5 + lap * 0.2)
			var gate := race.gates[index]
			race.process_movement(gate.to_global(Vector3(0, 1, 2)), gate.to_global(Vector3(0, 1, -2)))
		race.session.advance(3.5)
		var finish := race.gates[0]
		race.process_movement(finish.to_global(Vector3(0, 1, 2)), finish.to_global(Vector3(0, 1, -2)))
	await _save("results")
	root.size = Vector2i(1024, 576)
	await _save("results_1024")
	root.size = Vector2i(1280, 720)
	main.get_node("HUD").visible = false
	var camera := main.get_node("ChaseCamera") as Camera3D
	camera.set_process(false)
	camera.position = Vector3(0, 230, 1)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 215
	await _save("overview")
	var track := main.get_node("Track") as TrackBuilder
	var forward := track.sample_forward(20)
	var right := forward.cross(Vector3.UP)
	var wall := track.barrier_point(20, 1.0) + Vector3.UP * 0.5
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 55
	camera.position = wall - right * 5 + forward * 2.5 + Vector3.UP * 1.8
	camera.look_at(wall, Vector3.UP)
	await _save("barriers")
	print("Saved previews to artifacts/%s_*.png" % output_prefix)
	quit()
